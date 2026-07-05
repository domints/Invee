import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import StorageDetail from '@/views/StorageDetail.vue'
import AdminView from '@/views/AdminView.vue'
import CategoryDetail from '@/views/CategoryDetail.vue'
import LoginView from '@/views/LoginView.vue'
import ItemEdit from '@/views/ItemEdit.vue'
import ItemDetail from '@/views/ItemDetail.vue'
import { useUserStore } from '@/stores/user'

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
    },
    {
      path: '/login',
      name: 'login',
      component: LoginView
    },
    {
      path: '/item/:id',
      name: 'item',
      component: ItemDetail,
    },
    {
      path: '/item/:id/edit',
      name: 'item-edit',
      component: ItemEdit,
      meta: { requiresAuth: true }
    }
  ],
})

router.beforeEach((to) => {
  const userStore = useUserStore()
  if (to.meta.requiresAuth && !userStore.loggedIn) {
    return { name: 'login' }
  }
})

export default router
