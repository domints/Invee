import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import StorageDetail from '@/views/StorageDetail.vue'
import AdminView from '@/views/AdminView.vue'
import CategoryDetail from '@/views/CategoryDetail.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/about',
      name: 'about',
      // route level code-splitting
      // this generates a separate chunk (About.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import('../views/AboutView.vue'),
    },
    {
      path: '/category/:id',
      name: 'category',
      component: CategoryDetail
    },
    {
      path: '/storage/:id',
      name: 'storage',
      component: StorageDetail
    },
    {
      path: '/admin',
      name: 'admin',
      component: AdminView
    }
  ],
})

export default router
