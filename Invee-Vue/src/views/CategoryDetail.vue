<script setup lang="ts">
import { ElButton, ElCard } from 'element-plus';
import CardHeader from '@/components/CardHeader.vue';
import { getCategoryItems, getCategoryTree, type ItemListEntry, type CategoryTreeResponse } from '@/client';
import { ref, useTemplateRef } from 'vue';
import { onBeforeRouteUpdate, useRoute } from 'vue-router';
import { slugId, slugParentId } from '@/utils';
import NewCategoryDialog from '@/components/NewCategoryDialog.vue';
import NewItemDialog from '@/components/NewItemDialog.vue';
import ItemList from '@/components/ItemList.vue';
import { useUserStore } from '@/stores/user';
import SvgIcon from '@jamescoyle/vue-icon';
import { mdiFolderOutline, mdiChevronLeft, mdiChevronRight } from '@mdi/js';

type CategoryItem = {
    id: number;
    parentId?: number | null;
    name: string | null;
    slug?: string | null;
    parentSlug?: string | null;
}

const userStore = useUserStore();

var categoryTree: CategoryTreeResponse[] = [];
var categoryDict: { [id: number]: CategoryItem } = {};
var childrenDict: { [id: number]: CategoryItem[] } = {};
var slugDict: { [slug: string]: CategoryItem } = {};
const currentCategory = ref<CategoryItem>();
const currentChildren = ref<CategoryItem[]>();
const currentItems = ref<ItemListEntry[]>([]);

const newCategoryDialog = useTemplateRef("newCategoryDialog");
const newItemDialog = useTemplateRef("newItemDialog");

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

    currentItems.value = (await getCategoryItems({ path: { id: currentCategory.value.id! } })).data ?? [];
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

const onCategoryCreated = async (newCategoryId: number) => {
    await refreshCategories()
}
</script>

<template>
    <div class="detailContainer">
        <el-card>
            <template #header>
                <CardHeader v-if="userStore?.loggedIn" :title="currentCategory?.name!" button-text="Add child +" @btn-clicked="newCategoryDialog?.openCreateCategoryDialog(Number(route.params.id))" @categoryCreated="onCategoryCreated">
                </CardHeader>
            </template>
            <nav class="catNav">
                <router-link
                    v-if="currentCategory?.parentId"
                    :to="{ name: 'category', params: slugParentId(currentCategory) }"
                    class="catNav__item catNav__item--back"
                >
                    <SvgIcon type="mdi" size="1.1rem" :path="mdiChevronLeft" class="catNav__icon" />
                    <span>Back</span>
                </router-link>
                <router-link
                    v-else
                    :to="{ name: 'home' }"
                    class="catNav__item catNav__item--back"
                >
                    <SvgIcon type="mdi" size="1.1rem" :path="mdiChevronLeft" class="catNav__icon" />
                    <span>Home</span>
                </router-link>

                <div v-if="currentChildren?.length" class="catNav__divider"></div>

                <router-link
                    v-for="child in currentChildren"
                    :key="child.id"
                    :to="{ name: 'category', params: slugId(child) }"
                    class="catNav__item"
                >
                    <SvgIcon type="mdi" size="1.1rem" :path="mdiFolderOutline" class="catNav__icon" />
                    <span class="catNav__label">{{ child.name }}</span>
                    <SvgIcon type="mdi" size="1rem" :path="mdiChevronRight" class="catNav__arrow" />
                </router-link>
            </nav>
        </el-card>
        <div class="itemsContainer">
            <div class="items-header">
                <h2>{{ currentCategory?.name }}</h2>
                <el-button v-if="userStore?.loggedIn" type="primary" plain @click="newItemDialog?.open('category', currentCategory!.id)">
                    Add item +
                </el-button>
            </div>
            <ItemList v-if="currentItems.length" :items="currentItems" />
            <p v-else class="empty-state">No items in this category</p>
        </div>
    </div>

    <NewCategoryDialog ref="newCategoryDialog"></NewCategoryDialog>
    <NewItemDialog ref="newItemDialog"></NewItemDialog>
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
    flex-grow: 1;
}

.items-header {
    display: flex;
    align-items: center;
    margin-bottom: 1.5em;

    h2 {
        flex-grow: 1;
        text-align: center;
        margin: 0;
    }
}

.empty-state {
    color: var(--el-text-color-secondary);
    text-align: center;
}

/* ── Sidebar nav ── */
.catNav {
    display: flex;
    flex-direction: column;
    gap: 2px;
    margin: -4px;

    &__divider {
        height: 1px;
        background: var(--el-border-color-lighter);
        margin: 4px 0;
    }

    &__item {
        display: flex;
        align-items: center;
        gap: 0.45rem;
        padding: 0.5rem 0.6rem;
        border-radius: var(--el-border-radius-base);
        text-decoration: none;
        color: var(--el-text-color-primary);
        font-size: 0.875rem;
        transition: background 0.15s, border-left-color 0.15s;
        border-left: 2px solid transparent;

        &:hover {
            background: var(--el-fill-color-light);
            border-left-color: var(--el-color-primary-light-5);
        }

        &--back {
            color: var(--el-text-color-secondary);
            font-size: 0.82rem;

            &:hover {
                color: var(--el-text-color-primary);
            }
        }
    }

    &__icon {
        flex-shrink: 0;
        color: var(--el-color-primary);

        .catNav__item--back & {
            color: var(--el-text-color-secondary);
        }
    }

    &__label {
        flex: 1;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    &__arrow {
        flex-shrink: 0;
        color: var(--el-text-color-placeholder);
    }
}
</style>