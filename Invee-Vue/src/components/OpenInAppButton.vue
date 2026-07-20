<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { ElButton } from 'element-plus';
import SvgIcon from '@jamescoyle/vue-icon';
import { mdiCellphoneLink } from '@mdi/js';
import { getShortLinkConfig, isMobileDevice, buildAppLink } from '@/shortLinks';

const props = defineProps<{
    kind: 'item' | 'storage';
    slug?: string | null;
}>();

const appLink = ref<string | null>(null);

onMounted(async () => {
    if (!props.slug || !isMobileDevice()) return;
    const config = await getShortLinkConfig();
    if (!config || !config.shortHost) return;
    appLink.value = buildAppLink(config, props.kind, props.slug);
});
</script>

<template>
    <a v-if="appLink" :href="appLink" class="open-in-app">
        <el-button type="primary" plain size="small">
            <svg-icon type="mdi" size="0.9rem" :path="mdiCellphoneLink" class="open-in-app__icon"></svg-icon>
            Open in app
        </el-button>
    </a>
</template>

<style lang="scss" scoped>
.open-in-app {
    text-decoration: none;

    &__icon {
        margin-right: 0.35rem;
    }
}
</style>
