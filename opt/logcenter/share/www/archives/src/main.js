import './assets/main.css'

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'

// Vuetify
import 'vuetify/styles'
// Overridden Vuetify constructor with a custom theme
import vuetify from './plugins/vuetify'

const app = createApp(App).use(vuetify)

app.use(router)

app.mount('#app')
