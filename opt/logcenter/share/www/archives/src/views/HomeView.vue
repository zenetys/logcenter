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
          <!-- Jour cliquable -->
          <span 
            :class="['date-part', viewMode === 'day' ? 'date-part-active' : '']"
            @click="viewMode = 'day'">
            {{ formattedDay }}
          </span>
          
          <!-- Séparateur -->
          <span class="date-separator">/</span>
          
          <!-- Mois cliquable -->
          <span 
            :class="['date-part', viewMode === 'month' ? 'date-part-active' : '']"
            @click="viewMode = 'month'">
            {{ formattedMonth }}
          </span>
          
          <!-- Séparateur -->
          <span class="date-separator">/</span>
          
          <!-- Année cliquable -->
          <span 
            :class="['date-part', viewMode === 'year' ? 'date-part-active' : '']"
            @click="viewMode = 'year'">
            {{ formattedYear }}
          </span>

          <!-- Trimestre (affiché conditionnellement) -->
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
        <v-combobox
          label="Filtrer par machine"
          density="compact"
          :items="hostsWithAliases"
          item-title="title"
          item-value="value"
          bg-color="grey-lighten-4"
          color="primary"
          variant="outlined"
          clearable
          multiple
          hide-details
          chips
          closable-chips
          @update:modelValue="handleSearch"
          prepend-icon="mdi-server"
        ></v-combobox>
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

import { onBeforeMount, ref, watch, computed } from 'vue'
import axios from 'axios'

// Default view mode is "day"
const viewMode = ref('day')

let rawLogs = null
const error = ref(null)
const timezone = ref('')
const formattedLogs = ref([])
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
  return hosts.value.map(host => ({
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
  date: selectedDate,
  currentQuarter,
  search
})

// Fetching all logs and formatting them
onBeforeMount(async () => {
  axios.get('./api/list-archives').then((response) => {
    try {
      rawLogs = response.data
      formattedLogs.value = structuredClone(rawLogs).map((log) => formatLogDate(log))
    } catch (err) {
      error.value = 'Failed to fetch logs'
      console.error('Failed to fetch logs:', err)
    }
  }).catch((err) => {
    error.value = 'Failed to fetch logs'
    console.error('Failed to fetch logs:', err)
  })

  await fetchConfig()
  const config = getConfig()
  if (config) timezone.value = config.timezone
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

const handleSearch = (event) => {
  // Vérifier si les sélections sont des objets ou des chaînes
  if (event && Array.isArray(event)) {
    // Convertir les sélections en IPs (valeurs)
    search.value = event.map(item => {
      // Si c'est un objet avec une propriété value (sélection d'un item du combobox)
      if (item && typeof item === 'object' && 'value' in item) {
        return item.value
      }
      // Si c'est une chaîne (saisie manuelle ou sélection directe)
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
      viewMode.value = 'day'
      // Calculate the latest log entry date
      mostRecentLogDate.value = utils.getMostRecentLogDate(newLogs)
      selectedDate.value = mostRecentLogDate.value
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

watch(viewMode, (newMode) => {
  setCurrentTimeLimits(newMode)
  generateHostsVolumeByPeriod()
})

watch(selectedDate, () => {
  setCurrentTimeLimits(viewMode.value)
  generateHostsVolumeByPeriod()
})

watch(search, () => {
  generateHostsVolumeByPeriod()
})
</script>

<style>
.z__chart-table-container {
  display: flex;
  flex-direction: column;
  margin-top: 10px;
  gap: 0; /* Eliminates the space between flex elements */
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
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  margin-bottom: 15px;
  margin-top: 15px;
  gap: 10px;
  padding: 0 10px;
  /* Main toolbar containing title, date selector and machine filter */
  
  .z__app-title-container {
    flex: 1;
    min-width: 350px;
    max-width: 400px;
    background-color: #f5f5f5;
    border-radius: 6px;
    padding: 5px 10px;
    /* Title container with increased width to show full text */
    
    .z__app-title {
      display: flex;
      align-items: center;
      font-size: 17px;
      font-weight: 600;
      color: #2c3e50;
      margin: 0;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      /* Main app title styling with enhanced visibility */
      
      .title-icon {
        margin-right: 8px;
        font-size: 22px;
        /* Icon styling to complement the title */
      }
      
      span {
        background-image: linear-gradient(to right, #17b8ce, #1e7b98);
        background-clip: text;
        -webkit-background-clip: text;
        color: transparent;
        text-shadow: 0px 1px 1px rgba(255,255,255,0.5);
        /* Gradient text effect for title */
      }
    }
  }
  
  .z__period-navigator {
    display: flex;
    align-items: center;
    white-space: nowrap;
    background-color: #f5f5f5;
    border-radius: 6px;
    padding: 2px 4px;
    /* Period selection component with interactive date parts */
    
    /* Style for the navigation arrows */
    .nav-arrow {
      min-width: 24px;
      width: 24px;
      height: 24px;
    }
    
    /* Container for the date parts */
    .date-parts {
      display: flex;
      align-items: center;
      padding: 0 4px;
      font-size: 14px;
      font-weight: 500;
      
      /* Style for each clickable date part */
      .date-part {
        cursor: pointer;
        padding: 2px 4px;
        border-radius: 4px;
        transition: all 0.2s ease;
        user-select: none;
        
        &:hover {
          background-color: rgba(23, 184, 206, 0.1);
        }
      }
      
      /* Active date part styling */
      .date-part-active {
        background-color: rgba(23, 184, 206, 0.2);
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
  flex: 1;
  max-width: 400px;
  max-height: 40px;

  .v-field {
    border-radius: 6px;
  }

  .v-field-label, .v-autocomplete__selection-text {
    font-size: 14px !important;
  }
  
  .v-chip {
    height: 20px;
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
      width: 100%;
      max-width: 100%;
    }
  }
}
</style>
