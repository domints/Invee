<script setup lang="ts">
import { ref, nextTick, onMounted } from 'vue'
import QRCode from 'qrcode'

const loading = ref(true)
const error = ref<string | null>(null)
const token = ref<string | null>(null)
const expiryDate = ref<Date | null>(null)
const qrCanvas = ref<HTMLCanvasElement | null>(null)

function getServerUrl(): string {
  const envUrl = import.meta.env.VITE_API_BASE_URL as string | undefined
  if (envUrl && envUrl !== '/') return envUrl.replace(/\/$/, '')
  return window.location.origin
}

function parseExpiry(jwt: string): Date | null {
  try {
    const parts = jwt.split('.')
    if (parts.length !== 3) return null
    const payload = atob(parts[1].replace(/-/g, '+').replace(/_/g, '/'))
    const data = JSON.parse(payload)
    if (data.exp) return new Date(data.exp * 1000)
  } catch {}
  return null
}

function daysUntil(date: Date): number {
  return Math.ceil((date.getTime() - Date.now()) / (1000 * 60 * 60 * 24))
}

async function renderQr(jwt: string) {
  await nextTick()
  if (!qrCanvas.value) return
  const payload = JSON.stringify({ url: getServerUrl(), token: jwt })
  await QRCode.toCanvas(qrCanvas.value, payload, { width: 280, margin: 2 })
}

async function fetchToken() {
  loading.value = true
  error.value = null
  token.value = null
  expiryDate.value = null

  try {
    const response = await fetch(getServerUrl() + '/api/auth/mobile-token', {
      credentials: 'include'
    })
    if (response.status === 401) {
      error.value = 'You must be logged in to generate a device token.'
      return
    }
    if (!response.ok) {
      error.value = `Server error: ${response.status}`
      return
    }
    const data = await response.json()
    const jwt = data.token as string
    token.value = jwt
    expiryDate.value = parseExpiry(jwt)
    loading.value = false
    await renderQr(jwt)
  } catch {
    error.value = 'Failed to connect to server.'
  } finally {
    loading.value = false
  }
}

async function copyToken() {
  if (token.value) await navigator.clipboard.writeText(token.value)
}

onMounted(fetchToken)
</script>

<template>
  <div class="mobile-setup">
    <h1>Mobile Device Setup</h1>
    <p class="subtitle">
      Scan this QR code with the Invee Windows Mobile app on your device to connect it.
      The token is valid for 90 days — generate a new one before it expires.
    </p>

    <div v-if="loading" class="state-box">
      <el-skeleton :rows="5" animated />
    </div>

    <div v-else-if="error" class="state-box">
      <el-alert :title="error" type="error" :closable="false" show-icon />
      <el-button @click="fetchToken" style="margin-top: 12px">Retry</el-button>
    </div>

    <template v-else>
      <div class="qr-section">
        <canvas ref="qrCanvas" class="qr-canvas" />

        <div class="token-meta" v-if="expiryDate">
          <el-tag
            v-if="daysUntil(expiryDate) <= 0"
            type="danger"
          >
            Expired on {{ expiryDate.toLocaleDateString() }}
          </el-tag>
          <el-tag
            v-else-if="daysUntil(expiryDate) <= 7"
            type="warning"
          >
            Expires in {{ daysUntil(expiryDate) }} day{{ daysUntil(expiryDate) === 1 ? '' : 's' }}
            ({{ expiryDate.toLocaleDateString() }})
          </el-tag>
          <el-tag v-else type="success">
            Valid until {{ expiryDate.toLocaleDateString() }}
          </el-tag>
        </div>

        <el-button type="primary" @click="fetchToken">Refresh Token</el-button>
      </div>

      <div class="manual-section">
        <h3>Manual entry</h3>
        <p>If you cannot scan the QR code, enter these values in the app setup screen:</p>

        <div class="field-row">
          <span class="field-label">Server URL</span>
          <code>{{ getServerUrl() }}</code>
        </div>

        <div class="field-row">
          <span class="field-label">Token</span>
          <code class="token-text">{{ token }}</code>
          <el-button size="small" @click="copyToken">Copy</el-button>
        </div>
      </div>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.mobile-setup {
  max-width: 520px;
  margin: 0 auto;
  padding: 1.5rem 1rem;

  h1 {
    margin-bottom: 0.25rem;
  }

  .subtitle {
    color: var(--el-text-color-secondary);
    margin-bottom: 1.5rem;
    line-height: 1.5;
  }

  .state-box {
    padding: 1rem 0;
  }

  .qr-section {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    margin-bottom: 2rem;

    .qr-canvas {
      border-radius: 8px;
      border: 1px solid var(--el-border-color);
    }

    .token-meta {
      text-align: center;
    }
  }

  .manual-section {
    border-top: 1px solid var(--el-border-color);
    padding-top: 1.25rem;

    h3 {
      margin: 0 0 0.4rem;
    }

    p {
      color: var(--el-text-color-secondary);
      font-size: 0.9rem;
      margin-bottom: 0.75rem;
    }

    .field-row {
      display: flex;
      align-items: flex-start;
      gap: 0.5rem;
      margin-bottom: 0.6rem;
      flex-wrap: wrap;

      .field-label {
        font-weight: 600;
        min-width: 90px;
        flex-shrink: 0;
        padding-top: 2px;
      }

      code {
        font-family: monospace;
        background: var(--el-fill-color);
        padding: 2px 6px;
        border-radius: 4px;
        word-break: break-all;
        flex: 1;
        font-size: 0.8rem;
        min-width: 0;

        &.token-text {
          overflow: hidden;
          display: -webkit-box;
          -webkit-line-clamp: 3;
          -webkit-box-orient: vertical;
        }
      }
    }
  }
}
</style>
