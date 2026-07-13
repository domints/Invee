<script setup lang="ts">
import {
    addItemCode,
    createTag,
    deleteItemCode,
    getCategoryTree,
    getItem,
    getItemBySlug,
    getStorages,
    getTags,
    setItemTags,
    updateItem,
    updateItemCode,
    type CategoryTreeResponse,
    type ImageDto,
    type ItemCodeDto,
    type ItemResponse,
    type StorageTreeResponse,
    type TagDto,
} from '@/client';
import { ElButton, ElDatePicker, ElDialog, ElForm, ElFormItem, ElInput, ElInputNumber, ElMessage, ElOption, ElRadio, ElRadioGroup, ElSelect, ElSwitch } from 'element-plus';
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useUserStore } from '@/stores/user';
import ImageGallery from '@/components/ImageGallery.vue';
import ImageUpload from '@/components/ImageUpload.vue';

const route = useRoute();
const router = useRouter();
const userStore = useUserStore();
const rawId = route.params.id as string;

const STOP_WORDS = new Set(['a', 'an', 'the', 'of', 'in', 'for', 'on', 'with', 'and', 'or', 'is', 'it', 'to', 'at', 'by']);

const CODE_TYPE_OPTIONS = [
    { value: 0, label: 'QR Code' },
    { value: 1, label: 'EAN-13' },
    { value: 2, label: 'EAN-8' },
    { value: 3, label: 'UPC-A' },
    { value: 4, label: 'Code 128' },
    { value: 5, label: 'Code 39' },
    { value: 6, label: 'Data Matrix' },
    { value: 7, label: 'PDF417' },
    { value: 8, label: 'Aztec' },
    { value: 9, label: 'ITF-14' },
];
const codeTypeLabel = (value: number) => CODE_TYPE_OPTIONS.find(o => o.value === value)?.label ?? String(value);

const flattenCategories = (nodes: CategoryTreeResponse[], prefix = ''): { id: number; label: string }[] => {
    const result: { id: number; label: string }[] = [];
    for (const node of nodes) {
        const label = prefix ? `${prefix} / ${node.name}` : node.name;
        result.push({ id: node.id!, label });
        if (node.children?.length) result.push(...flattenCategories(node.children, label));
    }
    return result;
};

const flattenStorages = (nodes: StorageTreeResponse[], prefix = ''): { id: number; label: string }[] => {
    const result: { id: number; label: string }[] = [];
    for (const node of nodes) {
        const label = prefix ? `${prefix} / ${node.name}` : node.name;
        result.push({ id: node.id!, label });
        if (node.children?.length) result.push(...flattenStorages(node.children, label));
    }
    return result;
};

const suggestTagIds = (name: string, allTags: TagDto[]): number[] => {
    const words = name.toLowerCase().split(/\s+/).filter(w => w.length > 1 && !STOP_WORDS.has(w));
    return allTags.filter(t => words.includes(t.name.toLowerCase())).map(t => t.id!);
};

const [itemResp, catResp, storResp, tagsResp] = await Promise.all([
    !isNaN(+rawId) ? getItem({ path: { id: +rawId } }) : getItemBySlug({ path: { slug: rawId } }),
    getCategoryTree(),
    getStorages(),
    getTags(),
]);

const item = itemResp.data as ItemResponse;
const itemId = item.id!;
const images = ref<ImageDto[]>(item.images ?? []);

const onImageUploaded = async () => {
    const refreshed = await getItem({ path: { id: itemId } });
    if (refreshed.data) {
        images.value = refreshed.data.images ?? [];
    }
};

const onImageDeleted = (imageId: number) => {
    images.value = images.value.filter(img => img.id !== imageId);
};

const allTags = ref<TagDto[]>(tagsResp.data ?? []);
const categories = flattenCategories(catResp.data ?? []);
const storages = flattenStorages(storResp.data ?? []);

const form = ref({
    name: item.name,
    slug: item.slug ?? '',
    note: item.note ?? '',
    categoryId: item.category.id!,
    storageId: item.storage.id!,
    quantityType: item.quantityType ?? 0,
    quantity: item.quantity ?? null as number | null,
    level: item.level ?? null as number | null,
    broken: item.broken ?? false,
    expiresAt: item.expiresAt ? new Date(item.expiresAt) : null as Date | null,
});

const isNewItem = !item.tags?.length;
const selectedTagIds = ref<number[]>(
    isNewItem
        ? suggestTagIds(item.name, allTags.value)
        : allTags.value.filter(t => item.tags!.includes(t.name)).map(t => t.id!)
);

const newTagInput = ref('');
const saving = ref(false);

// --- Codes ---
const codes = ref<ItemCodeDto[]>(item.codes ?? []);

const newCode = ref({ codeType: 0, contents: '' });
const addingCode = ref(false);

