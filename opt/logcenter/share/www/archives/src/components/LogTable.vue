<template>
  <div class="table-container">
    <v-dialog max-width="500" v-model="downloadDialog">
      <v-card title="Téléchargement">
        <v-card-text> Voulez-vous télécharger ces logs ? </v-card-text>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn text="Annuler" @click="downloadDialog = false"></v-btn>
          <v-btn text="Télécharger" @click="confirmDownload()" color="primary"></v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-data-table
      v-if="!props.error"
      :items="filteredData"
      :headers="currentModeHeaders"
      height="100%"
      fixed-header
      :loading="loading"
      :items-per-page="25"
    >
      <template v-slot:item="{ item }">
        <tr class="v-data-table__tr">
          <template v-for="header in currentModeHeaders" :key="header.key">
            <td v-if="header.key !== 'name'"
              class="v-data-table__td"
              :title="item[header.key].title"
              :class="cellClasses()"
              @click="onCellClick(item, header)"
            >
              {{ item[header.key].value }}{{ item[header.key].unit }}
            </td>
            <td v-else class="v-data-table__td" :title="item[header.key].raw">
              <span :title="item.name">{{ item[header.key] }}</span>
            </td>
          </template>
        </tr>
      </template>
    </v-data-table>
    <div v-else class="z__error-message">{{ props.error }}</div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import axios from 'axios'
import {
  getHumanReadableByteSize,
  monthsLabels,
  formatAndDownloadLogs,
  changeDateFromWeekNumber
} from '@/plugins/utils'

// Props
const props = defineProps(['config', 'error'])

const timeValues = props.config.timeValues

// Data
const tableData = ref([])
const downloadDialog = ref(false)
const downloadIsConfirmed = ref(false)

// Component Events
const emit = defineEmits(['change-date', 'change-mode'])

/**
 * @computed The table data filtered by the search data
 */
const filteredData = computed(() => {
  return tableData.value.filter((item) => {
    if (!props.config.search || props.config.search.length === 0) return true
    return props.config.search.some((host) => item.name.includes(host))
  })
})

const currentModeHeaders = ref(null)
const loading = ref(true)
/**
 * Get classes for a given cell
 * @param value The value of the cell
 * @returns {string} the classes for the cell
 */
const cellClasses = () => {
  return `mode__${props.config.viewMode} cell__hover`
}

/**
 * Handle a click action on a table cell :
 * Either scale the view-mode down to a narrower time period,
 * Or download the corresponding logs as a JSON file when on "lowest" view-mode (day).
 * @param item The whole table line object
 * @param header The corresponding header config object
 */
const onCellClick = (item, header) => {
  const cellContent = item[header.key]
  const date = new Date(props.config.date)

  if (props.config.viewMode === 'day' && cellContent.logs?.length > 0) {
    downloadDialog.value = true

    watch(downloadIsConfirmed, (value) => {
      if (value) {
        const clickedDate = cellContent.logs[0].dateObject.getTime()
        formatAndDownloadLogs(axios, cellContent.logs, clickedDate, item.name)
        downloadIsConfirmed.value = false
      }
    })
  } else if (props.config.viewMode === 'quarter') {
    const adjustedDate = changeDateFromWeekNumber(date, Number(header.key))
    emit('change-date', adjustedDate)
    emit('change-mode', 'month')
  } else if (props.config.viewMode === 'month') {
    date.setUTCDate(header.key)
    emit('change-date', date.getTime())
    emit('change-mode', 'day')
  } else if (props.config.viewMode === 'year') {
    date.setUTCMonth(header.key)
    emit('change-date', date.getTime())
    emit('change-mode', 'month')
  }
}

/**
 * Confirm the download of the logs
 * Triggered by the dialog
 */
const confirmDownload = () => {
  downloadIsConfirmed.value = true
  downloadDialog.value = false
}

/**
 * Generate table headers depending on the current time mode
 */
