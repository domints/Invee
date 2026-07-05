export const slugify = (...args: (string | number)[]): string => {
    const value = args.join(' ')

    return value
        .normalize('NFD') // split an accented letter in the base letter and the acent
        .replace(/[\u0300-\u036f]/g, '') // remove all previously split accents
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9 ]/g, '') // remove all chars not letters, numbers and spaces (to be replaced)
        .replace(/\s+/g, '-') // separator
}

export const slugParentId = (item: { parentId?: number | null, parentSlug?: string | null } | undefined | null) =>
{
    return {
        id: item?.parentSlug ?? item?.parentId
    }
}

export const slugId = (item: { id?: number | null, slug?: string | null } | undefined | null) =>
    {
        return {
            id: item?.slug ?? item?.id
        }
    }

const quantityLevelLabels: Record<number, string> = {
    0: 'None',
    1: 'Low',
    2: 'Good',
}

export function formatItemQuantity(item: { quantityType?: number, quantity?: number | null, level?: number | null }): string | null {
    if (item.quantityType === 2 && item.quantity != null) {
        return `× ${item.quantity}`
    }
    if (item.quantityType === 1 && item.level != null) {
        return quantityLevelLabels[item.level] ?? null
    }
    return null
}