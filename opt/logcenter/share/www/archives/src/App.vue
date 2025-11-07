<template>
  <header>
    <div class="wrapper mt-2">
      <a href="https://www.zenetys.com/" target="_blank">
        <picture>
          <source srcset="/zenetys-light.png" media="(prefers-color-scheme: dark)" />
          <img src="/zenetys.png" class="logo mr-4" alt="ZENETYS" />
        </picture>
      </a>
      <nav>
        <RouterLink to="/"></RouterLink>
      </nav>
      <div class="header-buttons">
        <v-btn v-if="archivesUsage" :title="getArchivesUsageTooltip()" class="usage-btn text-none">
          <v-icon size="small" class="mr-1">mdi-harddisk</v-icon>
          <span class="usage-text">{{ formatUsage(archivesUsage.used, archivesUsage.max) }}</span>
        </v-btn>
        <v-btn v-if="elasticUsage" :title="getElasticUsageTooltip()" class="usage-btn text-none">
          <v-icon size="small" class="mr-1">mdi-database</v-icon>
          <span class="usage-text">{{ formatUsage(elasticUsage.used, elasticUsage.max) }}</span>
        </v-btn>
        <v-btn v-if="user" title="Utilisateur" class="text-none">
          {{ user }}
        </v-btn>
        <v-btn v-if="hasKibana" title="Kibana" @click="navigateTo('/kibana', true)">
          <v-icon>
            <img src="/kibana.svg" width="24" height="24" alt="Kibana" />
          </v-icon>
        </v-btn>
        <v-btn title="Se déconnecter" @click="navigateTo('/logout', false)">
          <v-icon>
            <img src="/logout.svg" width="18" height="18" alt="Logout" />
          </v-icon>
        </v-btn>
      </div>
    </div>
  </header>

  <RouterView />
</template>

<script setup>
import { RouterLink, RouterView } from 'vue-router'
import { useRouter } from 'vue-router'
import { ref, onMounted, provide } from 'vue'
import { fetchConfig, getConfig } from './plugins/config.js'
import { getHumanReadableByteSize } from './plugins/utils.js'

const router = useRouter()
const user = ref('')
const hasKibana = ref(false)
const archivesUsage = ref(null)
const elasticUsage = ref(null)

// Provide elasticUsage to child components
provide('elasticUsage', elasticUsage)

const navigateTo = (path, tab = null) => {
  if (tab === true) window.open(path, '_blank')
  else if (tab === false) window.location.href = path
  else router.push(path)
}

const formatUsage = (used, max) => {
  const usedHuman = getHumanReadableByteSize(used, 1)
  const maxHuman = getHumanReadableByteSize(max, 1)
  return `${usedHuman.toString()} / ${maxHuman.toString()}`
}

const getArchivesUsageTooltip = () => {
  if (!archivesUsage.value) return ''
  const percent = ((archivesUsage.value.used / archivesUsage.value.max) * 100).toFixed(1)
  return `Archives: ${percent}% utilisé`
}

const getElasticUsageTooltip = () => {
  if (!elasticUsage.value) return ''
  const percent = ((elasticUsage.value.used / elasticUsage.value.max) * 100).toFixed(1)
  return `Elasticsearch: ${percent}% utilisé`
}

onMounted(async () => {
  await fetchConfig()
  const config = getConfig()
  if (config) {
    user.value = config.user_id
    hasKibana.value = config.has_kibana
    archivesUsage.value = config.archives_usage
    elasticUsage.value = config.elastic_usage
  }
})
</script>

<style>
.logo {
  width: 160px;
  height: auto;
}

header .wrapper {
  display: flex;
  place-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
}

.header-buttons {
  display: flex;
  gap: 10px;
}
.header-buttons .v-btn  {
  background: var(--color-background-mute) !important;
  color: var(--color-heading) !important;
  min-width: 10px !important;
  padding: 0 10px !important;
}
.header-buttons .usage-btn {
  font-size: 12px;
}
.header-buttons .usage-text {
  font-weight: 500;
}
</style>
