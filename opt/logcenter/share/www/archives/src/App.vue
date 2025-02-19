<template>
  <header>
    <div class="wrapper mt-2">
      <img src="/logo.png" class="logo mr-4" alt="ZENETYS" />
      <nav>
        <RouterLink to="/"></RouterLink>
      </nav>
      <div class="header-buttons">
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
import { ref, onMounted } from 'vue'
import axios from 'axios'

const router = useRouter()
const user = ref('')
const hasKibana = ref(false)

const navigateTo = (path, tab = null) => {
  if (tab === true) window.open(path, '_blank')
  else if (tab === false) window.location.href = path
  else router.push(path)
}

const fetchConfig = async () => {
  try {
    const response = await axios.get('./config.json')
    user.value = response.data.user_id
    hasKibana.value = response.data.has_kibana
  } catch (error) {
    console.error('Failed to fetch config:', error)
  }
}

onMounted(() => {
  fetchConfig()
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
  min-width: 10px !important;
  padding: 0 10px !important;
}
</style>
