<template>
  <main>
    <div class="z__main-toolbar mt-2">
      <!-- Left: Title with icon -->
      <div class="z__app-title-container">
        <h2 class="z__app-title">
          <v-icon
            icon="mdi-chart-bar"
            color="primary"
            class="title-icon"
          ></v-icon>
          <span>Volume reçu sur la plateforme LogVault</span>
        </h2>
      </div>

      <!-- Center: Period Navigator -->
      <div class="z__period-navigator">
        <v-btn
          icon="mdi-chevron-left"
          size="x-small"
          variant="text"
          color="primary"
          density="comfortable"
          @click="navigatePeriod('prev')"
          class="nav-arrow"
        ></v-btn>

        <div class="date-parts">
          <!-- Clickable day -->
          <span
            :class="['date-part', viewMode === 'day' ? 'date-part-active' : '']"
            @click="viewMode = 'day'">
            {{ formattedDay }}
          </span>

          <!-- Separator -->
          <span class="date-separator">/</span>

          <!-- Clickable month -->
          <span
            :class="['date-part', viewMode === 'month' ? 'date-part-active' : '']"
            @click="viewMode = 'month'">
            {{ formattedMonth }}
          </span>

          <!-- Separator -->
          <span class="date-separator">/</span>

          <!-- Clickable year -->
          <span
            :class="['date-part', viewMode === 'year' ? 'date-part-active' : '']"
            @click="viewMode = 'year'">
            {{ formattedYear }}
          </span>

          <!-- Quarter (conditionally displayed) -->
          <span
            :class="['date-part', 'date-part-quarter', viewMode === 'quarter' ? 'date-part-active' : '']"
            @click="viewMode = 'quarter'"
            v-if="showTrimestre || viewMode === 'quarter'">
            (T{{ currentQuarter }})
          </span>
        </div>

        <v-btn
          icon="mdi-chevron-right"
          size="x-small"
          variant="text"
          color="primary"
          density="comfortable"
          @click="navigatePeriod('next')"
          class="nav-arrow"
        ></v-btn>

        <v-tooltip
          location="bottom"
          text="Réinitialiser à la date la plus récente"
          transition="fade-transition"
        >
          <template v-slot:activator="{ props }">
            <v-btn
              v-bind="props"
              size="x-small"
              variant="text"
              color="primary"
              density="comfortable"
              icon="mdi-calendar-today"
              @click="selectedDate = mostRecentLogDate"
              class="ml-1 nav-arrow"
            ></v-btn>
          </template>
        </v-tooltip>
      </div>

      <!-- Right: Machine Filter -->
      <div class="z__searchbar">
        <div class="host-selector-container">
          <v-icon icon="mdi-server" color="primary" class="filter-icon"></v-icon>
          <v-combobox
            placeholder="Filtrer par machine"
            density="compact"
            :items="hostsWithAliases"
            item-title="title"
            item-value="value"
            bg-color="transparent"
            color="primary"
            variant="plain"
            clearable
            multiple
            hide-details
            chips
            closable-chips
            @update:modelValue="handleSearch"
            :menu-props="{ maxHeight: '400px' }"
            class="host-selector"
          ></v-combobox>
        </div>
      </div>
    </div>
    <div class="z__chart-table-container">
      <LogChart
        :config="chartConfig"
        @change-date="changeDate"
        @change-mode="changeMode"
      />
      <LogTable
        :config="tableConfig"
        :error="error"
        @change-date="changeDate"
        @change-mode="changeMode"
      />
    </div>
  </main>
</template>

<script setup>
import LogTable from '../components/LogTable.vue'
import LogChart from '../components/LogChart.vue'
import * as utils from '@/plugins/utils'
import { getAliasForIP, fetchConfig, getConfig } from '@/plugins/config.js'

import { onBeforeMount, ref, watch, computed, inject } from 'vue'
import axios from 'axios'

// Default view mode is "day"
const viewMode = ref('day')

