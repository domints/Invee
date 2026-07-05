<script setup lang="ts">
import { createCategory } from '@/client';
import { slugify } from '@/utils';
import { ElButton, ElDialog, ElForm, ElFormItem, ElInput } from 'element-plus';
import { reactive, ref } from 'vue';

const createCategoryDialogVisible = ref(false)
const createCategoryForm = reactive({
    name: '',
    parentCategoryId: <number | null>null,
    slug: <string | null>null
});
const emit = defineEmits(["categoryCreated"]);

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
    emit("categoryCreated");
    //await refreshCategories();
}

defineExpose({ openCreateCategoryDialog });

</script>

<template>
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