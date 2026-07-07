<script setup lang="ts">
import { getStorage, getStorageBySlug, type GetStorageResponse, type ImageDto } from '@/client';
import StorageList from '@/components/StorageList.vue';
import ItemList from '@/components/ItemList.vue';
import NewItemDialog from '@/components/NewItemDialog.vue';
import ImageGallery from '@/components/ImageGallery.vue';
import ImageUpload from '@/components/ImageUpload.vue';
import { ElButton } from 'element-plus';
import { ref, computed, useTemplateRef } from 'vue'
import { onBeforeRouteUpdate, useRoute } from 'vue-router'
import SvgIcon from '@jamescoyle/vue-icon';
import { mdiArrowUpLeftBold } from '@mdi/js';
import { slugParentId, isZeroAmount } from '@/utils';
import { useUserStore } from '@/stores/user';

const userStore = useUserStore();
const newItemDialog = useTemplateRef('newItemDialog');

const storage = ref<GetStorageResponse>();
const images = ref<ImageDto[]>([]);
const activeItems = computed(() => (storage.value?.items ?? []).filter(i => !isZeroAmount(i)));
const emptyItems = computed(() => (storage.value?.items ?? []).filter(i => isZeroAmount(i)));

const reloadStorage = async (id: string) => {
    if (!isNaN(+id)) {
        let s = await getStorage({ path: { id: +id } });
        return s.data;
    }
    else {
        let s = await getStorageBySlug({ path: { slug: id } });
        return s.data;
    }
}

const route = useRoute();
storage.value = await reloadStorage(<string>route.params.id);
images.value = storage.value?.images ?? [];

onBeforeRouteUpdate(async (to, from) => {
    if (to.params.id !== from.params.id) {
        storage.value = await reloadStorage(<string>to.params.id);
        images.value = storage.value?.images ?? [];
    }
});

const onImageUploaded = async () => {
    storage.value = await reloadStorage(<string>route.params.id);
    images.value = storage.value?.images ?? [];
};

const onImageDeleted = (imageId: number) => {
    images.value = images.value.filter(img => img.id !== imageId);
};
</script>
<template>
    <div class="storage-header">
        <div class="storage-header__back">
            <router-link v-if="storage?.parentId"
                :to="{ name: 'storage', params: slugParentId(storage) }">
                <svg-icon type="mdi" size="1rem" :path="mdiArrowUpLeftBold"></svg-icon> Up!
            </router-link>
            <router-link v-if="!storage?.parentId" :to="{ name: 'home' }">
                <svg-icon type="mdi" size="1rem" :path="mdiArrowUpLeftBold"></svg-icon> Up!
            </router-link>
        </div>
        <div class="storage-header__name">
            <h2>{{ storage?.name }}</h2>
        </div>
        <div v-if="userStore.loggedIn" class="storage-header__actions">
            <el-button type="primary" plain @click="newItemDialog?.open('storage', storage!.id!)">Add item +</el-button>
        </div>
    </div>

    <StorageList v-if="storage?.childStorages?.length" :storage-items="storage.childStorages"></StorageList>

    <div v-if="images.length || userStore.loggedIn" class="images-section">
        <ImageGallery
            :images="images"
            entity-type="storage"
            :entity-id="storage!.id!"
            @deleted="onImageDeleted"
        />
        <ImageUpload
            v-if="userStore.loggedIn"
            entity-type="storage"
            :entity-id="storage!.id!"
            @uploaded="onImageUploaded"
        />
    </div>

    <div class="items-section">
        <ItemList v-if="activeItems.length" :items="activeItems" />
        <details v-if="emptyItems.length" class="empty-items-accordion">
            <summary class="empty-items-accordion__summary">Empty items ({{ emptyItems.length }})</summary>
            <ItemList :items="emptyItems" />
        </details>
        <p v-if="!activeItems.length && !emptyItems.length && !storage?.childStorages?.length" class="empty-state">No items or sub-storages here</p>
    </div>

    <NewItemDialog ref="newItemDialog"></NewItemDialog>
</template>

<style lang="scss" scoped>
.storage-header {
    display: flex;
    align-items: center;
    margin-bottom: 1.5em;

    &__name {
        flex-grow: 1;
        display: flex;
        justify-content: center;
    }

    &__back a {
        display: flex;
        height: 100%;
        align-items: center;
        padding: 0;

        svg {
            margin-right: 0.5rem;
        }
    }

    &__actions {
        display: flex;
        align-items: center;
    }
}

.items-section {
    margin-top: 1rem;
}

.images-section {
    margin-top: 1rem;
    padding: 1rem;
    background: var(--el-bg-color-overlay);
    border-radius: 8px;
}

.empty-state {
    color: var(--el-text-color-secondary);
    text-align: center;
}

.empty-items-accordion {
    margin-top: 0.75rem;
    border: 1px solid var(--el-border-color-lighter);
    border-radius: var(--el-border-radius-base);

    &__summary {
        list-style: none;
        display: flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.55rem 0.75rem;
        cursor: pointer;
        font-size: 0.85rem;
        color: var(--el-text-color-secondary);
        user-select: none;
        border-radius: var(--el-border-radius-base);
        transition: background 0.15s;

        &::-webkit-details-marker { display: none; }

        &::before {
            content: '▶';
            font-size: 0.65rem;
            transition: transform 0.2s;
            flex-shrink: 0;
        }

        &:hover {
            background: var(--el-fill-color-light);
            color: var(--el-text-color-primary);
        }
    }

    &[open] > .empty-items-accordion__summary::before {
        transform: rotate(90deg);
    }
}
</style>