// Auto-zoom: hierarchy of zoom levels and retry counter
// Allows cascading day→month→quarter→year, then up to 5 previous years
const zoomOutMap = { day: 'month', month: 'quarter', quarter: 'year' }
const autoZoomRetries = ref(0)
const MAX_AUTO_ZOOM_RETRIES = 8 // 4 zoom levels + up to 4 previous years

// Inject elasticUsage from App.vue
const elasticUsage = inject('elasticUsage')

let rawLogs = null
let rawIndices = null
const error = ref(null)
const timezone = ref('')
const formattedLogs = ref([])
const formattedIndices = ref([])
const selectedDate = ref(null)
/**
 * @computed The formatted version of the selected date
 */
const selectedFullDate = computed(() => {
  return selectedDate.value
    ? new Intl.DateTimeFormat('fr-FR').format(selectedDate.value).replace('"', '')
    : null
})

/**
 * @computed Get just the day part of the date
 */
const formattedDay = computed(() => {
  if (!selectedDate.value) return ''
  const date = new Date(selectedDate.value)
  return date.getUTCDate().toString().padStart(2, '0')
})

/**
 * @computed Get just the month part of the date
 */
const formattedMonth = computed(() => {
  if (!selectedDate.value) return ''
  const date = new Date(selectedDate.value)
  return (date.getUTCMonth() + 1).toString().padStart(2, '0')
})

/**
 * @computed Get just the year part of the date
 */
const formattedYear = computed(() => {
  if (!selectedDate.value) return ''
  const date = new Date(selectedDate.value)
  return date.getUTCFullYear().toString()
})

/**
 * @computed Control whether to show the trimester indicator
 */
const showTrimestre = computed(() => {
  return viewMode.value === 'quarter' || (selectedDate.value && currentQuarter.value)
})

/**
 * @computed Hosts with their aliases as titles
 */
const hostsWithAliases = computed(() => {
  // Sort using natural sort for both IPs and hostnames
  return hosts.value
    .slice() // Create a copy to avoid modifying the original
    .sort((a, b) => {
      const aliasA = getAliasForIP(a)
      const aliasB = getAliasForIP(b)
      return utils.naturalCompare(aliasA, aliasB)
    })
    .map(host => ({
      title: getAliasForIP(host),
      value: host
    }))
})


const search = ref([])
const mostRecentLogDate = ref(null)
const hosts = ref([])
const logsByHost = ref({})

const currentTimeLimits = ref({ start: null, end: null })
/** Log volumes ordered by host and by time period */
const hostsVolumeByPeriod = ref([])
/** All log volumes added together and ordered by time period */
const totalVolumeByPeriod = ref({})
/** Index volumes ordered by time period */
const totalIndexVolumeByPeriod = ref({})

// Time-based values
const hoursValues = [...Array(24).keys()]
// Number of days has to be reactive because it can change depending on the month
const daysValues = ref([...Array(31).keys()].map((key) => Number(key) + 1))
const monthsValues = [...Array(12).keys()].map((key) => Number(key))
const q1weeks = [...Array(13).keys()].map((key) => Number(key) + 1)
const q2weeks = q1weeks.map((w) => w + 13)
const q3weeks = q2weeks.map((w) => w + 13)
const q4weeks = q3weeks.map((w) => w + 13)
const quarterWeeksValues = ref(q1weeks)
const currentQuarter = ref(1)

const tableConfig = ref({
  viewMode,
  hostsVolumeByPeriod,
  currentTimeLimits,
  currentQuarter,
  timeValues: {
    hours: hoursValues,
    days: daysValues,
    months: monthsValues,
    quarterWeeks: quarterWeeksValues
  },
  search,
  date: selectedDate
})

const chartConfig = ref({
  viewMode,
  totals: totalVolumeByPeriod,
  indexTotals: totalIndexVolumeByPeriod,
  date: selectedDate,
  currentQuarter,
  search
})

