<script setup lang="ts">
import { ElButton } from 'element-plus';

defineProps<{
    title: string
    buttonText?: string
}>()
defineEmits<{
    btnClicked?: []
}>();
</script>

<template>
    <div class="card-header">
        <div class="card-header__title">
            {{ title }}
        </div>
        <el-button v-if="buttonText" type="primary" plain @click="$emit('btnClicked')">{{ buttonText }}</el-button>
    </div>
</template>

<style lang="scss" scoped>
.card-header {
    display: flex;

    &__title {
        flex-grow: 1;
        display: flex;
        align-items: center;
    }
}
</style>