const addCode = async () => {
    if (!newCode.value.contents.trim()) {
        ElMessage.warning('Code contents cannot be empty.');
        return;
    }
    addingCode.value = true;
    try {
        const result = await addItemCode({
            path: { id: itemId },
            body: { id: itemId, codeType: newCode.value.codeType, contents: newCode.value.contents.trim() },
        });
        if (result.data != null) {
            codes.value.push({ id: result.data, codeType: newCode.value.codeType, contents: newCode.value.contents.trim() });
            newCode.value = { codeType: 0, contents: '' };
        } else {
            ElMessage.error('Failed to add code.');
        }
    } finally {
        addingCode.value = false;
    }
};

const editDialog = ref({ visible: false, id: 0, codeType: 0, contents: '' });
const editSaving = ref(false);

const openEditDialog = (code: ItemCodeDto) => {
    editDialog.value = { visible: true, id: code.id, codeType: code.codeType, contents: code.contents };
};

const saveEditCode = async () => {
    if (!editDialog.value.contents.trim()) {
        ElMessage.warning('Code contents cannot be empty.');
        return;
    }
    editSaving.value = true;
    try {
        const result = await updateItemCode({
            path: { id: itemId, codeId: editDialog.value.id },
            body: { id: itemId, codeId: editDialog.value.id, codeType: editDialog.value.codeType, contents: editDialog.value.contents.trim() },
        });
        if (!result.error) {
            const idx = codes.value.findIndex(c => c.id === editDialog.value.id);
            if (idx !== -1) {
                codes.value[idx] = { id: editDialog.value.id, codeType: editDialog.value.codeType, contents: editDialog.value.contents.trim() };
            }
            editDialog.value.visible = false;
        } else {
            ElMessage.error('Failed to update code.');
        }
    } finally {
        editSaving.value = false;
    }
};

const removeCode = async (code: ItemCodeDto) => {
    const result = await deleteItemCode({ path: { id: itemId, codeId: code.id } });
    if (!result.error) {
        codes.value = codes.value.filter(c => c.id !== code.id);
    } else {
        ElMessage.error('Failed to delete code.');
    }
};

// --- /Codes ---

const quantityValue = computed({
    get: () => form.value.quantityType === 1 ? form.value.level : form.value.quantity,
    set: (v: number | null) => {
        if (form.value.quantityType === 1) form.value.level = v;
        else form.value.quantity = v;
    },
});

const createAndAddTag = async () => {
    const name = newTagInput.value.trim();
    if (!name) return;
    const result = await createTag({ body: { name } });
    if (result.data != null) {
        const newTag: TagDto = { id: result.data, name };
        allTags.value.push(newTag);
        selectedTagIds.value.push(result.data);
        newTagInput.value = '';
    }
};

const save = async () => {
    saving.value = true;
    try {
        const [updateResp, tagsUpdateResp] = await Promise.all([
            updateItem({
                path: { id: itemId },
                body: {
                    id: itemId,
                    name: form.value.name,
                    slug: form.value.slug || null,
                    note: form.value.note || null,
                    categoryId: form.value.categoryId,
                    storageId: form.value.storageId,
                    quantityType: form.value.quantityType,
                    quantity: form.value.quantityType === 2 ? form.value.quantity : form.value.quantityType === 1 ? form.value.level : null,
                    broken: form.value.broken,
                    expiresAt: form.value.expiresAt ? form.value.expiresAt.toISOString() : null,
                },
            }),
            setItemTags({
                path: { id: itemId },
                body: { id: itemId, tagIds: selectedTagIds.value },
            }),
        ]);

        if (updateResp.error || tagsUpdateResp.error) {
            ElMessage.error('Failed to save item.');
        } else {
            ElMessage.success('Item saved.');
        }
    } finally {
        saving.value = false;
    }
};
</script>