/**
 * Format valid dates for indices as a JS Date object
 * @param {Object} indexData - The index data object to format
 * @returns {Object} The formatted index data object
 */
const formatIndexDate = (indexData) => {
  indexData.rawDate = indexData.date
  const dateObject = new Date(indexData.date)

  /** @WORKAROUND Temporary hotfix to avoid incoherent dates (year of 32120 etc.) */
  if (dateObject.getFullYear() <= new Date().getFullYear()) {
    indexData.dateObject = dateObject
    indexData.date = new Intl.DateTimeFormat('fr-FR').format(indexData.dateObject)
  }

  return indexData
}

/**
 * Fetch logs and indices data for the exact period being displayed
 * @param {Date} refDate - Reference date for the period
 * @param {string} mode - View mode:
 *   - day: displays ONE day hour by hour (24 hours)
 *   - month: displays ONE month day by day (~30 days)
 *   - quarter: displays ONE quarter week by week (13 weeks)
 *   - year: displays ONE year month by month (12 months)
 */
const fetchDataForPeriod = async (refDate = null, mode = 'day') => {
  // Use current date if no reference provided
  const reference = refDate ? new Date(refDate) : new Date()

  // Calculate exact period based on view mode
  let startDate = new Date(reference)
  let endDate = new Date(reference)

  switch (mode) {
    case 'day':
      // Load exactly 1 day
      startDate.setHours(0, 0, 0, 0)
      endDate.setHours(23, 59, 59, 999)
      break
    case 'month':
      // Load exactly 1 month
      startDate.setDate(1)
      startDate.setHours(0, 0, 0, 0)
      const lastDay = new Date(startDate.getFullYear(), startDate.getMonth() + 1, 0).getDate()
      endDate.setDate(lastDay)
      endDate.setHours(23, 59, 59, 999)
      break
    case 'quarter':
      // Load exactly 1 quarter (3 months)
      const currentMonth = startDate.getMonth()
      const quarterStartMonth = Math.floor(currentMonth / 3) * 3
      startDate.setMonth(quarterStartMonth, 1)
      startDate.setHours(0, 0, 0, 0)
      endDate.setMonth(quarterStartMonth + 3, 0) // Last day of quarter
      endDate.setHours(23, 59, 59, 999)
      break
    case 'year':
      // Load exactly 1 year
      startDate.setMonth(0, 1)
      startDate.setHours(0, 0, 0, 0)
      endDate.setMonth(11, 31)
      endDate.setHours(23, 59, 59, 999)
      break
  }

  const startStr = startDate.toISOString().split('T')[0]
  const endStr = endDate.toISOString().split('T')[0]

  // Determine aggregation level based on view mode
  // hour: hourly data (for day view)
  // day: daily aggregated data (for month/quarter view)
  // month: monthly aggregated data (for year view)
  const granularity = mode === 'day' ? 'hour' : mode === 'year' ? 'month' : 'day'

  // Fetch logs data with granularity parameter
  axios.get('./api/list-archives', {
    params: { start: startStr, end: endStr, granularity }
  }).then((response) => {
    try {
      rawLogs = response.data

      // Auto-zoom: if no data returned, try a broader view or previous year
      if ((!rawLogs || rawLogs.length === 0) && autoZoomRetries.value < MAX_AUTO_ZOOM_RETRIES) {
        autoZoomRetries.value++
        const nextMode = zoomOutMap[mode]
        if (nextMode) {
          // Zoom out to next broader level (day→month→quarter→year)
          viewMode.value = nextMode
          setCurrentTimeLimits(nextMode)
          fetchDataForPeriod(selectedDate.value ?? reference.getTime(), nextMode)
        } else {
          // Already at year level with no data: try previous year
          const prevYear = new Date(reference)
          prevYear.setUTCFullYear(prevYear.getUTCFullYear() - 1)
          selectedDate.value = prevYear.getTime()
          setCurrentTimeLimits(viewMode.value)
          fetchDataForPeriod(prevYear.getTime(), viewMode.value)
        }
        return
      }

      autoZoomRetries.value = 0
      formattedLogs.value = structuredClone(rawLogs).map((log) => formatLogDate(log))
    } catch (err) {
      autoZoomRetries.value = 0
      error.value = 'Failed to fetch logs'
      console.error('Failed to fetch logs:', err)
    }
  }).catch((err) => {
    autoZoomRetries.value = 0
    error.value = 'Failed to fetch logs'
    console.error('Failed to fetch logs:', err)
  })

  // Fetch indices data only if Elasticsearch is enabled (elastic_usage is not null)
  if (elasticUsage.value) {
    axios.get('./api/list-indices', {
      params: { start: startStr, end: endStr, granularity }
    }).then((response) => {
      try {
        rawIndices = response.data
        formattedIndices.value = structuredClone(rawIndices).map((index) => formatIndexDate(index))
      } catch (err) {
        console.error('Failed to fetch indices:', err)
      }
    }).catch((err) => {
      console.error('Failed to fetch indices:', err)
    })
  } else {
    // Reset indices data if Elasticsearch is not available
    rawIndices = null
    formattedIndices.value = []
  }
}

