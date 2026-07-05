<script setup lang="ts">
import { getLoggedInUserInfo } from '@/client';
import { useUserStore } from '@/stores/user';

const userStore = useUserStore();

let userResponse = await getLoggedInUserInfo();
if (userResponse.data) {
  userStore.login(userResponse.data);
}
else {
  userStore.logout();
}
</script>
<template>
  <div class="">
    <h1>Hi {{ userStore.user?.name }}!</h1>
    You can go back <RouterLink to="/home">home</RouterLink> now.
  </div>
</template>

<style>
@media (min-width: 1024px) {
  .about {
    min-height: 100vh;
    display: flex;
    align-items: center;
  }
}
</style>
