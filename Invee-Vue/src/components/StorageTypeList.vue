<script setup lang="ts">
import { deleteStorageType, renameStorageType, type StorageTypeDto } from '@/client';
import { ElButton, ElDialog, ElForm, ElFormItem, ElInput } from 'element-plus';
import { Delete, Edit } from '@element-plus/icons-vue';
import { reactive, ref } from 'vue';

defineProps<{
    types: StorageTypeDto[]
}>()
const emit = defineEmits<{
    changed: []
}>();

const renameDialogVisible = ref(false)
const renameForm = reactive({
    id: 0,
    name: ''
})

const openRenameDialog = (type: StorageTypeDto) => {
    renameForm.id = type.id!;
    renameForm.name = type.name;
    renameDialogVisible.value = true;
};

const saveRename = async () => {
    renameDialogVisible.value = false;
    await renameStorageType({
        path: { id: renameForm.id },
        body: { id: renameForm.id, name: renameForm.name }
    });
    emit('changed');
};

const remove = async (id: number) => {
    await deleteStorageType({ path: { id: id } });
    emit('changed');
}
</script>

<template>
    <ul>
        <li v-for="t in types" :key="t.id">
            <div class="item">
                <div class="item__name">
                    {{ t.name }}
                </div>
                <div class="item__actions">
                    <el-button :icon="Edit" @click="openRenameDialog(t)"></el-button>
                    <el-button :icon="Delete" @click="remove(t.id!)" plain type="danger"></el-button>
                </div>
            </div>
        </li>
    </ul>

    <el-dialog v-model="renameDialogVisible" title="Rename storage type">
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
</style>