// Initial data loading
onBeforeMount(async () => {
  await fetchConfig()
  const config = getConfig()
  if (config) timezone.value = config.timezone

  // Load initial data with default viewMode ('day')
  await fetchDataForPeriod(null, viewMode.value)
})

/**
 * Change the value of the currently selected date
 * @param {number} newDate The new timestamp to set as selected
 */
const changeDate = (newDate) => {
  selectedDate.value = newDate
}

/**
 * Change the view mode
 * @param {string} newMode The new view mode to set
 */
const changeMode = (newMode) => {
  viewMode.value = newMode
}

/**
 * Navigate to the previous or next period based on the current view mode
 * @param {string} direction Either 'prev' or 'next'
 */
const navigatePeriod = (direction) => {
  if (!selectedDate.value) return
  autoZoomRetries.value = 0
  
  const currentDate = new Date(selectedDate.value)
  let newDate

  switch (viewMode.value) {
    case 'day':
      // Navigate by 1 day
      newDate = new Date(currentDate)
      newDate.setUTCDate(currentDate.getUTCDate() + (direction === 'next' ? 1 : -1))
      break
    case 'month':
      // Navigate by 1 month
      newDate = new Date(currentDate)
      newDate.setUTCMonth(currentDate.getUTCMonth() + (direction === 'next' ? 1 : -1))
      break
    case 'quarter':
      // Navigate by 3 months (1 quarter)
      newDate = new Date(currentDate)
      newDate.setUTCMonth(currentDate.getUTCMonth() + (direction === 'next' ? 3 : -3))
      break
    case 'year':
      // Navigate by 1 year
      newDate = new Date(currentDate)
      newDate.setUTCFullYear(currentDate.getUTCFullYear() + (direction === 'next' ? 1 : -1))
      break
  }

  // Update selected date
  if (newDate) {
    selectedDate.value = newDate.getTime()
  }
}

/**
 * Generate logs volumes, ordered by host and time period
 */
