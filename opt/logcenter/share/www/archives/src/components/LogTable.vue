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
              <!-- Edit / display mode -->
              <div v-if="editingHostname === item.name" class="hostname-edit-container">
                <div class="hostname-input-wrapper">
                  <input
                    v-model="editingAlias"
                    :disabled="isUpdatingAlias"
                    @keydown="handleKeyPress"
                    @blur="saveAlias"
                    placeholder="Alias (Enter/Esc)"
                    class="hostname-edit-field"
                    :class="{ 'error': showAliasError }"
                  />
                  <button 
                    type="button"
                    class="hostname-delete-button"
                    title="Supprimer l'alias"
                    @mousedown.prevent="deleteAliasAction"
                    :disabled="isUpdatingAlias"
                  >
                    ×
                  </button>
                </div>
                <div v-if="showAliasError" class="hostname-error-message">
                  {{ aliasError }}
                </div>
              </div>
              <!-- Display mode -->
              <span 
                v-else
                :title="getHostnameTooltip(item.name) + ' (Double-click to edit)'"
                @dblclick="(event) => startEditing(item.name, event)"
                class="hostname-display"
              >
                {{ getDisplayName(item.name) }}
              </span>
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
import {
  getHumanReadableByteSize,
  monthsLabels,
  downloadLogs,
  changeDateFromWeekNumber
} from '@/plugins/utils'
import { getAliasForIP, updateAlias, deleteAlias } from '@/plugins/config.js'

// Props
const props = defineProps(['config', 'error'])

const timeValues = props.config.timeValues

// Data
const tableData = ref([])
const downloadDialog = ref(false)
const downloadPendingData = ref(null)

// States for alias editing
const editingHostname = ref(null)
const editingAlias = ref('')
const isUpdatingAlias = ref(false)
const aliasError = ref('')
const showAliasError = ref(false)

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
 * Obtient le nom d'affichage pour un hostname (alias si disponible)
 * @param {string} hostname - Le hostname original (IP)
 * @returns {string} L'alias si disponible, sinon le hostname original
 */
const getDisplayName = (hostname) => {
  return getAliasForIP(hostname)
}

/**
 * Obtient le tooltip pour un hostname (IP originale si alias utilisé)
 * @param {string} hostname - Le hostname original (IP)
 * @returns {string} L'IP originale si un alias est utilisé, sinon le hostname
 */
const getHostnameTooltip = (hostname) => {
  const alias = getAliasForIP(hostname)
  return alias !== hostname ? `IP: ${hostname}` : hostname
}

/**
 * Start editing an alias
 * @param {string} hostname - The original hostname (IP)
 * @param {Event} event - The double-click event
 */
const startEditing = (hostname, event) => {
  // Set the current hostname and alias being edited
  editingHostname.value = hostname
  editingAlias.value = getAliasForIP(hostname)
  
  // Focus is handled automatically by Vue in the next render cycle
  setTimeout(() => {
    const input = document.querySelector('.hostname-edit-field')
    if (input) {
      input.focus()
      input.select()
    }
  }, 20)
}

/**
 * Cancel current editing
 */
const cancelEditing = () => {
  editingHostname.value = null
  editingAlias.value = ''
  aliasError.value = ''
  showAliasError.value = false
}

/**
 * Check if an alias is valid
 * @param {string} alias - The alias to check
 * @returns {boolean} - True if the alias is valid
 */
const isAliasValid = (alias) => {
  // An empty alias is valid (used for deletion)
  if (!alias || alias.trim() === '') return true
  // Check if the alias contains only valid characters
  // Alphanumeric, hyphens, underscores, periods
  return /^[a-zA-Z0-9\-_\.]+$/.test(alias)
}

/**
 * Delete the current alias
 */
const deleteAliasAction = async () => {
  if (!editingHostname.value || isUpdatingAlias.value) return
  
  try {
    isUpdatingAlias.value = true
    aliasError.value = ''
    showAliasError.value = false
    
    // Appel explicite à la fonction de suppression d'alias
    await deleteAlias(editingHostname.value)
    
    // Mise à jour de l'interface
    editingAlias.value = ''
    cancelEditing()
  } catch (error) {
    console.error('Error deleting alias:', error)
    aliasError.value = 'Delete error'
    showAliasError.value = true
    
    // Display error for a moment then hide it
    setTimeout(() => {
      showAliasError.value = false
    }, 3000)
  } finally {
    isUpdatingAlias.value = false
  }
}

/**
 * Save the edited alias
 */
