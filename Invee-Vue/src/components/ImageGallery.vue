<script setup lang="ts">
import { deleteItemImage, deleteStorageImage, type ImageDto } from '@/client';
import { ElImage, ElButton, ElMessage } from 'element-plus';
import { useUserStore } from '@/stores/user';
import SvgIcon from '@jamescoyle/vue-icon';
import { mdiDelete } from '@mdi/js';

const props = defineProps<{
    images: ImageDto[];
    entityType: 'item' | 'storage';
    entityId: number;
    readonly?: boolean;
}>();

const emit = defineEmits<{
    (e: 'deleted', imageId: number): void;
}>();

const userStore = useUserStore();

const onDelete = async (imageId: number) => {
    const fn = props.entityType === 'item' ? deleteItemImage : deleteStorageImage;
    const resp = await fn({ path: { id: props.entityId, imageId } });
    if (resp.error) {
        ElMessage.error('Failed to delete image.');
    } else {
        emit('deleted', imageId);
    }
};
</script>

<template>
    <div v-if="images.length" class="image-gallery">
        <div v-for="img in images" :key="img.id" class="image-gallery__item">
            <el-image
                :src="img.url ?? ''"
                :preview-src-list="images.map(i => i.url ?? '')"
                :initial-index="images.indexOf(img)"
                fit="cover"
                class="image-gallery__thumb"
            />
            <el-button
                v-if="!props.readonly && userStore.loggedIn"
                class="image-gallery__delete"
                type="danger"
                size="small"
                circle
                @click.stop="onDelete(img.id!)"
            >
                <svg-icon type="mdi" :path="mdiDelete" size="14" />
            </el-button>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.image-gallery {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-bottom: 1rem;

    &__item {
        position: relative;
        width: 100px;
        height: 100px;
        flex-shrink: 0;
    }

    &__thumb {
        width: 100%;
        height: 100%;
        border-radius: 6px;
        overflow: hidden;
        cursor: pointer;
    }

    &__delete {
        position: absolute;
        top: 4px;
        right: 4px;
        opacity: 0;
        transition: opacity 0.15s;
    }

    &__item:hover &__delete {
        opacity: 1;
    }
}
</style>