const generateHostsVolumeByPeriod = () => {
  const data = []
  const filter = search.value.length > 0 ? hosts.value.filter(host => search.value.includes(host)) : hosts.value

  filter?.forEach((host) => {
    // All logs for a given host
    const hostLogs = logsByHost.value[host]
    const hostData = { name: host }
    const logsInPeriod = utils.getLogsFromPeriod(
      hostLogs,
      currentTimeLimits.value.start,
      currentTimeLimits.value.end
    )

    if (viewMode.value === 'day') {
      hoursValues.forEach((hour) => {
        // All logs from host per hour
        const logsInHour = logsInPeriod.filter((log) => log.dateObject?.getHours() === hour)
        // Sum of all logs sizes to get the hourly volume
        hostData[hour] = {
          data: logsInHour.reduce((acc, log) => acc + log.size, 0),
          rawLogs: logsInHour
        }
      })
    } else if (viewMode.value === 'month') {
      daysValues.value.forEach((day) => {
        const logsInDay = logsInPeriod.filter((log) => log.dateObject?.getDate() === day)
        hostData[day] = logsInDay.reduce((acc, log) => acc + log.size, 0)
      })
    } else if (viewMode.value === 'quarter') {
      quarterWeeksValues.value.forEach((week) => {
        const logsInWeek = logsInPeriod.filter(
          (log) => utils.getWeekNumberFromDate(log.dateObject) === week
        )
        hostData[week] = logsInWeek.reduce((acc, log) => acc + log.size, 0)
      })
    } else if (viewMode.value === 'year') {
      monthsValues.forEach((month) => {
        const logsInMonth = logsInPeriod.filter((log) => log.dateObject?.getMonth() === month)
        hostData[month] = logsInMonth.reduce((acc, log) => acc + log.size, 0)
      })
    }
    data.push(hostData)
  })

  hostsVolumeByPeriod.value = data
  generateTotalVolumeByPeriod()
}

/**
 * Generate total logs volumes added together and ordered by time period
 */
const generateTotalVolumeByPeriod = () => {
  if (!hostsVolumeByPeriod.value) return

  const totals = {}
  let timePeriods = null

  if (viewMode.value === 'day') {
    timePeriods = hoursValues
  } else if (viewMode.value === 'month') {
    timePeriods = daysValues.value
  } else if (viewMode.value === 'quarter') {
    timePeriods = quarterWeeksValues.value
  } else if (viewMode.value === 'year') {
    timePeriods = monthsValues
  }

  timePeriods.forEach((period) => {
    if (viewMode.value === 'day') {
      totals[period] = { data: 0, rawLogs: [] }
      hostsVolumeByPeriod.value.forEach((host) => {
        if (host[period].data !== 0) {
          totals[period].data += host[period].data
          host[period].rawLogs.forEach((log) => totals[period].rawLogs.push(log))
        }
      })
    } else {
      totals[period] = 0
      hostsVolumeByPeriod.value.forEach((host) => {
        if (host[period] !== 0) totals[period] += host[period]
      })
    }
  })

  totalVolumeByPeriod.value = totals
  generateTotalIndexVolumeByPeriod()
}

/**
 * Generate total index volumes ordered by time period
 */
const generateTotalIndexVolumeByPeriod = () => {
  if (!formattedIndices.value || formattedIndices.value.length === 0) return

  const indexTotals = {}
  let timePeriods = null

  if (viewMode.value === 'day') {
    timePeriods = hoursValues
  } else if (viewMode.value === 'month') {
    timePeriods = daysValues.value
  } else if (viewMode.value === 'quarter') {
    timePeriods = quarterWeeksValues.value
  } else if (viewMode.value === 'year') {
    timePeriods = monthsValues
  }

  // Initialize periods with zero values
  timePeriods.forEach(period => {
    indexTotals[period] = 0
  })

  // Filter indices by period and search
  const indicesInPeriod = formattedIndices.value.filter(index => {
    return index.dateObject &&
           index.dateObject.getTime() >= currentTimeLimits.value.start &&
           index.dateObject.getTime() <= currentTimeLimits.value.end &&
           (!search.value.length || search.value.includes(index.hostname))
  })

  // Aggregate data by period
  indicesInPeriod.forEach(index => {
    if (!index.dateObject) return

    if (viewMode.value === 'day') {
      const hour = index.dateObject.getHours()
      indexTotals[hour] += index.size || 0
    } else if (viewMode.value === 'month') {
      const day = index.dateObject.getDate()
      indexTotals[day] += index.size || 0
    } else if (viewMode.value === 'quarter') {
      const week = utils.getWeekNumberFromDate(index.dateObject)
      if (quarterWeeksValues.value.includes(week)) {
        indexTotals[week] += index.size || 0
      }
    } else if (viewMode.value === 'year') {
      const month = index.dateObject.getMonth()
      indexTotals[month] += index.size || 0
    }
  })

  totalIndexVolumeByPeriod.value = indexTotals
}

