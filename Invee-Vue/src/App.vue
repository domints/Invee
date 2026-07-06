<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
import { ref, nextTick } from 'vue'
import QRCode from 'qrcode'
import { useUserStore } from './stores/user';

const userStore = useUserStore();

const qrDialogVisible = ref(false)
const qrCanvas = ref<HTMLCanvasElement | null>(null)

function getServerUrl(): string {
  const envUrl = import.meta.env.VITE_API_BASE_URL as string | undefined
  if (envUrl && envUrl !== '/') return envUrl.replace(/\/$/, '')
  return window.location.origin
}

async function openQrDialog() {
  qrDialogVisible.value = true
  await nextTick()
  const canvas = qrCanvas.value
  if (!canvas) return
  const payload = JSON.stringify({ url: getServerUrl() })
  await QRCode.toCanvas(canvas, payload, { width: 260, margin: 2 })
}
</script>

<template>
  <header>
    <div class="logo">
      <RouterLink to="/">
        <img alt="Vue logo" class="logo__img" src="@/assets/logo.svg" height="100%" />
        <span class="title">Invee</span>
      </RouterLink>
    </div>
    <div class="spacer">
    </div>
    <nav>
      <RouterLink to="/">Home</RouterLink>
      <template v-if="userStore.loggedIn">
        <RouterLink to="/admin">Administration</RouterLink>
        <el-tooltip content="Connect mobile app" placement="bottom">
          <button class="qr-btn" @click="openQrDialog" aria-label="Connect mobile app">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor">
              <path d="M3 11h8V3H3v8zm2-6h4v4H5V5zM3 21h8v-8H3v8zm2-6h4v4H5v-4zM13 3v8h8V3h-8zm6 6h-4V5h4v4zM13 13h2v2h-2zM15 15h2v2h-2zM13 17h2v2h-2zM17 13h2v2h-2zM19 15h2v2h-2zM17 17h2v2h-2zM19 19h2v2h-2zM15 19h2v2h-2zM13 21h2v-2h-2z"/>
            </svg>
          </button>
        </el-tooltip>
        <span>Hi {{ userStore.user?.username }}!</span>
      </template>
      <template v-else>
        <RouterLink to="/login">Login</RouterLink>
      </template>
    </nav>
  </header>

  <el-dialog v-model="qrDialogVisible" title="Connect Mobile App" width="320px" align-center>
    <div class="qr-dialog-body">
      <canvas ref="qrCanvas" />
      <p class="qr-hint">Scan this with the Invee mobile app to connect.</p>
    </div>
  </el-dialog>

  <main>
    <RouterView v-slot="{ Component }">
      <template v-if="Component">
        <Suspense>
          <!-- main content -->
          <component :is="Component"></component>

          <!-- loading state -->
          <template #fallback>
            Loading...
          </template>
        </Suspense>
      </template>
    </RouterView>
  </main>
</template>

<style lang="scss" scoped>
header {
  display: flex;
  padding-top: 0.5rem;
  padding-bottom: 0.5rem;
  height: 3rem;

  .logo {
    height: 100%;
    margin-left: 2rem;

    a {
      display: flex;
      height: 100%;
      align-items: center;
      padding-right: 0.5rem;

      .title {
        display: inline-block;
        margin-left: 0.8rem;
        font-size: 1.2rem;
        line-height: 1.2rem;
        font-weight: 600;
      }
    }
  }

  .spacer {
    flex-grow: 1;
  }

  nav {
    height: 100%;
    display: flex;
    align-items: center;

    a {
      height: 100%;
      padding-left: 2rem;
      padding-right: 2rem;
    }

    span {
      height: 100%;
      padding-left: 2rem;
      padding-right: 2rem;
      padding-top: 3px;
      padding-left: 3px;
    }

    .qr-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100%;
      padding: 0 0.75rem;
      background: none;
      border: none;
      cursor: pointer;
      color: inherit;
      opacity: 0.75;
      transition: opacity 0.15s;

      &:hover {
        opacity: 1;
      }
    }
  }
}

.qr-dialog-body {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;

  canvas {
    border-radius: 8px;
  }

  .qr-hint {
    margin: 0;
    font-size: 0.85rem;
    color: var(--el-text-color-secondary);
    text-align: center;
  }
}

main {
  max-width: 75rem;
  margin: 0 auto;
  padding: 1rem;
}
</style>