const generateHeaders = () => {
  const headers = [{ title: 'Nom', key: 'name', sortable: false }]

  if (props.config.viewMode === 'day') {
    // Generating 24 hourly headers
    headers.push(
      ...timeValues.hours.map((hour) => ({
        title: hour < 10 ? `0${hour}:00` : `${hour}:00`,
        key: String(hour),
        sortable: false,
        align: 'center'
      }))
    )
  } else if (props.config.viewMode === 'month') {
    headers.push(
      ...timeValues.days.map((day) => ({ title: day, key: String(day), sortable: false }))
    )
  } else if (props.config.viewMode === 'quarter') {
    headers.push(
      ...timeValues.quarterWeeks.map((week) => ({
        title: `Sem ${week}`,
        key: String(week),
        sortable: false
      }))
    )
  } else if (props.config.viewMode === 'year') {
    headers.push(
      ...timeValues.months.map((month) => ({
        title: monthsLabels[month],
        key: String(month),
        sortable: false
      }))
    )
  }
  currentModeHeaders.value = headers
}

watch(
  props.config,
  (newConfig) => {
    if (newConfig.hostsVolumeByPeriod.length > 0) {
      tableData.value = newConfig.hostsVolumeByPeriod.map((item) => {
        const newItem = {}
        Object.keys(item).forEach((key) => {
          if (key !== 'name') {
            const data = item[key].data || item[key]
            const logs = item[key].rawLogs
            const humanReadableSize = getHumanReadableByteSize(data)

            newItem[key] = {
              value: humanReadableSize.value,
              unit: humanReadableSize.unit,
              text: humanReadableSize.toString(),
              logs
            }
            newItem[key].raw = props.config.viewMode === 'day' ? item[key].data : item[key]

            // Set the tooltip depending on the view mode
            if (newConfig.viewMode === 'day') {
              newItem[key].title = 'Télécharger ces logs'
            } else if (newConfig.viewMode !== 'quarter') {
              newItem[key].title = 'Voir les logs de cette période'
            } else {
              newItem[key].title = humanReadableSize.toString()
            }
          } else {
            newItem['name'] = item['name']
          }
        })
        return newItem
      })
      generateHeaders()
      loading.value = false
    }
  },
  { immediate: true }
)
</script>

<style lang="scss">
.v-table {
  border-radius: 4px !important;
  font-size: 12px !important;
  width: 100% !important;
  min-height: 400px;
  max-height: 450px;

  .v-table__wrapper {
    // Hide the scrollbar
    -ms-overflow-style: none; /* IE and Edge */
    scrollbar-width: none;

    &::-webkit-scrollbar {
      display: none;
    }
  }
}

.v-data-table__th {
  padding: 0 0 0 8px !important;
  height: 32px !important;
  box-shadow: inset 0 -2px 0 rgb(var(--v-theme-primary)) !important;
  white-space: nowrap;

  .v-data-table-header__content {
    font-weight: bold;
  }

  &:not(:nth-child(1)) {
    span {
      width: 100%;
      text-align: center;
    }
  }
}

.v-data-table__tr td {
  &:not(:nth-child(1)) {
    font-size: 11px;
  }
  padding: 0 4px !important;
  height: 32px !important;
  white-space: nowrap;
  border: none !important;

  &:not(:nth-child(1)) {
    text-align: center;
    white-space: normal;
  }

  &:nth-child(1) {
    width: 150px;
    padding: 0 0 0 8px !important;
    background: transparent;
    overflow-x: hidden;
    text-overflow: ellipsis;
    font-weight: bold;
  }

  &.mode__day {
    max-width: 38px;
    min-width: 38px;
  }

  &.mode__month {
    min-width: 30px;
    max-width: 30px;
  }

  &.mode__quarter {
    min-width: 72px;
    max-width: 72px;
  }

  &.mode__year {
    min-width: 78px;
    max-width: 78px;
  }

  &.cell__hover:hover {
    cursor: pointer;
  }
}

.v-data-table-footer .v-select__selection-text {
  font-size: 12px;
}

.v-data-table-footer .v-pagination__list {
  color: rgb(var(--v-theme-primary));
}

tbody > :nth-child(odd) {
  background-color: rgb(var(--v-theme-primary-super-light)) !important;
}

#v-menu-11 * {
  font-size: 12px !important;
}

.z__error-message {
  color: red;
  text-align: center;
  background-color: rgb(var(--v-theme-primary-super-light));
  border: 1px solid rgb(var(--v-theme-primary));
  border-radius: 10px;
  padding: 30px 0;
  margin: 0 auto;
  font-size: 18px;
  width: 500px;
}
</style>
