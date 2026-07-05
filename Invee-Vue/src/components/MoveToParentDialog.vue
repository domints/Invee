<script setup lang="ts">
import { buildMoveTargetOptions, type TreeNode } from '@/utils/tree';
import { ElButton, ElDialog, ElForm, ElFormItem, ElSelect, ElOption } from 'element-plus';
import { computed, ref, watch } from 'vue';

const ROOT_VALUE = 'root';

const props = defineProps<{
    tree: TreeNode[]
    nodeId: number | null
    nodeName: string
}>()

const emit = defineEmits<{
    confirm: [parentId: number | null]
}>()

const visible = defineModel<boolean>('visible', { default: false })
const selectedDestination = ref<string | number>(ROOT_VALUE)

const destinationOptions = computed(() => {
    if (props.nodeId == null)
        return [{ value: ROOT_VALUE, label: 'Root level' }];

    return buildMoveTargetOptions(props.tree, props.nodeId).map(option => ({
        value: option.value ?? ROOT_VALUE,
        label: option.label
    }));
})

watch(visible, (isVisible) => {
    if (isVisible)
        selectedDestination.value = ROOT_VALUE;
})

const save = () => {
    visible.value = false;
    const parentId = selectedDestination.value === ROOT_VALUE
        ? null
        : selectedDestination.value as number;
    emit('confirm', parentId);
}
</script>

<template>
    <el-dialog v-model="visible" :title="`Move ${nodeName}`">
        <el-form>
            <el-form-item label="Move to">
                <el-select v-model="selectedDestination" placeholder="Select destination">
                    <el-option
                        v-for="option in destinationOptions"
                        :key="String(option.value)"
                        :label="option.label"
                        :value="option.value"
                    />
                </el-select>
            </el-form-item>
        </el-form>
        <template #footer>
            <div class="dialog-footer">
                <el-button @click="visible = false">Cancel</el-button>
                <el-button type="primary" @click="save()">
                    Confirm
                </el-button>
            </div>
        </template>
    </el-dialog>
</template>
