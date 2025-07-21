import axios from 'axios'
import { ref, reactive } from 'vue'

let config = null
let configPromise = null
// Créer un objet réactif pour les alias
const aliases = reactive({})

export const fetchConfig = async () => {
  if (!configPromise) {
    configPromise = axios.get('./config.json')
      .then(response => {
        config = response.data
        
        // Initialiser les alias réactifs
        if (config.aliases) {
          Object.keys(config.aliases).forEach(key => {
            aliases[key] = config.aliases[key]
          })
        }
        
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

/**
 * Récupère les alias depuis la configuration
 * @returns {Object} Objet contenant les alias IP -> nom, ou objet vide si pas d'alias
 */
export const getAliases = () => {
  if (!config) {
    console.warn('Configuration not loaded yet')
    return aliases
  }
  return aliases
}

/**
 * Récupère l'alias pour une adresse IP donnée
 * @param {string} ip - L'adresse IP
 * @returns {string} L'alias si trouvé, sinon l'IP originale
 */
export const getAliasForIP = (ip) => {
  const aliases = getAliases()
  return aliases[ip] || ip
}

/**
 * Met à jour un alias pour une adresse IP
 * @param {string} ip - L'adresse IP
 * @param {string} alias - Le nouvel alias
 * @returns {Promise} Promise de la requête de mise à jour
 */
export const updateAlias = async (ip, alias) => {
  try {
    const response = await axios.get('api/config', {
      params: {
        mode: 'aliases',
        ipaddr: ip,
        alias: alias
      }
    })
    
    // Mettre à jour le cache local de manière réactive
    aliases[ip] = alias
    
    // Mettre à jour aussi config.aliases pour compatibilité
    if (config && config.aliases) {
      config.aliases[ip] = alias
    }
    
    return response.data
  } catch (error) {
    console.error('Failed to update alias:', error)
    throw error
  }
}

/**
 * Supprime un alias pour une adresse IP
 * @param {string} ip - L'adresse IP dont l'alias doit être supprimé
 * @returns {Promise} Promise de la requête de suppression
 */
export const deleteAlias = async (ip) => {
  try {
    const response = await axios.get('api/config', {
      params: {
        mode: 'aliases',
        ipaddr: ip,
        alias: '' // Un alias vide signifie suppression
      }
    })
    
    // Mettre à jour le cache local de manière réactive
    if (ip in aliases) {
      delete aliases[ip]
    }
    
    // Mettre à jour aussi config.aliases pour compatibilité
    if (config && config.aliases && ip in config.aliases) {
      delete config.aliases[ip]
    }
    
    return response.data
  } catch (error) {
    console.error('Failed to delete alias:', error)
    throw error
  }
}
