<script setup lang="ts">
import { deleteCategory, renameCategory, type CategoryTreeResponse } from '@/client';
import { ElButton, ElDialog, ElForm, ElFormItem, ElInput } from 'element-plus';
import { Plus, Delete, Edit, Rank } from '@element-plus/icons-vue';
import { reactive, ref } from 'vue';

defineProps<{
    category: CategoryTreeResponse[]
}>()
const emit = defineEmits<{
    addChild: [parentId: number],
    removed: [id: number],
    changed: [],
    move: [id: number, name: string]
}>();

const renameDialogVisible = ref(false)
const renameForm = reactive({
    id: 0,
    name: ''
})

const openRenameDialog = (cat: CategoryTreeResponse) => {
    renameForm.id = cat.id!;
    renameForm.name = cat.name;
    renameDialogVisible.value = true;
};

const saveRename = async () => {
    renameDialogVisible.value = false;
    await renameCategory({
        path: { id: renameForm.id },
        body: { id: renameForm.id, name: renameForm.name }
    });
    emit('changed');
};

const remove = async (id: number) => {
    await deleteCategory({ path: { id: id } });
    emit('removed', id);
}
</script>

<template>
    <ul>
        <li v-for="c in category" :key="c.id">
            <div class="item">
                <div class="item__icon">

                </div>
                <div class="item__name">
                    {{ c.name }}
                </div>
                <div class="item__actions">
                    <el-button :icon="Plus" @click="$emit('addChild', c.id!)"></el-button>
                    <el-button :icon="Edit" @click="openRenameDialog(c)"></el-button>
                    <el-button :icon="Rank" @click="$emit('move', c.id!, c.name)"></el-button>
                    <el-button :icon="Delete" @click="remove(c.id!)" plain type="danger"></el-button>
                </div>
            </div>
            <div class="subitems" v-if="c.children && c.children.length">
                <CategoryTree
                    :category="c.children!"
                    @add-child="(parentId) => $emit('addChild', parentId)"
                    @removed="(id) => $emit('removed', id)"
                    @changed="() => $emit('changed')"
                    @move="(id, name) => $emit('move', id, name)"
                >
                </CategoryTree>
            </div>
        </li>
    </ul>

    <el-dialog v-model="renameDialogVisible" title="Rename category">
        <el-form :model="renameForm">
            <el-form-item label="Name">
                <el-input v-model="renameForm.name" autocomplete="off" />
            </el-form-item>
        </el-form>
        <template #footer>
            <div class="dialog-footer">
                <el-button @click="renameDialogVisible = false">Cancel</el-button>
                <el-button type="primary" @click="saveRename()">
                    Confirm
                </el-button>
            </div>
        </template>
    </el-dialog>
</template>

<style lang="scss" scoped>
ul {
    list-style-type: none;
    margin: 0;
    padding: 0;
}

.item {
    display: flex;
    padding: 0.2rem;

    &__name {
        flex-grow: 1;
        display: flex;
        align-items: center;
    }

    &__actions {
        .el-button+.el-button {
            margin-left: 0.2rem;
        }
    }
}

.subitems {
    padding-left: 1rem;
    padding-bottom: 1rem;
}
</style>
