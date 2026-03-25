<script setup lang="ts">
import type { StorageTreeResponse } from '@/client';

defineProps<{
    storage: StorageTreeResponse[]
}>()
</script>

<template>
    <ul>
        <li v-for="s in storage">
            {{ s.name }}
        </li>
    </ul>
</template>