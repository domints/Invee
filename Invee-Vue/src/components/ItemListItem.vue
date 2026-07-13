<script setup lang="ts">
import type { ItemListEntry } from '@/client';
import { formatItemQuantity, slugId } from '@/utils';
import { computed } from 'vue';
import SvgIcon from '@jamescoyle/vue-icon'
import { mdiCubeOutline } from '@mdi/js'
import { RouterLink } from 'vue-router';

const props = defineProps<{
    item: ItemListEntry
}>()

const quantityLabel = computed(() => formatItemQuantity(props.item))
</script>

<template>
    <li>
        <router-link :to="{ name: 'item', params: slugId(item) }" class="row">
            <div class="icon">
                <SvgIcon type="mdi" size="2rem" :path="mdiCubeOutline"></SvgIcon>
            </div>
            <div class="label">
                <span class="name">{{ item.name }}</span>
                <span v-if="quantityLabel" class="quantity">{{ quantityLabel }}</span>
            </div>
            <div v-if="item.borrowed || item.broken" class="badges">
                <span v-if="item.borrowed" class="badge badge--borrowed">Borrowed</span>
                <span v-if="item.broken" class="badge badge--broken">Broken</span>
            </div>
        </router-link>
    </li>
</template>

<style lang="scss" scoped>
li {
    height: 3rem;
    margin-bottom: 5px;

    .row {
        display: flex;
        width: 100%;
        height: 100%;
        padding: 0;
        align-items: center;
        text-decoration: none;
        color: inherit;

        &:hover {
            background-color: var(--el-fill-color-light);
            border-radius: 4px;
        }

        .icon {
            padding-left: 0.5rem;
            padding-right: 0.5rem;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .label {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            flex-grow: 1;

            .quantity {
                color: var(--el-text-color-secondary);
                font-size: 0.875rem;
            }
        }

        .badges {
            display: flex;
            gap: 0.25rem;
            padding-right: 0.5rem;
        }

        .badge {
            font-size: 0.75rem;
            padding: 0.125rem 0.375rem;
            border-radius: 0.25rem;

            &--borrowed {
                background-color: var(--el-color-warning-light-7);
                color: var(--el-color-warning-dark-2);
            }

            &--broken {
                background-color: var(--el-color-danger-light-7);
                color: var(--el-color-danger-dark-2);
            }
        }
    }
}
</style>

<style lang="scss" scoped>
li {
    height: 3rem;
    margin-bottom: 5px;

    .row {
        display: flex;
        width: 100%;
        height: 100%;
        padding: 0;
        align-items: center;

        .icon {
            padding-left: 0.5rem;
            padding-right: 0.5rem;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .label {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            flex-grow: 1;

            .quantity {
                color: var(--el-text-color-secondary);
                font-size: 0.875rem;
            }
        }

        .badges {
            display: flex;
            gap: 0.25rem;
            padding-right: 0.5rem;
        }

        .badge {
            font-size: 0.75rem;
            padding: 0.125rem 0.375rem;
            border-radius: 0.25rem;

            &--borrowed {
                background-color: var(--el-color-warning-light-7);
                color: var(--el-color-warning-dark-2);
            }

            &--broken {
                background-color: var(--el-color-danger-light-7);
                color: var(--el-color-danger-dark-2);
            }
        }
    }
}
</style>
