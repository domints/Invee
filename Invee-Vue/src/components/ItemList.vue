<script setup lang="ts">
import type { ItemListEntry } from '@/client';
import ItemListItem from '@/components/ItemListItem.vue';

defineProps<{
    items: ItemListEntry[]
}>()
</script>

<template>
    <ul>
        <ItemListItem v-for="item in items" :key="item.id" :item="item"></ItemListItem>
    </ul>
</template>

<style lang="scss" scoped>
ul {
    list-style-type: none;
    padding-left: 0;
}
</style>
