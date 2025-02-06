<script setup lang="ts">
import { getRootStorage, type StorageListEntry } from '@/client';
import StorageList from '@/components/StorageList.vue';
import { ref } from 'vue';

const rootStorages = ref<StorageListEntry[]>();
const errors = ref();
const storagesResponse = await getRootStorage();
if (storagesResponse.error) {
  errors.value = storagesResponse.error;
}
else {
  rootStorages.value = storagesResponse.data;
}
</script>

<template>
  <div class="storage-header">
        <div class="storage-header__name">
            <h2>Home</h2>
        </div>
    </div>
  <StorageList v-if="rootStorages" :storage-items=rootStorages></StorageList>
</template>

<style lang="scss" scoped>
.storage-header {
    display: flex;
    margin-bottom: 1.5em;

    &__name {
        flex-grow: 1;
        display: flex;
        justify-content: center;
    }
}
</style>
