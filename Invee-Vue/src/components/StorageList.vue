<script setup lang="ts">
import type { StorageListEntry } from '@/client';
import StorageListItem from '@/components/StorageListItem.vue';

defineProps<{
    storageItems: StorageListEntry[]
}>()
</script>

<template>
    <ul>
        <StorageListItem v-for="item in storageItems" :storage=item></StorageListItem>
    </ul>
</template>

<style lang="scss" scoped>
ul {
    list-style-type: none;
    padding-left: 0;
}
</style>