<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
import { useUserStore } from './stores/user';
import { getUserInfo } from './client';

const userStore = useUserStore();


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
        <span>Hi {{ userStore.user?.username }}!</span>
      </template>
      <template v-else>
        <RouterLink to="/login">Login</RouterLink>
      </template>
    </nav>
  </header>

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
  }
}

main {
  max-width: 75rem;
  margin: 0 auto;
  padding: 1rem;
}
</style>
