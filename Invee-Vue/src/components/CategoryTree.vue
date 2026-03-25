<script setup lang="ts">
import { deleteCategory, type CategoryTreeResponse } from '@/client';
import { ElButton } from 'element-plus';
import { Plus, Delete } from '@element-plus/icons-vue';

defineProps<{
    category: CategoryTreeResponse[]
}>()
const emit = defineEmits<{
    addChild: [parentId: number],
    removed: [id: number]
}>();

const remove = async (id: number) => {
    await deleteCategory({ path: { id: id } });
    emit('removed', id);
}
</script>

<template>
    <ul>
        <li v-for="c in category">
            <div class="item">
                <div class="item__icon">

                </div>
                <div class="item__name">
                    {{ c.name }}
                </div>
                <div class="item__actions">
                    <el-button :icon="Plus" @click="$emit('addChild', c.id!)"></el-button>
                    <el-button :icon="Delete" @click="remove(c.id!)" plain type="danger"></el-button>
                </div>
            </div>
            <div class="subitems" v-if="c.children && c.children.length">
                <CategoryTree :category="c.children!" @add-child="(parentId) => $emit('addChild', parentId)" @removed="(id) => $emit('removed', id)">
                </CategoryTree>
            </div>
        </li>
    </ul>
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