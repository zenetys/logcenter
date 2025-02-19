<template>
  <div class="mt-3 z__bar-chart-container container mb-5">
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
    <Bar id="z__bar-chart" v-if="chartIsLoaded" :data="chartData" :options="options" />
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import {
  getHumanReadableByteSize,
  monthsLabels,
  formatAndDownloadLogs,
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
    if (!elements || elements.length <= 0) {
      return
    } else {
      const clickedItem = elements[0]
      const date = new Date(props.config.date)
      const selectedTotal = props.config.totals[clickedItem.index]

      if (props.config.viewMode === 'day' && selectedTotal.rawLogs && selectedTotal.rawLogs[0]) {
        // Download raw logs for the clicked hour
        downloadDialog.value = true
        watch(downloadIsConfirmed, async (value) => {
          if (value) {
            const clickedDate = selectedTotal.rawLogs[0].dateObject.getTime()
            formatAndDownloadLogs(selectedTotal.rawLogs, clickedDate)
            downloadIsConfirmed.value = false
          }
        })
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
const downloadIsConfirmed = ref(false)
const label = ref('Total par heure')

// Component Events
const emit = defineEmits(['change-date', 'change-mode'])

/**
 * Confirm the download of the logs
 * Triggered by the dialog
 */
const confirmDownload = () => {
  downloadIsConfirmed.value = true
  downloadDialog.value = false
}

/**
 * Build chart config from provided totals
 * @param totals The provided totals
 */
const buildChartData = (totals) => {
  let labels = Object.keys(totals)
  let data = []
  const dateObject = new Date(config.date)

  if (config.viewMode === 'day') {
    const labelDate = new Intl.DateTimeFormat('fr-FR').format(dateObject)
    labels = labels.map((hour) => (parseInt(hour) < 10 ? `0${hour}:00` : `${hour}:00`))
    label.value = `Total par heure - ${labelDate}`
    // Adding raw logs data & time indexes to chart items
    data = Object.keys(totals).map((key) => {
      return {
        time: labels[key],
        data: totals[key].data || totals[key],
        rawLogs: totals[key].rawLogs
      }
    })
  } else if (config.viewMode === 'year') {
    labels = labels.map((month) => monthsLabels[month])
    const labelDate = dateObject.getUTCFullYear()
    label.value = `Total par mois - Année ${labelDate}`
    data = Object.values(totals)
  } else if (config.viewMode === 'month') {
    const labelDate = `${monthsLabels[dateObject.getUTCMonth()]} ${dateObject.getUTCFullYear()}`
    label.value = 'Total par jour - ' + labelDate
    data = Object.values(totals)
  } else if (config.viewMode === 'quarter') {
    const labelDate = `Trimestre ${config.currentQuarter}, ${dateObject.getUTCFullYear()}`
    labels = labels.map((week) => `Sem ${week}`)
    label.value = 'Total par semaine - ' + labelDate
    data = Object.values(totals)
  }

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
    buildChartData(newConfig.totals)
    chartIsLoaded.value = true
  }
})
</script>

<style lang="scss">
.z__bar-chart-container {
  height: 30vh;
  padding-left: 44px;
}
</style>
