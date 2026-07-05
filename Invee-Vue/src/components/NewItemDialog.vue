<script setup lang="ts">
import { createItem, getCategoryTree, getStorages, type CategoryTreeResponse, type StorageTreeResponse } from '@/client';
import { slugify } from '@/utils';
import { ElButton, ElDialog, ElForm, ElFormItem, ElInput, ElOption, ElRadio, ElRadioGroup, ElSelect } from 'element-plus';
import { reactive, ref } from 'vue';
import { useRouter } from 'vue-router';

type Context = 'category' | 'storage';

const router = useRouter();

const visible = ref(false);
const context = ref<Context>('category');
const contextId = ref(0);

const form = reactive({
    name: '',
    categoryId: null as number | null,
    storageId: null as number | null,
    quantityType: 0,
});

const categories = ref<{ id: number; label: string }[]>([]);
const storages = ref<{ id: number; label: string }[]>([]);

const flattenCategories = (nodes: CategoryTreeResponse[], prefix = ''): { id: number; label: string }[] => {
    const result: { id: number; label: string }[] = [];
    for (const node of nodes) {
        const label = prefix ? `${prefix} / ${node.name}` : node.name;
        result.push({ id: node.id!, label });
        if (node.children?.length) {
            result.push(...flattenCategories(node.children, label));
        }
    }
    return result;
};

const flattenStorages = (nodes: StorageTreeResponse[], prefix = ''): { id: number; label: string }[] => {
    const result: { id: number; label: string }[] = [];
    for (const node of nodes) {
        const label = prefix ? `${prefix} / ${node.name}` : node.name;
        result.push({ id: node.id!, label });
        if (node.children?.length) {
            result.push(...flattenStorages(node.children, label));
        }
    }
    return result;
};

const open = async (ctx: Context, id: number) => {
    context.value = ctx;
    contextId.value = id;
    form.name = '';
    form.categoryId = ctx === 'category' ? id : null;
    form.storageId = ctx === 'storage' ? id : null;
    form.quantityType = 0;

    if (ctx === 'category') {
        const resp = await getStorages();
        storages.value = flattenStorages(resp.data ?? []);
    } else {
        const resp = await getCategoryTree();
        categories.value = flattenCategories(resp.data ?? []);
    }

    visible.value = true;
};

const confirm = async () => {
    if (!form.name.trim()) return;

    const slug = slugify(form.name);
    const result = await createItem({
        body: {
            name: form.name.trim(),
            categoryId: form.categoryId!,
            storageId: form.storageId!,
            slug,
            quantityType: form.quantityType,
        },
    });

    if (result.data != null) {
        visible.value = false;
        router.push({ name: 'item', params: { id: result.data } });
    }
};

defineExpose({ open });
</script>

<template>
    <el-dialog v-model="visible" :title="context === 'category' ? 'Add item to category' : 'Add item to storage'" width="480px">
        <el-form :model="form" label-width="130px">
            <el-form-item label="Name">
                <el-input v-model="form.name" autocomplete="off" />
            </el-form-item>

            <el-form-item v-if="context === 'category'" label="Storage">
                <el-select v-model="form.storageId" placeholder="Select storage" filterable style="width: 100%">
                    <el-option v-for="s in storages" :key="s.id" :label="s.label" :value="s.id" />
                </el-select>
            </el-form-item>

            <el-form-item v-if="context === 'storage'" label="Category">
                <el-select v-model="form.categoryId" placeholder="Select category" filterable style="width: 100%">
                    <el-option v-for="c in categories" :key="c.id" :label="c.label" :value="c.id" />
                </el-select>
            </el-form-item>

            <el-form-item label="Quantity type">
                <el-radio-group v-model="form.quantityType">
                    <el-radio :value="0">None</el-radio>
                    <el-radio :value="1">Levels</el-radio>
                    <el-radio :value="2">Precise</el-radio>
                </el-radio-group>
            </el-form-item>
        </el-form>

        <template #footer>
            <div class="dialog-footer">
                <el-button @click="visible = false">Cancel</el-button>
                <el-button type="primary" :disabled="!form.name.trim() || (context === 'category' && !form.storageId) || (context === 'storage' && !form.categoryId)" @click="confirm">
                    Add item
                </el-button>
            </div>
        </template>
    </el-dialog>
</template>
