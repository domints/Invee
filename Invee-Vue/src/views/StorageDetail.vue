<script setup lang="ts">
import { getStorage, getStorageBySlug, type GetStorageResponse } from '@/client';
import StorageList from '@/components/StorageList.vue';
import { ref } from 'vue'
import { onBeforeRouteUpdate, useRoute } from 'vue-router'
import SvgIcon from '@jamescoyle/vue-icon';
import { mdiArrowUpLeftBold } from '@mdi/js';

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
    // only fetch the user if the id changed as maybe only the query or the hash changed
    if (to.params.id !== from.params.id) {
        storage.value = await reloadStorage(<string>to.params.id);
    }
});
</script>
<template>
    <div class="storage-header">
        <div class="storage-header__back">
            <router-link v-if="storage?.parentId"
                :to="{ name: 'storage', params: { id: storage?.parentSlug ?? storage?.parentId } }">
                <svg-icon type="mdi" size="1rem" :path="mdiArrowUpLeftBold"></svg-icon> Up!
            </router-link>
            <router-link v-if="!storage?.parentId" :to="{ name: 'home' }">
                <svg-icon type="mdi" size="1rem" :path="mdiArrowUpLeftBold"></svg-icon> Up!
            </router-link>
        </div>
        <div class="storage-header__name">
            <h2>{{ storage?.name }}</h2>
        </div>
    </div>

    <StorageList v-if="storage?.childStorages" :storage-items=storage?.childStorages></StorageList>
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

    &__back a {
        display: flex;
        height: 100%;
        align-items: center;
        padding: 0;

        svg {
            margin-right: 0.5rem;
        }
    }
}
</style>