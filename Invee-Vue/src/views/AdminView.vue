<script setup lang="ts">

import { createCategory, createStorage, createStorageType, getCategoryTree, getStorages, getStorageTypes, setCategoryParent, setStorageParent, type StorageTypeDto } from '@/client';

import CategoryTree from '@/components/CategoryTree.vue';

import StorageTree from '@/components/StorageTree.vue';

import StorageTypeList from '@/components/StorageTypeList.vue';

import MoveToParentDialog from '@/components/MoveToParentDialog.vue';

import { reactive, ref } from 'vue';

import { ElCard, ElButton, ElDialog, ElForm, ElFormItem, ElInput, ElSelect, ElOption } from 'element-plus';

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



const createStorageDialogVisible = ref(false)

const createStorageForm = reactive({

    name: '',

    parentStorageId: <number | null>null,

    storageTypeId: <number | null>null

})

const storageTypes = ref<StorageTypeDto[]>([])



const createStorageTypeDtoDialogVisible = ref(false)

const createStorageTypeDtoForm = reactive({

    name: ''

})



const moveDialogVisible = ref(false)

const moveTarget = reactive({

    kind: <'category' | 'storage' | null>null,

    id: <number | null>null,

    name: ''

})



storageTree.value = (await getStorages()).data;

categoryTree.value = (await getCategoryTree()).data;

storageTypes.value = (await getStorageTypes()).data ?? [];



const refreshCategories = async () => {

    categoryTree.value = (await getCategoryTree()).data;

}



const refreshStorages = async () => {

    storageTree.value = (await getStorages()).data;

}



const refreshStorageTypeDtos = async () => {

    storageTypes.value = (await getStorageTypes()).data ?? [];

}



const onRefreshClicked = async () => {

    refreshStorages();

    refreshCategories();

    refreshStorageTypeDtos();

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



const openCreateStorageDialog = (parentId: number | null = null) => {

    createStorageForm.name = '';

    createStorageForm.parentStorageId = parentId;

    createStorageForm.storageTypeId = storageTypes.value[0]?.id ?? null;

    createStorageDialogVisible.value = true;

};



const saveStorage = async () => {

    if (createStorageForm.storageTypeId == null)

        return;



    createStorageDialogVisible.value = false;

    let slug = slugify(createStorageForm.name);

    await createStorage({

        body: {

            name: createStorageForm.name,

            parentId: createStorageForm.parentStorageId,

            storageTypeId: createStorageForm.storageTypeId,

            slug: slug

        }

    });

    await refreshStorages();

}



const openCreateStorageTypeDtoDialog = () => {

    createStorageTypeDtoForm.name = '';

    createStorageTypeDtoDialogVisible.value = true;

};



const saveStorageTypeDto = async () => {

    createStorageTypeDtoDialogVisible.value = false;

    await createStorageType({

        body: {

            name: createStorageTypeDtoForm.name

        }

    });

    await refreshStorageTypeDtos();

}



const openMoveDialog = (kind: 'category' | 'storage', id: number, name: string) => {

    moveTarget.kind = kind;

    moveTarget.id = id;

    moveTarget.name = name;

    moveDialogVisible.value = true;

}



const confirmMove = async (parentId: number | null) => {

    if (moveTarget.kind === 'category' && moveTarget.id != null) {

        await setCategoryParent({

            path: { id: moveTarget.id },

            body: { id: moveTarget.id, parentId: parentId }

        });

        await refreshCategories();

    } else if (moveTarget.kind === 'storage' && moveTarget.id != null) {

        await setStorageParent({

            path: { id: moveTarget.id },

            body: { id: moveTarget.id, parentId: parentId }

        });

        await refreshStorages();

    }

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

            <CategoryTree

                :category="categoryTree"

                @add-child="(parentId) => openCreateCategoryDialog(parentId)"

                @removed="refreshCategories()"

                @changed="refreshCategories()"

                @move="(id, name) => openMoveDialog('category', id, name)"

            ></CategoryTree>

        </el-card>

        <el-card>

            <template #header>

                <CardHeader title="Storages" button-text="Add +" @btn-clicked="openCreateStorageDialog()">

                </CardHeader>

            </template>

            <StorageTree

                :storage="storageTree"

                :storage-types="storageTypes"

                @add-child="(parentId) => openCreateStorageDialog(parentId)"

                @changed="refreshStorages()"

                @move="(id, name) => openMoveDialog('storage', id, name)"

            ></StorageTree>

        </el-card>

        <el-card class="admin-container__storage-types">

            <template #header>

                <CardHeader title="Storage types" button-text="Add +" @btn-clicked="openCreateStorageTypeDtoDialog()">

                </CardHeader>

            </template>

            <StorageTypeList :types="storageTypes" @changed="refreshStorageTypeDtos()"></StorageTypeList>

        </el-card>

    </div>



    <MoveToParentDialog

        v-model:visible="moveDialogVisible"

        :tree="moveTarget.kind === 'category' ? categoryTree : storageTree"

        :node-id="moveTarget.id"

        :node-name="moveTarget.name"

        @confirm="confirmMove"

    />



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



    <el-dialog v-model="createStorageDialogVisible" title="Create storage">

        <el-form :model="createStorageForm">

            <el-form-item label="Storage name">

                <el-input v-model="createStorageForm.name" autocomplete="off" />

            </el-form-item>

            <el-form-item label="Storage type">

                <el-select v-model="createStorageForm.storageTypeId" placeholder="Select type">

                    <el-option v-for="t in storageTypes" :key="t.id" :label="t.name" :value="t.id!" />

                </el-select>

            </el-form-item>

        </el-form>

        <template #footer>

            <div class="dialog-footer">

                <el-button @click="createStorageDialogVisible = false">Cancel</el-button>

                <el-button type="primary" @click="saveStorage()" :disabled="createStorageForm.storageTypeId == null">

                    Confirm

                </el-button>

            </div>

        </template>

    </el-dialog>



    <el-dialog v-model="createStorageTypeDtoDialogVisible" title="Create storage type">

        <el-form :model="createStorageTypeDtoForm">

            <el-form-item label="Storage type name">

                <el-input v-model="createStorageTypeDtoForm.name" autocomplete="off" />

            </el-form-item>

        </el-form>

        <template #footer>

            <div class="dialog-footer">

                <el-button @click="createStorageTypeDtoDialogVisible = false">Cancel</el-button>

                <el-button type="primary" @click="saveStorageTypeDto()">

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



    &__storage-types {

        grid-column: 1 / span 2;

    }

}

</style>

