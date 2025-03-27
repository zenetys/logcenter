<template>
  <div class="z__bar-chart-container">
  <!-- <div class="mt-3 z__bar-chart-container container mb-5"> -->
    <!--
    <v-dialog max-width="500" v-model="downloadDialog">
      <v-card title="Téléchargement">
        <v-card-text>
          Voulez-vous télécharger les logs correspondant à cette période ?
        </v-card-text>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn text="Annuler" @click="downloadDialog = false"></v-btn>
          <v-btn text="Télécharger" @click="confirmDownload()" color="primary"></v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    -->
    <Bar id="z__bar-chart" v-if="chartIsLoaded" :data="chartData" :options="options" />
  </div>
</template>

<script setup>
import { ref, watch, nextTick } from 'vue'
import axios from 'axios'
import {
  getHumanReadableByteSize,
  monthsLabels,
  downloadLogs,
  changeDateFromWeekNumber
} from '@/plugins/utils'
import { Bar } from 'vue-chartjs'
import {
  Chart as ChartJS,
  Title,
  Tooltip,
  Legend,
  BarElement,
  CategoryScale,
  LinearScale
} from 'chart.js'

// Chart Config & Setup
ChartJS.register(Title, Tooltip, Legend, BarElement, CategoryScale, LinearScale)
const chartData = ref({ labels: [], datasets: [] })
const chartIsLoaded = ref(false)
const options = ref({
  maintainAspectRatio: false,
  scales: {
    y: {
      afterFit: (scaleInstance) => {
        scaleInstance.width = 80 // sets the width to 80px
      },
      afterTickToLabelConversion(scaleInstance) {
        // Convert Y scale ticks to human readable byte sizes
        scaleInstance.ticks = scaleInstance.ticks.map((tick) => {
          const humanReadableTick = getHumanReadableByteSize(tick.value, 1)
          return {
            value: tick.value,
            label: humanReadableTick.toString()
          }
        })
      },
      ticks: {
        padding: 25
      }
    }
  },
  plugins: {
    tooltip: {
      callbacks: {
        label: (context) => {
          // Convert tooltip values to human readable byte sizes
          let label = context.dataset.label || ''

          if (label) {
            label += ': '
          }

          if (context.parsed.y !== null) {
            label += getHumanReadableByteSize(context.parsed.y).toString()
          }
          return label
        }
      }
    },
    legend: {
      // Preventing default onClick behaviour on legends
      onClick: () => {}
    }
  },
  parsing: {
    xAxisKey: 'time',
    yAxisKey: 'data'
  },
  onHover: (event, elements) => {
    event.native.target.style.cursor = elements && elements.length > 0 ? 'pointer' : 'default'
  },
  onClick: (event, elements) => {
    if (!elements || elements.length <= 0) return
    else {
      const clickedItem = elements[0]
      const date = new Date(props.config.date)
      const selectedTotal = props.config.totals[clickedItem.index]

      if (props.config.viewMode === 'day' && selectedTotal.rawLogs && selectedTotal.rawLogs[0]) {
        // Download raw logs for the clicked hour
        downloadDialog.value = true
        downloadPendingData.value = selectedTotal.rawLogs
      } else if (props.config.viewMode === 'quarter') {
        // change date to first day of the selected ISO week and drill down to month view
        const clickedWeek = Number(Object.keys(props.config.totals)[clickedItem.index])
        const adjustedDate = changeDateFromWeekNumber(date, clickedWeek)
        emit('change-date', adjustedDate)
        emit('change-mode', 'month')
      } else if (props.config.viewMode === 'month') {
        date.setDate(clickedItem.index + 1)
        // change date and drill down to day view
        emit('change-date', date.getTime())
        emit('change-mode', 'day')
      } else if (props.config.viewMode === 'year') {
        // change date and drill down to month view
        date.setMonth(clickedItem.index)
        emit('change-date', date.getTime())
        emit('change-mode', 'month')
      }
    }
  }
})

