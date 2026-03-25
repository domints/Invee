<script setup lang="ts">
import { ElCard } from 'element-plus';
import CardHeader from '@/components/CardHeader.vue';
import { getCategoryItems, getCategoryTree, type ItemListEntry, type CategoryTreeResponse } from '@/client';
import { ref } from 'vue';
import { onBeforeRouteUpdate, useRoute } from 'vue-router';
import { slugId, slugParentId } from '@/utils';

type CategoryItem = {
    id: number;
    parentId?: number | null;
    name: string | null;
    slug?: string | null;
    parentSlug?: string | null;
}

var categoryTree: CategoryTreeResponse[] = [];
var categoryDict: { [id: number]: CategoryItem } = {};
var childrenDict: { [id: number]: CategoryItem[] } = {};
var slugDict: { [slug: string]: CategoryItem } = {};
const currentCategory = ref<CategoryItem>();
const currentChildren = ref<CategoryItem[]>();
const currentItems = ref<ItemListEntry[]>();

const fillDict = (cats: CategoryTreeResponse[]) => {
    for (let c of cats) {
        let o: CategoryItem = { id: c.id!, parentId: c.parentId, name: c.name, slug: c.slug };
        categoryDict[c.id!] = o;
        if (c.slug) {
            slugDict[c.slug] = o;
        }
        if (childrenDict[c.parentId!]) {
            childrenDict[c.parentId!].push(o);
        }
        else {
            childrenDict[c.parentId!] = [o];
        }

        if (c.children) {
            fillDict(c.children);
        }
    }
}

const refreshCategories = async () => {
    let categoryTreeResp = (await getCategoryTree()).data;
    if (!categoryTreeResp)
        return;
    categoryTree = categoryTreeResp;
    categoryDict = {};
    slugDict = {};
    childrenDict = {};

    fillDict(categoryTree);

    for (let c in categoryDict) {
        if (categoryDict[c].parentId) {
            let parent = categoryDict[categoryDict[c].parentId];
            categoryDict[c].parentSlug = parent.slug;
        }
    }
}

const updateCurrentCat = async (id: string | number) => {
    if (!isNaN(+id)) {
        currentCategory.value = categoryDict[+id];
    }
    else {
        currentCategory.value = slugDict[id];
    }

    currentChildren.value = childrenDict[currentCategory.value.id!];

    currentItems.value = (await getCategoryItems({ path: { id: currentCategory.value.id! } })).data;
};

await refreshCategories();
const route = useRoute();
await updateCurrentCat(<string>route.params.id);

onBeforeRouteUpdate(async (to, from) => {
    // only fetch the user if the id changed as maybe only the query or the hash changed
    if (to.params.id !== from.params.id) {
        await updateCurrentCat(<string>to.params.id);
    }
});
</script>

<template>
    <div class="detailContainer">
        <el-card>
            <template #header>
                <CardHeader :title="currentCategory?.name!">
                </CardHeader>
            </template>
            <ul>
                <li v-if="currentCategory?.parentId">
                    <router-link :to="{ name: 'category', params: slugParentId(currentCategory) }">Back</router-link>
                </li>
                <li v-else>
                    <router-link :to="{ name: 'home' }">Back</router-link>
                </li>
                <li v-for="child in currentChildren">
                    <router-link :to="{ name: 'category', params: slugId(child) }">{{ child.name }}</router-link>
                </li>
            </ul>
        </el-card>
        <div class="itemsContainer">
            <ul>
                <li v-for="item in currentItems">{{ item.name }}</li>
            </ul>
            XD
        </div>
    </div>
</template>

<style lang="scss" scoped>
.detailContainer {
    display: flex;
    gap: 1rem;
}

.el-card {
    width: 25%;
}

.itemsContainer {
    background-color: bisque;
    flex-grow: 1;
}

ul {
    list-style-type: none;
    margin: 0;
    padding: 0;
}
</style>