const saveAlias = async () => {
  // Check if editing is active
  if (!editingHostname.value || isUpdatingAlias.value) return
  
  // Check if the value has changed
  const currentAlias = getAliasForIP(editingHostname.value)
  if (currentAlias === editingAlias.value) {
    cancelEditing()
    return
  }
  
  // Check if the alias is valid
  if (!isAliasValid(editingAlias.value)) {
    aliasError.value = 'Invalid name. Use only letters, numbers, - _ .'
    showAliasError.value = true
    
    // Display error for a moment then hide it
    setTimeout(() => {
      showAliasError.value = false
    }, 3000)
    
    return
  }
  
  // If the alias is empty, show a confirmation message
  if (editingAlias.value.trim() === '') {
    // Trim the alias to ensure it's truly empty
    editingAlias.value = ''
  }
  
  try {
    aliasError.value = ''
    showAliasError.value = false
    isUpdatingAlias.value = true
    await updateAlias(editingHostname.value, editingAlias.value)
    cancelEditing()
  } catch (error) {
    console.error('Error updating alias:', error)
    aliasError.value = 'Save error'
    showAliasError.value = true
    
    // Display error for a moment then hide it
    setTimeout(() => {
      showAliasError.value = false
    }, 3000)
  } finally {
    isUpdatingAlias.value = false
  }
}

/**
 * Handle special keys
 * @param {KeyboardEvent} event 
 */
const handleKeyPress = (event) => {
  if (event.key === 'Enter') {
    event.preventDefault()
    saveAlias()
  } else if (event.key === 'Escape') {
    event.preventDefault()
    cancelEditing()
  }
}


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
    downloadPendingData.value = cellContent.logs;
  } else if (props.config.viewMode === 'quarter') {
    const adjustedDate = changeDateFromWeekNumber(date, Number(header.key))
    emit('change-date', adjustedDate)
    emit('change-mode', 'month')
  } else if (props.config.viewMode === 'month') {
    date.setDate(header.key)
    emit('change-date', date.getTime())
    emit('change-mode', 'day')
  } else if (props.config.viewMode === 'year') {
    date.setMonth(header.key)
    emit('change-date', date.getTime())
    emit('change-mode', 'month')
  }
}

/**
 * Confirm the download of the logs
 * Triggered by the dialog
 */
const confirmDownload = () => {
  if (downloadPendingData.value) {
    downloadLogs(downloadPendingData.value)
    downloadPendingData.value = null;
  }
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

<style>
.v-table {
  border-radius: 4px !important;
  font-size: 12px !important;
  width: 100% !important;
  min-height: 400px;
  max-height: 450px;
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
      min-width: 32px;
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
  }

  &:nth-child(1) {
    width: 150px;
    min-width: 150px;
    padding: 0 0 0 8px !important;
    background: transparent;
    overflow-x: hidden;
    text-overflow: ellipsis;
    font-weight: bold;
  }

  &.mode__day {
    max-width: 39px;
    min-width: 39px;
  }

  &.mode__month {
    min-width: 32px;
    max-width: 32px;
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

@media (max-width: 1400px) {
.v-data-table__tr td {
  &:nth-child(1) {
    width: 100px;
    min-width: 100px;
  }
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

/* Styles pour l'édition des hostnames */
.hostname-display {
  cursor: pointer;
  transition: background-color 0.2s ease;
  padding: 2px 4px;
  border-radius: 4px;
}

.hostname-display:hover {
  background-color: rgba(var(--v-theme-primary), 0.1);
}

/* Container for editing with error message */
.hostname-edit-container {
  position: relative;
  display: inline-block;
}

.hostname-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

/* Simple style for hostname edit field */
.hostname-edit-field {
  /* Dimensions and spacing */
  width: 100%;
  max-width: 150px;
  height: 24px;
  padding: 0 4px;
  margin: 0;
  box-sizing: border-box;
  padding-right: 24px; /* Make room for the delete button */
  
  /* Appearance */
  border: 1px solid #ccc;
  border-radius: 3px;
  font-size: 12px;
  font-family: inherit;
}

/* Delete button style */
.hostname-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.hostname-edit-field {
  width: 100%;
  padding-right: 24px; /* Espace pour le bouton de suppression */
}

.hostname-delete-button {
  position: absolute;
  right: 0;
  top: 0;
  height: 100%;
  width: 24px;
  padding: 0;
  margin: 0;
  border: none;
  background: transparent;
  font-size: 18px;
  line-height: 1;
  color: #888;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.hostname-delete-button:hover {
  color: #f44336;
}

.hostname-delete-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Focus state */
.hostname-edit-field:focus {
  outline: none;
  border-color: #888;
}

/* Error state */
.hostname-edit-field.error {
  border-color: #f44336;
}

/* Placeholder */
.hostname-edit-field::placeholder {
  font-size: 10px;
  opacity: 0.7;
}

/* Error message */
.hostname-error-message {
  position: absolute;
  top: 100%;
  left: 0;
  width: auto;
  min-width: 150px;
  max-width: 250px;
  padding: 4px 8px;
  margin-top: 2px;
  background-color: #f44336;
  color: white;
  font-size: 11px;
  border-radius: 2px;
  z-index: 100;
  white-space: nowrap;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
}
</style>
