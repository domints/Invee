<script setup lang="ts">
import { createCategory, getCategoryTree, getStorages } from '@/client';
import CategoryTree from '@/components/CategoryTree.vue';
import StorageTree from '@/components/StorageTree.vue';
import { reactive, ref } from 'vue';
import { ElCard, ElButton, ElDialog, ElForm, ElFormItem, ElInput } from 'element-plus';
import { useRoute } from 'vue-router';
import CardHeader from '@/components/CardHeader.vue';
import { slugify } from '@/utils';

const storageTree = ref();
const categoryTree = ref();

const createCategoryDialogVisible = ref(false)
const createCategoryForm = reactive({
    name: '',
    parentCategoryId: <number | null>null,
    slug: <string | null>null
})

const route = useRoute();
storageTree.value = (await getStorages()).data;
categoryTree.value = (await getCategoryTree()).data;

const refreshCategories = async () => {
    categoryTree.value = (await getCategoryTree()).data;
}

const onRefreshClicked = async () => {
    storageTree.value = (await getStorages()).data;
    refreshCategories();
};

const openCreateCategoryDialog = (parentId: number | null = null) => {
    createCategoryForm.name = '';
    createCategoryForm.parentCategoryId = parentId;
    createCategoryForm.slug = null;
    createCategoryDialogVisible.value = true;
};

const saveCategory = async () => {
    createCategoryDialogVisible.value = false;
    let slug = slugify(createCategoryForm.name);
    await createCategory({
        body: {
            name: createCategoryForm.name,
            parentId: createCategoryForm.parentCategoryId,
            slug: slug
        }
    });
    await refreshCategories();
}

</script>

<template>
    <div class="admin-container">
        <div class="admin-container__header">
            <div class="admin-container__title">Admin panel</div>
            <div class="admin-container__actions">
                <el-button @click="onRefreshClicked" plain type="primary">Refresh</el-button>
            </div>
        </div>
        <el-card>
            <template #header>
                <CardHeader title="Categories" button-text="Add +" @btn-clicked="openCreateCategoryDialog()">
                </CardHeader>
            </template>
            <CategoryTree :category="categoryTree" @add-child="(parentId) => openCreateCategoryDialog(parentId)" @removed="refreshCategories()"></CategoryTree>
        </el-card>
        <el-card>
            <template #header>
                <CardHeader title="Storages" button-text="Add +"></CardHeader>
            </template>
            <StorageTree :storage="storageTree"></StorageTree>
        </el-card>
    </div>

    <el-dialog v-model="createCategoryDialogVisible" title="Create category">
        <el-form :model="createCategoryForm">
            <el-form-item label="Category name">
                <el-input v-model="createCategoryForm.name" autocomplete="off" />
            </el-form-item>
        </el-form>
        <template #footer>
            <div class="dialog-footer">
                <el-button @click="createCategoryDialogVisible = false">Cancel</el-button>
                <el-button type="primary" @click="saveCategory()">
                    Confirm
                </el-button>
            </div>
        </template>
    </el-dialog>
</template>

<style lang="scss" scoped>
.admin-container {
    display: grid;
    grid-template-columns: 1fr 1fr;
    column-gap: 1rem;
    row-gap: 1rem;

    &__header {
        grid-column: 1 / span 2;
        display: flex;
    }

    &__title {
        flex-grow: 1;
        display: flex;
        justify-content: center;
        align-items: center;
        font-size: 2rem;
    }
}
</style>