// Props
const props = defineProps(['config'])

// Data
const config = props.config
const downloadDialog = ref(false)
const downloadPendingData = ref(null)
const label = ref('Total par heure')

// Component Events
const emit = defineEmits(['change-date', 'change-mode'])

/**
 * Confirm the download of the logs
 * Triggered by the dialog
 */
const confirmDownload = () => {
  if (downloadPendingData.value) {
    downloadLogs(axios, downloadPendingData.value)
    downloadPendingData.value = null
  }
  downloadDialog.value = false
}

/**
 * Filter data based on search
 * @param labels The provided labels
 * @param totals The provided totals
 * @param search The search query
 *
 * @returns The filtered data
 */
const filterData = (labels, totals, search) => {
  return Object.keys(totals).map((key, index) => {
    const rawLogs = totals[key]?.rawLogs || []
    const filteredLogs = search.length > 0 ? rawLogs.filter(log => search.includes(log.hostname)) : rawLogs
    const totalSize = filteredLogs.reduce((sum, log) => sum + (log.size || 0), 0)

    if (config.viewMode === 'month') {
      return { time: monthsLabels[key], data: totalSize || totals[key], rawLogs: filteredLogs }
    } else if (config.viewMode === 'quarter') {
      return { time: `Trimestre ${Math.ceil(key / 3)}`, data: totalSize || totals[key], rawLogs: filteredLogs }
    } else if (config.viewMode === 'year') {
      return { time: `Année ${key}`, data: totalSize || totals[key], rawLogs: filteredLogs }
    } else {
      return filteredLogs.length > 0 ? { time: labels[index], data: totalSize || totals[key].data || totals[key], rawLogs: filteredLogs } : null
    }
  }).filter(item => item !== null)
}

/**
 * Set the label based on the view mode
 * @param labels The labels
 *
 * @returns The label
 */
const setLabel = (labels) => {
  const dateObject = new Date(config.date)
  const labelDate = new Intl.DateTimeFormat('fr-FR').format(dateObject)

  if (config.viewMode === 'day') {
    labels = labels.map(hour => `${hour.padStart(2, '0')}:00`)
    return `Total par heure - ${labelDate}`
  } else if (config.viewMode === 'year') {
    labels = labels.map(month => monthsLabels[month])
    return `Total par mois - Année ${dateObject.getFullYear()}`
  } else if (config.viewMode === 'month') {
    return `Total par jour - ${monthsLabels[dateObject.getMonth()]} ${dateObject.getFullYear()}`
  } else if (config.viewMode === 'quarter') {
    labels = labels.map(week => `Sem ${week}`)
    return `Total par semaine - Trimestre ${config.currentQuarter}, ${dateObject.getFullYear()}`
  }
}

/**
 * Build chart config from provided totals
 * @param totals The provided totals
 */
const buildChartData = (totals, search) => {
  let labels = Object.keys(totals)
  let data = []

  if (search?.length) {
    data = filterData(labels, totals, search).map(item => item.data || 0)
  } else {
    data = Object.keys(totals).map((key, index) => ({
      time: labels[index],
      data: totals[key].data || totals[key] || 0,
      rawLogs: totals[key].rawLogs || []
    }))
  }

  label.value = setLabel(labels)
  chartData.value = {
    labels,
    datasets: [
      {
        data,
        label: label.value,
        backgroundColor: 'rgba(75, 192, 192, 0.2)',
        borderColor: 'rgba(75, 192, 192, 1)',
        borderWidth: 1
      }
    ]
  }
}

watch(props.config, (newConfig) => {
  chartIsLoaded.value = false
  if (newConfig?.totals) {
    buildChartData(newConfig.totals, newConfig.search || {})
    nextTick(() => {
      chartIsLoaded.value = true
    })
  }
}, { deep: true })
</script>

<style lang="scss">
.z__bar-chart-container {
  height: 30vh;
  width: calc(100% + 4px);
  padding: 0 1px 0 73.5px;
}
</style>
