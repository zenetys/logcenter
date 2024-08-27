import '@mdi/font/css/materialdesignicons.css' // Ensure you are using css-loader
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'

const zenetysLightTheme = {
  dark: false,
  colors: {
    primary: '#17B8CE',
    'primary-darken-1': '#0F6E84',
    'primary-super-light': '#e7f7fa'
  }
}

export default createVuetify({
  icons: {
    defaultSet: 'mdi' // This is already the default value - only for display purposes
  },
  theme: {
    defaultTheme: 'zenetysLightTheme',
    themes: {
      zenetysLightTheme
    }
  },
  components,
  directives
})
