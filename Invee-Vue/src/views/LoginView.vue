<script setup lang="ts">
import { getUserInfo } from '@/client';
import { useUserStore } from '@/stores/user';

const userStore = useUserStore();

let userResponse = await getUserInfo();
if (userResponse.data) {
  userStore.login(userResponse.data);
}
else {
  userStore.logout();
}
</script>
<template>
  <div class="about">
    <h1>Hi {{ userStore.user?.name }}!</h1>
    You can go back <RouterLink to="/admin">home</RouterLink> now.
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