/**
 * Format valid dates as a JS Date object
 * @param {Object} log - The log object to format
 * @returns {Object} The formatted log object
 */
const formatLogDate = (log) => {
  log.rawDate = log.date
  const dateObject = new Date(log.date)

  /** @WORKAROUND Temporary hotfix to avoid incoherent dates (year of 32120 etc.) */
  if (dateObject.getFullYear() <= new Date().getFullYear()) {
    log.dateObject = dateObject
    log.date = new Intl.DateTimeFormat('fr-FR').format(log.dateObject)
  }

  return log
}

/**
 * Set the time limits based on the view mode and the selected date
 * @param mode The mode for which to set the time limits
 */
const setCurrentTimeLimits = (mode) => {
  const startObject = new Date(selectedDate.value)
  const endObject = new Date(selectedDate.value)
  startObject.setHours(0, 0, 0, 0)
  endObject.setHours(23, 59, 59, 999)

  if (mode === 'day') {
    // Simply set start of day and end of day as time limits
    currentTimeLimits.value.start = startObject.getTime()
    currentTimeLimits.value.end = endObject.getTime()
  } else if (mode === 'year') {
    // Set start of reference year and end of reference year as time limits
    currentTimeLimits.value.start = startObject.setMonth(0, 1)
    currentTimeLimits.value.end = endObject.setMonth(11, 31)
  } else if (mode === 'quarter') {
    // For quarter mode, we first need to know in which quarter the reference date is :
    const currentMonth = new Date(selectedDate.value).getMonth()
    // Set time limits depending on quarter of the reference month
    if ([0, 1, 2].includes(currentMonth)) {
      currentTimeLimits.value.start = startObject.setMonth(0, 1)
      currentTimeLimits.value.end = endObject.setMonth(2, 31)
      quarterWeeksValues.value = q1weeks
      currentQuarter.value = 1
    } else if ([3, 4, 5].includes(currentMonth)) {
      currentTimeLimits.value.start = startObject.setMonth(3, 1)
      currentTimeLimits.value.end = endObject.setMonth(5, 31)
      quarterWeeksValues.value = q2weeks
      currentQuarter.value = 2
    } else if ([6, 7, 8].includes(currentMonth)) {
      currentTimeLimits.value.start = startObject.setMonth(6, 1)
      currentTimeLimits.value.end = endObject.setMonth(8, 31)
      quarterWeeksValues.value = q3weeks
      currentQuarter.value = 3
    } else if ([9, 10, 11].includes(currentMonth)) {
      currentTimeLimits.value.start = startObject.setMonth(9, 1)
      currentTimeLimits.value.end = endObject.setMonth(11, 31)
      quarterWeeksValues.value = q4weeks
      currentQuarter.value = 4
    }
  } else if (mode === 'month') {
    /**
     * Calculates the total number of days in the selected month
     * @param y year
     * @param m month
     * @returns {Number} the number of days in the selected month
     */
    const numDays = (y, m) => new Date(y, m, 0).getDate()

    const selectedDateObject = new Date(selectedDate.value)
    const numberOfDays = numDays(
      selectedDateObject.getFullYear(),
      selectedDateObject.getMonth() + 1
    )
    // Update the array of days with the correct number of days
    daysValues.value = [...Array(numberOfDays).keys()].map((key) => Number(key) + 1)
    // Finally, set the current time limits
    currentTimeLimits.value.start = startObject.setDate(1)
    currentTimeLimits.value.end = endObject.setDate(numberOfDays)
  }
}

/**
 * Handles the update of selections in the combobox
 * @param {Array|null} event - The selected elements
 */
