<script setup lang="ts">
import { getStorage, getStorageBySlug } from '@/client';
import { watch, ref } from 'vue'
import { useRoute } from 'vue-router'

const storageId = ref(0);
const reloadStorage = async (id: string) => {
    console.log(id);
    if (!isNaN(+id)) {
        storageId.value = +id;
        let s = await getStorage({ path: { id: +id } });
        console.log(s);
    }
    else {
        storageId.value = -1;
        let s = await getStorageBySlug({ path: { slug: id } });
        console.log(s);
    }
}

const route = useRoute();
console.log("idk, right after useRoute");
await reloadStorage(<string>route.params.id);
watch(
    () => route.params.id,
    async (newId, oldId) => {
        await reloadStorage(<string>newId);
    }
)
</script>
<template>
    Id: {{ storageId }}
    <router-link :to="{ name: 'storage', params: { id: '15' } }">
        15
    </router-link><br>
    <router-link :to="{ name: 'storage', params: { id: 'ziemniaczki' } }">
        Ziemniaczki
    </router-link><br>
    <router-link :to="{ name: 'storage', params: { id: '2137' } }">
        2137
    </router-link><br>
</template>