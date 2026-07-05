<script setup lang="ts">
import { deleteStorage, updateStorage, type StorageTreeResponse, type StorageTypeDto } from '@/client';
import { ElButton, ElDialog, ElForm, ElFormItem, ElInput, ElSelect, ElOption } from 'element-plus';
import { Plus, Delete, Edit, Rank } from '@element-plus/icons-vue';
import { reactive, ref } from 'vue';

defineProps<{
    storage: StorageTreeResponse[]
    storageTypes: StorageTypeDto[]
}>()
const emit = defineEmits<{
    addChild: [parentId: number],
    changed: [],
    move: [id: number, name: string]
}>();

const editDialogVisible = ref(false)
const editForm = reactive({
    id: 0,
    name: '',
    storageTypeId: <number | null>null
})

const openEditDialog = (s: StorageTreeResponse) => {
    editForm.id = s.id!;
    editForm.name = s.name;
    editForm.storageTypeId = s.storageTypeId ?? null;
    editDialogVisible.value = true;
};

const saveEdit = async () => {
    if (editForm.storageTypeId == null)
        return;

    editDialogVisible.value = false;
    await updateStorage({
        path: { id: editForm.id },
        body: { id: editForm.id, name: editForm.name, storageTypeId: editForm.storageTypeId }
    });
    emit('changed');
};

const remove = async (id: number) => {
    await deleteStorage({ path: { id: id } });
    emit('changed');
}
</script>

<template>
    <ul>
        <li v-for="s in storage" :key="s.id">
            <div class="item">
                <div class="item__name">
                    {{ s.name }}
                </div>
                <div class="item__actions">
                    <el-button :icon="Plus" @click="$emit('addChild', s.id!)"></el-button>
                    <el-button :icon="Edit" @click="openEditDialog(s)"></el-button>
                    <el-button :icon="Rank" @click="$emit('move', s.id!, s.name)"></el-button>
                    <el-button :icon="Delete" @click="remove(s.id!)" plain type="danger"></el-button>
                </div>
            </div>
            <div class="subitems" v-if="s.children && s.children.length">
                <StorageTree
                    :storage="s.children!"
                    :storage-types="storageTypes"
                    @add-child="(parentId) => $emit('addChild', parentId)"
                    @changed="() => $emit('changed')"
                    @move="(id, name) => $emit('move', id, name)"
                >
                </StorageTree>
            </div>
        </li>
    </ul>

    <el-dialog v-model="editDialogVisible" title="Edit storage">
        <el-form :model="editForm">
            <el-form-item label="Storage name">
                <el-input v-model="editForm.name" autocomplete="off" />
            </el-form-item>
            <el-form-item label="Storage type">
                <el-select v-model="editForm.storageTypeId" placeholder="Select type">
                    <el-option v-for="t in storageTypes" :key="t.id" :label="t.name" :value="t.id!" />
                </el-select>
            </el-form-item>
        </el-form>
        <template #footer>
            <div class="dialog-footer">
                <el-button @click="editDialogVisible = false">Cancel</el-button>
                <el-button type="primary" @click="saveEdit()" :disabled="editForm.storageTypeId == null">
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
