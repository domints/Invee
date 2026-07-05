<script setup lang="ts">
import { getStorage, getStorageBySlug, type GetStorageResponse } from '@/client';
import StorageList from '@/components/StorageList.vue';
import ItemList from '@/components/ItemList.vue';
import NewItemDialog from '@/components/NewItemDialog.vue';
import { ElButton } from 'element-plus';
import { ref, useTemplateRef } from 'vue'
import { onBeforeRouteUpdate, useRoute } from 'vue-router'
import SvgIcon from '@jamescoyle/vue-icon';
import { mdiArrowUpLeftBold } from '@mdi/js';
import { slugParentId } from '@/utils';
import { useUserStore } from '@/stores/user';

const userStore = useUserStore();
const newItemDialog = useTemplateRef('newItemDialog');

const storageId = ref(0);
const storage = ref<GetStorageResponse>();
const reloadStorage = async (id: string) => {
    console.log(id);
    if (!isNaN(+id)) {
        storageId.value = +id;
        let s = await getStorage({ path: { id: +id } });
        return s.data;
    }
    else {
        storageId.value = -1;
        let s = await getStorageBySlug({ path: { slug: id } });
        return s.data;
    }
}

const route = useRoute();
storage.value = await reloadStorage(<string>route.params.id);

onBeforeRouteUpdate(async (to, from) => {
    if (to.params.id !== from.params.id) {
        storage.value = await reloadStorage(<string>to.params.id);
    }
});
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
            <el-button type="primary" plain @click="newItemDialog?.open('storage', storageId)">Add item +</el-button>
        </div>
    </div>

    <StorageList v-if="storage?.childStorages?.length" :storage-items="storage.childStorages"></StorageList>

    <div class="items-section">
        <ItemList v-if="storage?.items?.length" :items="storage.items" />
        <p v-else-if="!storage?.childStorages?.length" class="empty-state">No items or sub-storages here</p>
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

.empty-state {
    color: var(--el-text-color-secondary);
    text-align: center;
}
</style>