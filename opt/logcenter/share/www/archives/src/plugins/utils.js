/**
 * Build a list of unique hosts from an array of logs
 * @param {Array} logs The list of logs to get hosts from
 * @returns {Array} The list of unique hosts
 */
export const getUniqueHosts = (logs) => {
  return [...new Set(logs.map((log) => log.hostname))]
}

/**
 * Get the most recent date in an array of logs
 * @param {Array} logs The list of logs to get the date from
 * @returns {Date} The most recent date
 */
export const getMostRecentLogDate = (logs) => {
  return logs
    .filter((log) => log.dateObject)
    .reduce((acc, log) => {
      if (log.dateObject.getTime() > acc) {
        return log.dateObject.getTime()
      }
      return acc
    }, new Date(0).getTime())
}

/**
 * Order a list of logs by their unique hostname
 * @param {Array} logs The unordered array of logs
 * @param {Array} hosts The list of unique hosts to order logs by
 * @returns {Object} The logs ordered by host
 */
export const getLogsByHost = (logs, hosts) => {
  return hosts.reduce((acc, host) => {
    acc[host] = logs.filter((log) => log.hostname === host)
    return acc
  }, {})
}

/**
 * Get all logs from a given period of time
 * @param {Array} logs The list of logs
 * @param {Date} start The start of the time period to filter
 * @param {Date} end The end of the time period to filter
 * @returns {Array} The list of logs from the provided period
 */
export const getLogsFromPeriod = (logs, start, end) => {
  return logs.filter((log) => {
    return log.dateObject && log.dateObject.getTime() >= start && log.dateObject.getTime() <= end
  })
}

/**
 * Get the week number of a given date
 * @param {Date} d The date to get the week from
 * @returns {Number} The week number of the provided date
 */
export const getWeekNumberFromDate = (d) => {
  // Deep cloning the provided date object to prevent its modification
  const dateTime = d.getTime()
  const date = new Date(dateTime)

  const dayNum = date.getDay() || 7
  // Here, the "day + 4" is because the first ISO week of a year is the week of the first Thursday of the year (ISO 8601 rule)
  date.setDate(date.getDate() + 4 - dayNum)
  const yearStart = new Date(date.getFullYear(), 0, 1)
  return Math.ceil(((date - yearStart) / 86400000 + 1) / 7)
}

/**
 * Format a raw byte size into a human readable format
 * @param {*} bytes the raw byte size to format
 * @returns {Object} The formatted byte size, with separate 'value', 'unit' and 'toString' properties
 * @source Inspired by https://github.com/sindresorhus/pretty-bytes
 */
export const getHumanReadableByteSize = (bytes, decimals = 0) => {
  if (typeof bytes !== 'number' || isNaN(bytes)) {
    return {
      value: 0,
      unit: '',
      toString: () => '0'
    }
  }

  if (bytes === 0) {
    return {
      value: 0,
      unit: '',
      toString: () => '0'
    }
  }

  let exponent
  let unit
  const units = ['o', 'ko', 'Mo', 'Go', 'To', 'Po', 'Eo', 'Zo', 'Yo']

  exponent = Math.min(Math.floor(Math.log(bytes) / Math.log(1000)), units.length - 1)
  bytes = (bytes / Math.pow(1000, exponent)).toFixed(decimals) * 1
  unit = units[exponent]

  return {
    value: bytes,
    unit: ' ' + unit,
    toString: () => {
      return `${bytes}${unit}`
    }
  }
}

/**
 * Correspondance table for month numbers and their respective short labels
 * @keys {Number} The month number, from 1 to 12
 * @values {String} The respective month's short label
 */
export const monthsLabels = {
  0: 'Jan',
  1: 'Fév',
  2: 'Mar',
  3: 'Avr',
  4: 'Mai',
  5: 'Juin',
  6: 'Juil',
  7: 'Aoû',
  8: 'Sep',
  9: 'Oct',
  10: 'Nov',
  11: 'Déc'
}

/**
 * Format an array of logs as a JSON file and download it
 * @param {array} logs The list of logs to format and download
 * @param {date} selectedDate The date of the logs to format and download
 * @param {string} hostname The hostname of the logs to format and download
 */
export const formatAndDownloadLogs = (axios, logs, selectedDate, hostname = null) => {
    const postData = JSON.stringify(logs);
    console.log('formatAndDownloadLogs', postData);
    axios.post(
      './api/get-archives',
      postData,
      {
        headers: { 'content-type': 'application/json' },
        responseType: 'blob',
      }
    )
      .then((response) => {
        // Try to get extract a filename from the content-disposition response
        // header, fallback to download.dat.
        let filename = undefined;
        if (response.headers['content-disposition']) {
          let cap = /; filename="([^"]+)"/.exec(response.headers['content-disposition']);
          if (cap)
            filename = cap[1];
        }
        if (!filename)
          filename = 'download.dat';
        // Offer to download
        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', filename)
        link.click()
        window.URL.revokeObjectURL(url)
      })
      .catch((error) => {
        console.error('Failed to download logs:', error)
      });
}

/**
 * Change a date from a new week number.
 * Using ISO 8601 weeks, the first week of the year is the week containing the first Thursday of the year.
 * @param {Date} currentDate The currently selected date to change
 * @param {number} weekNumber The number of the ISO week to change the date to
 * @returns {number} The timestamp of the adjusted date : the start of the given week number
 */
export const changeDateFromWeekNumber = (currentDate, weekNumber) => {
  // Deep cloning current date
  const d = new Date(currentDate.getTime())
  const year = d.getFullYear()
  const simple = new Date(year, 0, 1 + (weekNumber - 1) * 7)
  const dayOfWeek = simple.getDay()
  const isoWeekStart = simple

  // Get the Monday past, and add a week if the day was
  // Friday, Saturday or Sunday.
  isoWeekStart.setDate(simple.getDate() - dayOfWeek + 1)

  if (dayOfWeek > 4) {
    isoWeekStart.setDate(isoWeekStart.getDate() + 7)
  }
  return isoWeekStart.getTime()
}