const handleSearch = (event) => {
  // Check if selections are objects or strings
  if (event && Array.isArray(event)) {
    // Convert selections to IPs (values)
    search.value = event.map(item => {
      // If it's an object with a value property (combobox item selection)
      if (item && typeof item === 'object' && 'value' in item) {
        return item.value
      }
      // If it's a string (manual input or direct selection)
      return item
    })
  } else {
    search.value = event
  }
}

// Watchers
watch(
  formattedLogs,
  (newLogs) => {
    if (newLogs?.length > 0) {
      // Only initialize selectedDate on first load (when selectedDate is null)
      // viewMode is already initialized to 'day' by default (line 146)
      const isInitialLoad = !selectedDate.value

      if (isInitialLoad) {
        // Calculate the latest log entry date
        mostRecentLogDate.value = utils.getMostRecentLogDate(newLogs)
        selectedDate.value = mostRecentLogDate.value
      }

      // Get all unique hosts
      hosts.value = utils.getUniqueHosts(newLogs)
      // Organise logs by host
      logsByHost.value = utils.getLogsByHost(newLogs, hosts.value)
      // Set the current time limits based on the last log entry
      setCurrentTimeLimits(viewMode.value)
      generateHostsVolumeByPeriod()
    }
  },
  { immediate: true }
)

// Watcher for index data
watch(
  formattedIndices,
  (newIndices) => {
    if (newIndices?.length > 0 && currentTimeLimits.value.start) {
      // Generate index volumes by period
      generateTotalIndexVolumeByPeriod()
    }
  },
  { immediate: true }
)

watch(viewMode, (newMode) => {
  setCurrentTimeLimits(newMode)
  // Skip fetch during auto-zoom (auto-zoom handles its own fetches)
  if (selectedDate.value && autoZoomRetries.value === 0) {
    fetchDataForPeriod(selectedDate.value, newMode)
  }
  generateHostsVolumeByPeriod()
})

watch(selectedDate, () => {
  setCurrentTimeLimits(viewMode.value)
  // Skip fetch during auto-zoom (auto-zoom handles its own fetches)
  if (selectedDate.value && autoZoomRetries.value === 0) {
    fetchDataForPeriod(selectedDate.value, viewMode.value)
  }
  generateHostsVolumeByPeriod()
})

watch(search, () => {
  generateHostsVolumeByPeriod()
})
</script>

<style scoped>
.z__main-toolbar {
  justify-content: space-between;
  align-items: center;
  display: flex;
  padding: 0 16px;
  margin-bottom: 16px;
}

.z__app-title-container {
  align-items: center;
  display: flex;
}

.z__app-title {
  align-items: center;
  display: flex;
  margin: 0;
  font-weight: 500;
  font-size: 1.25rem;
}

.title-icon {
  margin-right: 8px;
}

.z__period-navigator {
  justify-content: center;
  align-items: center;
  display: flex;
}

.date-parts {
  align-items: center;
  display: flex;
  margin: 0 4px;
}

.date-part {
  transition: all 0.2s;
  cursor: pointer;
  padding: 2px 4px;
  border-radius: 4px;
}
.date-part:hover {
  background: #0000000d;
}

.date-part-active {
  color: var(--v-theme-primary);
  font-weight: 600;
}

.date-separator {
  color: #00000099;
  margin: 0 2px;
}

.date-part-quarter {
  color: #00000099;
  margin-left: 4px;
  font-size: 0.9em;
}

.z__searchbar {
  position: relative;
  width: 300px;
}

/* Styles for host selector */
.host-selector :deep(.v-field__input) {
  padding-bottom: 4px;
  padding-top: 4px;
}
.host-selector :deep(.v-chip) {
  margin-bottom: 2px;
  margin-top: 2px;
}
.host-selector :deep(.v-field__clearable) {
  --v-input-padding-top: 5px;
}