<template>
    <div class="item-edit">
        <div class="item-edit__header">
            <el-button @click="router.back()">← Back</el-button>
            <h2>{{ form.name || 'Edit item' }}</h2>
        </div>

        <div class="item-edit__card">
            <ImageGallery
                :images="images"
                entity-type="item"
                :entity-id="itemId"
                @deleted="onImageDeleted"
            />
            <ImageUpload
                entity-type="item"
                :entity-id="itemId"
                @uploaded="onImageUploaded"
            />
        </div>

        <el-form :model="form" label-width="140px" class="item-edit__form">
            <el-form-item label="Name">
                <el-input v-model="form.name" />
            </el-form-item>

            <el-form-item label="Slug">
                <el-input v-model="form.slug" placeholder="auto-generated" />
            </el-form-item>

            <el-form-item label="Note">
                <el-input v-model="form.note" type="textarea" :rows="3" />
            </el-form-item>

            <el-form-item label="Category">
                <el-select v-model="form.categoryId" filterable style="width: 100%">
                    <el-option v-for="c in categories" :key="c.id" :label="c.label" :value="c.id" />
                </el-select>
            </el-form-item>

            <el-form-item label="Storage">
                <el-select v-model="form.storageId" filterable style="width: 100%">
                    <el-option v-for="s in storages" :key="s.id" :label="s.label" :value="s.id" />
                </el-select>
            </el-form-item>

            <el-form-item label="Quantity type">
                <el-radio-group v-model="form.quantityType">
                    <el-radio :value="0">None</el-radio>
                    <el-radio :value="1">Levels</el-radio>
                    <el-radio :value="2">Precise</el-radio>
                </el-radio-group>
            </el-form-item>

            <el-form-item v-if="form.quantityType === 2" label="Quantity">
                <el-input-number v-model="form.quantity" :min="0" :precision="2" />
            </el-form-item>

            <el-form-item v-if="form.quantityType === 1" label="Level">
                <el-select v-model="form.level" style="width: 180px">
                    <el-option label="None" :value="0" />
                    <el-option label="Low" :value="1" />
                    <el-option label="Good" :value="2" />
                </el-select>
            </el-form-item>

            <el-form-item label="Broken">
                <el-switch v-model="form.broken" />
            </el-form-item>

            <el-form-item label="Expiry date">
                <el-date-picker
                    v-model="form.expiresAt"
                    type="date"
                    placeholder="No expiry"
                    clearable
                    style="width: 200px"
                />
            </el-form-item>

            <el-form-item label="Tags">
                <div class="tags-editor">
                    <el-select
                        v-model="selectedTagIds"
                        multiple
                        filterable
                        placeholder="Select tags"
                        style="width: 100%"
                    >
                        <el-option v-for="tag in allTags" :key="tag.id" :label="tag.name" :value="tag.id!" />
                    </el-select>
                    <div class="tags-editor__new">
                        <el-input v-model="newTagInput" placeholder="New tag name" style="flex: 1" @keyup.enter="createAndAddTag" />
                        <el-button @click="createAndAddTag">Add tag</el-button>
                    </div>
                </div>
            </el-form-item>

            <el-form-item label="Codes">
                <div class="codes-editor">
                    <div v-if="codes.length" class="codes-editor__list">
                        <div v-for="code in codes" :key="code.id" class="codes-editor__row">
                            <span class="codes-editor__type">{{ codeTypeLabel(code.codeType) }}</span>
                            <span class="codes-editor__contents">{{ code.contents }}</span>
                            <el-button size="small" @click="openEditDialog(code)">Edit</el-button>
                            <el-button size="small" type="danger" @click="removeCode(code)">Delete</el-button>
                        </div>
                    </div>
                    <div class="codes-editor__add">
                        <el-select v-model="newCode.codeType" style="width: 130px">
                            <el-option
                                v-for="opt in CODE_TYPE_OPTIONS"
                                :key="opt.value"
                                :label="opt.label"
                                :value="opt.value"
                            />
                        </el-select>
                        <el-input v-model="newCode.contents" placeholder="Code contents" style="flex: 1" @keyup.enter="addCode" />
                        <el-button :loading="addingCode" @click="addCode">Add code</el-button>
                    </div>
                </div>
            </el-form-item>

            <el-form-item>
                <el-button type="primary" :loading="saving" @click="save">Save</el-button>
            </el-form-item>
        </el-form>

        <el-dialog v-model="editDialog.visible" title="Edit code" width="420px">
            <el-form label-width="100px">
                <el-form-item label="Type">
                    <el-select v-model="editDialog.codeType" style="width: 100%">
                        <el-option
                            v-for="opt in CODE_TYPE_OPTIONS"
                            :key="opt.value"
                            :label="opt.label"
                            :value="opt.value"
                        />
                    </el-select>
                </el-form-item>
                <el-form-item label="Contents">
                    <el-input v-model="editDialog.contents" @keyup.enter="saveEditCode" />
                </el-form-item>
            </el-form>
            <template #footer>
                <el-button @click="editDialog.visible = false">Cancel</el-button>
                <el-button type="primary" :loading="editSaving" @click="saveEditCode">Save</el-button>
            </template>
        </el-dialog>
    </div>
</template>

<style lang="scss" scoped>
.item-edit {
    max-width: 700px;
    margin: 0 auto;
    padding: 1.5rem;

    &__header {
        display: flex;
        align-items: center;
        gap: 1rem;
        margin-bottom: 1.5rem;

        h2 {
            margin: 0;
        }
    }

    &__card {
        background: var(--el-bg-color);
        border-radius: 8px;
        padding: 1.25rem 1.5rem;
        margin-bottom: 1rem;
    }

    &__form {
        background: var(--el-bg-color);
        border-radius: 8px;
        padding: 1.5rem 1rem 0.5rem;
    }
}

.tags-editor {
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;

    &__new {
        display: flex;
        gap: 0.5rem;
    }
}

.codes-editor {
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 0.5rem;

    &__list {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        border: 1px solid var(--el-border-color);
        border-radius: 4px;
        padding: 0.5rem;
    }

    &__row {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    &__type {
        font-size: 0.75rem;
        font-weight: 600;
        color: var(--el-color-primary);
        background: var(--el-color-primary-light-9);
        border-radius: 4px;
        padding: 2px 6px;
        white-space: nowrap;
    }

    &__contents {
        flex: 1;
        font-family: monospace;
        font-size: 0.875rem;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
    }

    &__add {
        display: flex;
        gap: 0.5rem;
    }
}
</style>
