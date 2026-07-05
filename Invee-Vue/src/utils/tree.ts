export interface TreeNode {
    id?: number;
    name: string;
    children?: TreeNode[];
}

export function collectDescendantIds(node: TreeNode): Set<number> {
    const ids = new Set<number>();
    if (node.id != null)
        ids.add(node.id);

    for (const child of node.children ?? []) {
        for (const id of collectDescendantIds(child))
            ids.add(id);
    }

    return ids;
}

export function findTreeNode(nodes: TreeNode[], id: number): TreeNode | undefined {
    for (const node of nodes) {
        if (node.id === id)
            return node;

        const found = findTreeNode(node.children ?? [], id);
        if (found)
            return found;
    }

    return undefined;
}

export interface TreeSelectOption {
    value: number | null;
    label: string;
}

export function flattenTreeForSelect(
    nodes: TreeNode[],
    excludeIds: Set<number>,
    depth = 0
): TreeSelectOption[] {
    const options: TreeSelectOption[] = [];

    for (const node of nodes) {
        if (node.id == null || excludeIds.has(node.id)) {
            if (node.children?.length)
                options.push(...flattenTreeForSelect(node.children, excludeIds, depth));
            continue;
        }

        const prefix = depth > 0 ? `${'—'.repeat(depth)} ` : '';
        options.push({ value: node.id, label: `${prefix}${node.name}` });
        options.push(...flattenTreeForSelect(node.children ?? [], excludeIds, depth + 1));
    }

    return options;
}

export function buildMoveTargetOptions(tree: TreeNode[], nodeId: number): TreeSelectOption[] {
    const node = findTreeNode(tree, nodeId);
    const excludeIds = node ? collectDescendantIds(node) : new Set([nodeId]);

    return [
        { value: null, label: 'Root level' },
        ...flattenTreeForSelect(tree, excludeIds)
    ];
}
