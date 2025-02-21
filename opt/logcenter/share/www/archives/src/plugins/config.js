import axios from 'axios'

let config = null
let configPromise = null

export const fetchConfig = async () => {
  if (!configPromise) {
    configPromise = axios.get('./config.json')
      .then(response => {
        config = response.data
        return config
      })
      .catch(error => {
        console.error('Failed to fetch config:', error)
        throw error
      })
  }
  return configPromise
}

export const getConfig = () => config