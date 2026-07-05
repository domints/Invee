<script setup lang="ts">
import { uploadItemImage, uploadStorageImage, type ImageDto } from '@/client';
import { ElMessage } from 'element-plus';
import { ref } from 'vue';
import SvgIcon from '@jamescoyle/vue-icon';
import { mdiImagePlus } from '@mdi/js';

const props = defineProps<{
    entityType: 'item' | 'storage';
    entityId: number;
}>();

const emit = defineEmits<{
    (e: 'uploaded', imageId: number): void;
}>();

const loading = ref(false);
const fileInput = ref<HTMLInputElement | null>(null);

const triggerPick = () => {
    fileInput.value?.click();
};

const onFileChange = async (event: Event) => {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    loading.value = true;
    try {
        const fn = props.entityType === 'item' ? uploadItemImage : uploadStorageImage;
        const resp = await fn({
            path: { id: props.entityId },
            body: { file },
        });
        if (resp.error || !resp.data) {
            ElMessage.error('Upload failed.');
        } else {
            emit('uploaded', resp.data as number);
        }
    } finally {
        loading.value = false;
        input.value = '';
    }
};
</script>

<template>
    <div class="image-upload">
        <input
            ref="fileInput"
            type="file"
            accept="image/*"
            style="display: none"
            @change="onFileChange"
        />
        <button class="image-upload__btn" :disabled="loading" @click="triggerPick">
            <svg-icon type="mdi" :path="mdiImagePlus" size="18" />
            <span>{{ loading ? 'Uploading…' : 'Add photo' }}</span>
        </button>
    </div>
</template>

<style lang="scss" scoped>
.image-upload {
    &__btn {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        padding: 0.3rem 0.75rem;
        border: 1px dashed var(--el-border-color);
        border-radius: 6px;
        background: transparent;
        color: var(--el-text-color-secondary);
        font-size: 0.875rem;
        cursor: pointer;
        transition: border-color 0.15s, color 0.15s;

        &:hover:not(:disabled) {
            border-color: var(--el-color-primary);
            color: var(--el-color-primary);
        }

        &:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
    }
}
</style>