/* Styles for action buttons */
.host-selector-actions {
  transform: translateY(-50%);
  flex-direction: column;
  position: absolute;
  display: flex;
  right: -40px;
  top: 50%;
  gap: 4px;
}

.action-btn {
  transition: opacity 0.2s;
  opacity: 0.7;
}
.action-btn:hover {
  opacity: 1;
}

.z__chart-table-container {
  height: calc(100vh - 140px);
  flex-direction: column;
  display: flex;
}

.nav-arrow {
  margin: 0 2px;
}

.z__error-message {
  text-align: center;
  color: #f44336;
  padding: 16px;
  font-weight: 500;
}

.z__chart-table-container {
  flex-direction: column;
  display: flex;
  gap: 0;
  margin-top: 10px;
}

#v-menu-2 {
  .v-list {
    padding: 0;
  }
  .v-list-item {
    min-height: 40px !important;
  }

  .v-list-item-title {
    font-size: 12px;
  }
}

.z__main-toolbar {
  justify-content: space-between;
  flex-direction: row;
  align-items: center;
  display: flex;
  gap: 10px;
  width: 100%;
  padding: 0;
  margin-top: 15px;
  margin-bottom: 15px;

  .z__app-title-container {
    background: var(--color-background-mute);
    border-radius: 6px;
    padding: 5px 10px;
    max-width: 400px;
    min-width: 350px;
    flex: 1;

    .z__app-title {
      text-overflow: ellipsis;
      align-items: center;
      white-space: nowrap;
      overflow: hidden;
      color: #2c3e50;
      display: flex;
      margin: 0;
      font-size: 17px;
      font-weight: 600;

      .title-icon {
        margin-right: 8px;
        font-size: 22px;
      }

      span { color: #2fb4c5; }
    }
  }

  .z__period-navigator {
    background: var(--color-background-mute);
    align-items: center;
    white-space: nowrap;
    display: flex;
    padding: 5px 4px;
    border-radius: 6px;

    /* Style for the navigation arrows */
    .nav-arrow {
      min-width: 24px;
      height: 24px;
      width: 24px;
    }

    /* Container for the date parts */
    .date-parts {
      align-items: center;
      display: flex;
      padding: 0 4px;
      font-size: 14px;
      font-weight: 500;

      /* Style for each clickable date part */
      .date-part {
        transition: all 0.2s ease;
        user-select: none;
        cursor: pointer;
        padding: 2px 4px;
        border-radius: 4px;

        &:hover {
          background: #17b8ce1a;
        }
      }

      /* Active date part styling */
      .date-part-active {
        background: #17b8ce33;
        font-weight: 600;
        color: #17b8ce;
      }

      /* Quarter indicator styling */
      .date-part-quarter {
        margin-left: 4px;
        font-size: 12px;
        color: #666;
      }

      /* Date separator styling */
      .date-separator {
        margin: 0 2px;
        color: #999;
        user-select: none;
      }
    }
  }
}

.z__searchbar {
  max-width: 400px;
  flex: 1;

  .host-selector-container {
    background: var(--color-background-mute);
    align-items: center;
    display: flex;
    gap: 8px;
    padding: 4px 10px;
    border-radius: 6px;
  }

  .filter-icon {
    font-size: 22px;
    flex-shrink: 0;
  }

  .v-chip {
    border: 1px solid #17b8ce33;
    background: #17b8ce1a;
    height: 20px;

    &:hover {
      background: #17b8ce33;
    }
  }
}

/* Responsive adjustments */
@media (max-width: 960px) {
  .z__main-toolbar {
    flex-direction: column;
    gap: 15px;

    .z__app-title-container,
    .z__period-navigator,
    .z__searchbar {
      max-width: 100%;
      width: 100%;
    }
  }
}
</style>

<style>
/* Overrides Vuetify outside of scoped styles */
.host-selector input::placeholder {
  opacity: 1 !important;
}
.host-selector .v-field__append-inner {
  align-items: center !important;
  padding: 0 !important;
}
</style>
