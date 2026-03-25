import 'element-plus/theme-chalk/src/dark/css-vars.scss'
import './assets/main.css'

import { createApp } from 'vue'
import AppContainer from './AppContainer.vue'
import router from './router'
import configureApiClient from './configureApiClient'

configureApiClient();
const app = createApp(AppContainer)

app.use(router)

app.mount('#app')
