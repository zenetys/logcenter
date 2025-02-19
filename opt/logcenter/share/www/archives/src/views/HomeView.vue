<template>
  <main>
    <div class="z__toolbar-container mt-2" v-show="selectedDate">
      <div class="z__current-date mt-3">
        <strong>Date sélectionnée : {{ selectedFullDate }}</strong>
        <v-tooltip
          location="bottom"
          text="Réinitialiser à la date la plus récente"
          transition="fade-transition"
        >
          <template v-slot:activator="{ props }">
            <v-btn
              v-bind="props"
              color="primary"
              icon="mdi-cancel"
              size="x-small"
              class="ml-2 reset-date-button"
              @click="selectedDate = mostRecentLogDate"
            ></v-btn>
          </template>
        </v-tooltip>
      </div>
      <div class="z__searchbar pl-4 pr-4">
        <v-autocomplete
          label="Rechercher un hôte"
          density="compact"
          :items="hosts"
          bg-color="primary-super-light"
          base-color="primary-darken-1"
          color="primary-darken-1"
          clearable
          multiple
          single-line
          @update:modelValue="handleSearch"
        ></v-autocomplete>
      </div>
      <div class="z__mode-selector-container mt-3">
        <v-btn
          color="primary"
          class="ml-2 mr-2"
          size="x-small"
          :active="viewMode === 'day'"
          @click="viewMode = 'day'"
          >Jour</v-btn
        >
        <v-btn
          color="primary"
          class="ml-2 mr-2"
          size="x-small"
          :active="viewMode === 'month'"
          @click="viewMode = 'month'"
          >Mois</v-btn
        >
        <v-btn
          color="primary"
          class="ml-2 mr-2"
          size="x-small"
          :active="viewMode === 'quarter'"
          @click="viewMode = 'quarter'"
          >Trimestre</v-btn
        >
        <v-btn
          color="primary"
          class="ml-2 mr-2"
          size="x-small"
          :active="viewMode === 'year'"
          @click="viewMode = 'year'"
          >Année</v-btn
        >
      </div>
    </div>
    <LogChart
      class="z__log-chart"
      :config="chartConfig"
      @change-date="changeDate"
      @change-mode="changeMode"
    />
    <LogTable
      class="z__log-table"
      :config="tableConfig"
      @change-date="changeDate"
      @change-mode="changeMode"
    />
  </main>
</template>

<script setup>
import LogTable from '../components/LogTable.vue'
import LogChart from '../components/LogChart.vue'
import * as utils from '../plugins/utils.js'

import { onBeforeMount, ref, watch, computed } from 'vue'
import axios from 'axios'

// Default view mode is "day"
const viewMode = ref('day')

let rawLogs = null
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
onBeforeMount(() => {
  axios.get('./api/list-archives').then((response) => {
    rawLogs = response.data
    formattedLogs.value = structuredClone(rawLogs).map((log) => formatLogDate(log))
  })
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
 * Generate logs volumes, ordered by host and time period
 */
const generateHostsVolumeByPeriod = () => {
  const data = []

  hosts.value?.forEach((host) => {
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
        const logsInHour = logsInPeriod.filter((log) => log.dateObject?.getUTCHours() === hour)
        // Sum of all logs sizes to get the hourly volume
        hostData[hour] = {
          data: logsInHour.reduce((acc, log) => acc + log.size, 0),
          rawLogs: logsInHour
        }
      })
    } else if (viewMode.value === 'month') {
      daysValues.value.forEach((day) => {
        const logsInDay = logsInPeriod.filter((log) => log.dateObject?.getUTCDate() === day)
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
        const logsInMonth = logsInPeriod.filter((log) => log.dateObject?.getUTCMonth() === month)
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
  startObject.setUTCHours(0, 0, 0, 0)
  endObject.setUTCHours(23, 59, 59, 999)

  if (mode === 'day') {
    // Simply set start of day and end of day as time limits
    currentTimeLimits.value.start = startObject.getTime()
    currentTimeLimits.value.end = endObject.getTime()
  } else if (mode === 'year') {
    // Set start of reference year and end of reference year as time limits
    currentTimeLimits.value.start = startObject.setUTCMonth(0, 1)
    currentTimeLimits.value.end = endObject.setUTCMonth(11, 31)
  } else if (mode === 'quarter') {
    // For quarter mode, we first need to know in which quarter the reference date is :
    const currentMonth = new Date(selectedDate.value).getUTCMonth()
    // Set time limits depending on quarter of the reference month
    if ([0, 1, 2].includes(currentMonth)) {
      currentTimeLimits.value.start = startObject.setUTCMonth(0, 1)
      currentTimeLimits.value.end = endObject.setUTCMonth(2, 31)
      quarterWeeksValues.value = q1weeks
      currentQuarter.value = 1
    } else if ([3, 4, 5].includes(currentMonth)) {
      currentTimeLimits.value.start = startObject.setUTCMonth(3, 1)
      currentTimeLimits.value.end = endObject.setUTCMonth(5, 31)
      quarterWeeksValues.value = q2weeks
      currentQuarter.value = 2
    } else if ([6, 7, 8].includes(currentMonth)) {
      currentTimeLimits.value.start = startObject.setUTCMonth(6, 1)
      currentTimeLimits.value.end = endObject.setUTCMonth(8, 31)
      quarterWeeksValues.value = q3weeks
      currentQuarter.value = 3
    } else if ([9, 10, 11].includes(currentMonth)) {
      currentTimeLimits.value.start = startObject.setUTCMonth(9, 1)
      currentTimeLimits.value.end = endObject.setUTCMonth(11, 31)
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
      selectedDateObject.getUTCFullYear(),
      selectedDateObject.getUTCMonth() + 1
    )
    // Update the array of days with the correct number of days
    daysValues.value = [...Array(numberOfDays).keys()].map((key) => Number(key) + 1)
    // Finally, set the current time limits
    currentTimeLimits.value.start = startObject.setUTCDate(1)
    currentTimeLimits.value.end = endObject.setUTCDate(numberOfDays)
  }
}

const handleSearch = (event) => {
  search.value = event
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

<style lang="scss">
.z__log-table {
  width: 100%;
}

.z__toolbar-container {
  display: flex;
  width: 100%;

  .z__mode-selector-container {
    height: 100%;
    width: 30%;
    justify-content: center;
    display: flex;
    flex-direction: row;

    .v-btn--active {
      background: transparent !important;
      border: 1px solid #17b8ce !important;
      box-shadow: 0px 0px 5px #17b8ce;

      .v-btn__content {
        color: #17b8ce !important;
      }
    }
  }

  .z__current-date {
    width: 40%;
    font-size: 12px;
    text-align: center;
    vertical-align: middle;

    strong {
      vertical-align: middle;
    }
  }

  .z__searchbar {
    width: 70%;
    max-height: 40px;

    .v-field-label {
      font-size: 10px !important;
    }

    .v-autocomplete__selection-text,
    #input-0 {
      font-size: 12px !important;
    }

    .v-field__input {
      overflow: auto;
      flex-wrap: nowrap;
      scrollbar-width: none;
      -ms-overflow-style: none; /* IE and Edge */

      .no-scrollbar::-webkit-scrollbar {
        display: none;
      }
    }
  }
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

.reset-date-button {
  width: 25px !important;
  height: 25px !important;
}
</style>
