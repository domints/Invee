<script setup lang="ts">
import App from './App.vue'
import { getUserInfo } from './client';
import { useUserStore } from './stores/user';

const userStore = useUserStore();
setTimeout(async () => {
  var userInfo = await getUserInfo();
  if (userInfo.data) {
    if (userInfo.data.authorized) {
      userStore.login(userInfo.data)
    }
    else {
      userStore.logout();
    }
  }
}, 0);

</script>

<template>
  <App></App>
</template>