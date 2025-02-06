<script setup lang="ts">
import type { StorageListEntry } from '@/client';
import SvgIcon from '@jamescoyle/vue-icon'
import { mdiPackageVariant } from '@mdi/js'

defineProps<{
    storage: StorageListEntry
}>()
</script>

<template>
    <li>
        <router-link :to="{ name: 'storage', params: { id: storage.slug ?? storage.id } }">
            <div class="icon">
                <SvgIcon type="mdi" size="2rem" :path="mdiPackageVariant"></SvgIcon>
            </div>
            <div class="label">
                {{ storage.name }}
            </div>
        </router-link>
    </li>
</template>

<style lang="scss" scoped>
li {
    height: 3rem;
    margin-bottom: 5px;

    a {
        display: flex;
        width: 100%;
        height: 100%;
        padding: 0;


        .icon {
            padding-left: 0.5rem;
            padding-right: 0.5rem;
            display: flex;
            justify-content: center;
            align-items: center;
            vertical-align: middle;
        }

        .label {
            display: flex;
            justify-content: center;
            align-items: center;
            flex-grow: 1;
        }
    }
}
</style>