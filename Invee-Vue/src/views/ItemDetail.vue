<script setup lang="ts">
import {
    borrowItem,
    borrowReservation,
    cancelReservation,
    getItem,
    getItemBySlug,
    reserveItem,
    returnItem,
    updateItem,
    type BorrowingDto,
    type ImageDto,
    type ItemResponse,
} from '@/client';
import {
    ElButton,
    ElDatePicker,
    ElInput,
    ElMessage,
    ElSwitch,
} from 'element-plus';
import { computed, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useUserStore } from '@/stores/user';
import { slugId } from '@/utils';
import ImageGallery from '@/components/ImageGallery.vue';

const route = useRoute();
const router = useRouter();
const userStore = useUserStore();
const rawId = route.params.id as string;

const itemResp = !isNaN(+rawId)
    ? await getItem({ path: { id: +rawId } })
    : await getItemBySlug({ path: { slug: rawId } });
const item = ref<ItemResponse>(itemResp.data as ItemResponse);
const itemId = item.value.id!;
const images = ref<ImageDto[]>(item.value.images ?? []);

// Borrowing status constants
const STATUS_CANCELLED = 0;
const STATUS_RESERVED = 1;
const STATUS_BORROWED = 2;
const STATUS_RETURNED = 3;

const activeBorrowing = computed<BorrowingDto | null>(() => {
    return item.value.borrowings?.find(
        b => b.status === STATUS_RESERVED || b.status === STATUS_BORROWED
    ) ?? null;
});

const borrowingStatusLabel = computed(() => {
    const b = activeBorrowing.value;
    if (!b) return null;
    if (b.status === STATUS_RESERVED) return 'Reserved';
    if (b.status === STATUS_BORROWED) return 'Borrowed';
    return null;
});

const pastBorrowings = computed(() =>
    item.value.borrowings?.filter(
        b => b.status === STATUS_RETURNED || b.status === STATUS_CANCELLED
    ).sort((a, b) => {
        const da = a.update ? new Date(a.update).getTime() : 0;
        const db2 = b.update ? new Date(b.update).getTime() : 0;
        return db2 - da;
    }) ?? []
);

// Quantity quick-change
const quantityLoading = ref(false);

const saveQuantity = async (newQuantity: number | null) => {
    quantityLoading.value = true;
    try {
        const resp = await updateItem({
            path: { id: itemId },
            body: {
                id: itemId,
                name: item.value.name,
                slug: item.value.slug ?? null,
                note: item.value.note ?? null,
                categoryId: item.value.category.id!,
                storageId: item.value.storage.id!,
                quantityType: item.value.quantityType ?? 0,
                quantity: newQuantity,
                broken: item.value.broken ?? false,
                expiresAt: item.value.expiresAt ?? null,
            },
        });
        if (resp.error) {
            ElMessage.error('Failed to update quantity.');
        } else {
            // Refresh item data to keep in sync
            const refreshed = await getItem({ path: { id: itemId } });
            if (refreshed.data) item.value = refreshed.data;
        }
    } finally {
        quantityLoading.value = false;
    }
};

const onPreciseAdjust = (delta: number) => {
    const current = item.value.quantity ?? 0;
    const next = Math.max(0, current + delta);
    saveQuantity(next);
};

const onLevelChange = (level: number) => {
    saveQuantity(level);
};

// Reserve form
const showReserveForm = ref(false);
const reserveForm = ref({
    borrowerName: '',
    expectedStart: null as Date | null,
    expectedReturn: null as Date | null,
    comment: '',
    incomplete: false,
});
const reserveLoading = ref(false);

const submitReserve = async () => {
    if (!reserveForm.value.borrowerName.trim()) {
        ElMessage.warning('Borrower name is required.');
        return;
    }
    if (!reserveForm.value.expectedStart || !reserveForm.value.expectedReturn) {
        ElMessage.warning('Start and return dates are required.');
        return;
    }
    reserveLoading.value = true;
    try {
        const resp = await reserveItem({
            path: { id: itemId },
            body: {
                id: itemId,
                borrowerName: reserveForm.value.borrowerName.trim(),
                expectedStart: reserveForm.value.expectedStart.toISOString(),
                expectedReturn: reserveForm.value.expectedReturn.toISOString(),
                comment: reserveForm.value.comment || null,
                incomplete: reserveForm.value.incomplete,
            },
        });
        if (resp.error) {
            ElMessage.error('Failed to reserve item.');
        } else {
            ElMessage.success('Item reserved.');
            showReserveForm.value = false;
            reserveForm.value = { borrowerName: '', expectedStart: null, expectedReturn: null, comment: '', incomplete: false };
            const refreshed = await getItem({ path: { id: itemId } });
            if (refreshed.data) item.value = refreshed.data;
        }
    } finally {
        reserveLoading.value = false;
    }
};

// Borrow form
const showBorrowForm = ref(false);
const borrowForm = ref({
    borrowerName: '',
    expectedReturn: null as Date | null,
    comment: '',
    incomplete: false,
});
const borrowLoading = ref(false);

const submitBorrow = async () => {
    if (!borrowForm.value.borrowerName.trim()) {
        ElMessage.warning('Borrower name is required.');
        return;
    }
    if (!borrowForm.value.expectedReturn) {
        ElMessage.warning('Expected return date is required.');
        return;
    }
    borrowLoading.value = true;
    try {
        const resp = await borrowItem({
            path: { id: itemId },
            body: {
                id: itemId,
                borrowerName: borrowForm.value.borrowerName.trim(),
                expectedReturn: borrowForm.value.expectedReturn.toISOString(),
                comment: borrowForm.value.comment || null,
                incomplete: borrowForm.value.incomplete,
            },
        });
        if (resp.error) {
            ElMessage.error('Failed to borrow item.');
        } else {
            ElMessage.success('Item borrowed.');
            showBorrowForm.value = false;
            borrowForm.value = { borrowerName: '', expectedReturn: null, comment: '', incomplete: false };
            const refreshed = await getItem({ path: { id: itemId } });
            if (refreshed.data) item.value = refreshed.data;
        }
    } finally {
        borrowLoading.value = false;
    }
};

// Borrow reservation → convert to borrow
const convertLoading = ref(false);
const onConvertToBorrow = async () => {
    convertLoading.value = true;
    try {
        const resp = await borrowReservation({ path: { id: itemId } });
        if (resp.error) {
            ElMessage.error('Failed to convert reservation.');
        } else {
            ElMessage.success('Reservation converted to borrow.');
            const refreshed = await getItem({ path: { id: itemId } });
            if (refreshed.data) item.value = refreshed.data;
        }
    } finally {
        convertLoading.value = false;
    }
};

// Cancel reservation
const cancelLoading = ref(false);
const onCancelReservation = async () => {
    cancelLoading.value = true;
    try {
        const resp = await cancelReservation({ path: { id: itemId } });
        if (resp.error) {
            ElMessage.error('Failed to cancel reservation.');
        } else {
            ElMessage.success('Reservation cancelled.');
            const refreshed = await getItem({ path: { id: itemId } });
            if (refreshed.data) item.value = refreshed.data;
        }
    } finally {
        cancelLoading.value = false;
    }
};

// Return
const returnLoading = ref(false);
const onReturn = async () => {
    returnLoading.value = true;
    try {
        const resp = await returnItem({ path: { id: itemId } });
        if (resp.error) {
            ElMessage.error('Failed to return item.');
        } else {
            ElMessage.success('Item returned.');
            const refreshed = await getItem({ path: { id: itemId } });
            if (refreshed.data) item.value = refreshed.data;
        }
    } finally {
        returnLoading.value = false;
    }
};

const formatDate = (iso: string | null | undefined) => {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
};

const borrowingStatusText = (status: number | undefined) => {
    switch (status) {
        case STATUS_RESERVED: return 'Reserved';
        case STATUS_BORROWED: return 'Borrowed';
        case STATUS_RETURNED: return 'Returned';
        case STATUS_CANCELLED: return 'Cancelled';
        default: return 'Unknown';
    }
};

const levelLabels: Record<number, string> = { 0: 'None', 1: 'Low', 2: 'Good' };

const inNDays = (ndays: number): Date => {
    let date = new Date();
    date.setDate(date.getDate() + ndays);
    return date;
}
const expiryWarning = inNDays(7);
</script>

<template>
    <div class="item-detail">
        <!-- Header -->
        <div class="item-detail__header">
            <el-button @click="router.back()" class="back-btn">← Back</el-button>
            <div class="header-main">
                <div class="header-title">
                    <h2>{{ item.name }}</h2>
                    <div class="badges">
                        <span v-if="activeBorrowing?.status === STATUS_BORROWED"
                            class="badge badge--borrowed">Borrowed</span>
                        <span v-if="activeBorrowing?.status === STATUS_RESERVED"
                            class="badge badge--reserved">Reserved</span>
                        <span v-if="item.broken" class="badge badge--broken">Broken</span>
                    </div>
                </div>
                <div v-if="item.tags?.length" class="tags">
                    <span v-for="tag in item.tags" :key="tag" class="tag">{{ tag }}</span>
                </div>
            </div>
            <el-button v-if="userStore.loggedIn" type="primary" plain
                @click="router.push({ name: 'item-edit', params: { id: itemId } })">
                Edit
            </el-button>
        </div>

        <!-- Info section -->
        <div v-if="images.length" class="item-detail__card">
            <ImageGallery :images="images" entity-type="item" :entity-id="itemId" :readonly="true" />
        </div>

        <!-- Info section -->
        <div class="item-detail__card">
            <div class="info__grid">
                <div class="info__row">
                    <span class="info__label">Category</span>
                    <router-link :to="{ name: 'category', params: slugId(item.category) }" class="info__link">
                        {{ item.category.name }}
                    </router-link>
                </div>
                <div v-if="userStore.loggedIn" class="info__row">
                    <span class="info__label">Storage</span>
                    <router-link :to="{ name: 'storage', params: slugId(item.storage) }" class="info__link">
                        {{ item.storage.name }}
                    </router-link>
                </div>
                <div v-if="item.note" class="info__row info__row--note">
                    <span class="info__label">Note</span>
                    <span class="info__value note-text">{{ item.note }}</span>
                </div>
                <div class="info__row">
                    <span class="info__label">Added</span>
                    <span class="info__value">{{ item.addedAt ? formatDate(item.addedAt) : '—' }}</span>
                </div>
                <div v-if="item.expiresAt" class="info__row">
                    <span class="info__label">Expires</span>
                    <span
                        :class="['info__value', new Date(item.expiresAt) < new Date() ? 'expiry--expired' : (new Date(item.expiresAt) < expiryWarning ? 'expiry--warning' : 'expiry--ok')]">
                        {{ formatDate(item.expiresAt) }}
                    </span>
                </div>
            </div>
        </div>

        <!-- Quantity section -->
        <div v-if="item.quantityType !== 0" class="item-detail__card">
            <h3 class="section-title">Quantity</h3>

            <!-- Display only (guests) -->
            <div v-if="!userStore.loggedIn" class="quantity-display">
                <span v-if="item.quantityType === 1">{{ levelLabels[item.level ?? 0] }}</span>
                <span v-else-if="item.quantityType === 2">× {{ item.quantity ?? 0 }}</span>
            </div>

            <!-- Precise quantity controls (auth) -->
            <div v-else-if="item.quantityType === 2" class="quantity-controls">
                <el-button :disabled="(item.quantity ?? 0) <= 0 || quantityLoading" @click="onPreciseAdjust(-1)"
                    circle>−</el-button>
                <span class="quantity-value">× {{ item.quantity ?? 0 }}</span>
                <el-button :disabled="quantityLoading" @click="onPreciseAdjust(1)" circle>+</el-button>
            </div>

            <!-- Level controls (auth) -->
            <div v-else-if="item.quantityType === 1" class="level-controls">
                <el-button v-for="(label, val) in levelLabels" :key="val"
                    :type="item.level === Number(val) ? 'primary' : 'default'" :disabled="quantityLoading"
                    @click="onLevelChange(Number(val))">{{ label }}</el-button>
            </div>
        </div>

        <!-- Borrow status section (auth only) -->
        <div v-if="userStore.loggedIn" class="item-detail__card">
            <h3 class="section-title">Borrow status</h3>

            <!-- No active borrowing -->
            <template v-if="!activeBorrowing">
                <p class="borrow-available">Available</p>
                <div class="borrow-actions">
                    <el-button @click="showReserveForm = !showReserveForm; showBorrowForm = false">
                        {{ showReserveForm ? 'Cancel' : 'Reserve…' }}
                    </el-button>
                    <el-button @click="showBorrowForm = !showBorrowForm; showReserveForm = false">
                        {{ showBorrowForm ? 'Cancel' : 'Borrow…' }}
                    </el-button>
                </div>

                <!-- Reserve form -->
                <div v-if="showReserveForm" class="inline-form">
                    <h4>Reserve item</h4>
                    <div class="form-field">
                        <label>Borrower name</label>
                        <el-input v-model="reserveForm.borrowerName" placeholder="Name" />
                    </div>
                    <div class="form-field">
                        <label>Expected start</label>
                        <el-date-picker v-model="reserveForm.expectedStart" type="datetime"
                            placeholder="Pick date & time" style="width: 100%" />
                    </div>
                    <div class="form-field">
                        <label>Expected return</label>
                        <el-date-picker v-model="reserveForm.expectedReturn" type="datetime"
                            placeholder="Pick date & time" style="width: 100%" />
                    </div>
                    <div class="form-field">
                        <label>Comment</label>
                        <el-input v-model="reserveForm.comment" type="textarea" :rows="2" placeholder="Optional" />
                    </div>
                    <div class="form-field form-field--inline">
                        <label>Incomplete</label>
                        <el-switch v-model="reserveForm.incomplete" />
                    </div>
                    <el-button type="primary" :loading="reserveLoading" @click="submitReserve">Confirm
                        Reservation</el-button>
                </div>

                <!-- Borrow form -->
                <div v-if="showBorrowForm" class="inline-form">
                    <h4>Borrow item</h4>
                    <div class="form-field">
                        <label>Borrower name</label>
                        <el-input v-model="borrowForm.borrowerName" placeholder="Name" />
                    </div>
                    <div class="form-field">
                        <label>Expected return</label>
                        <el-date-picker v-model="borrowForm.expectedReturn" type="datetime"
                            placeholder="Pick date & time" style="width: 100%" />
                    </div>
                    <div class="form-field">
                        <label>Comment</label>
                        <el-input v-model="borrowForm.comment" type="textarea" :rows="2" placeholder="Optional" />
                    </div>
                    <div class="form-field form-field--inline">
                        <label>Incomplete</label>
                        <el-switch v-model="borrowForm.incomplete" />
                    </div>
                    <el-button type="primary" :loading="borrowLoading" @click="submitBorrow">Confirm Borrow</el-button>
                </div>
            </template>

            <!-- Reserved -->
            <template v-else-if="activeBorrowing.status === STATUS_RESERVED">
                <div class="borrow-detail">
                    <span class="badge badge--reserved">Reserved</span>
                    <div class="borrow-info">
                        <span><strong>Borrower:</strong> {{ activeBorrowing.borrower }}</span>
                        <span><strong>Start:</strong> {{ formatDate(activeBorrowing.start) }}</span>
                        <span><strong>Return by:</strong> {{ formatDate(activeBorrowing.end) }}</span>
                        <span v-if="activeBorrowing.comment"><strong>Comment:</strong> {{ activeBorrowing.comment
                            }}</span>
                        <span v-if="activeBorrowing.incomplete" class="incomplete-note">⚠ Incomplete</span>
                    </div>
                </div>
                <div class="borrow-actions">
                    <el-button type="primary" :loading="convertLoading" @click="onConvertToBorrow">Convert to
                        Borrow</el-button>
                    <el-button type="danger" plain :loading="cancelLoading" @click="onCancelReservation">Cancel
                        Reservation</el-button>
                </div>
            </template>

            <!-- Borrowed -->
            <template v-else-if="activeBorrowing.status === STATUS_BORROWED">
                <div class="borrow-detail">
                    <span class="badge badge--borrowed">Borrowed</span>
                    <div class="borrow-info">
                        <span><strong>Borrower:</strong> {{ activeBorrowing.borrower }}</span>
                        <span><strong>Since:</strong> {{ formatDate(activeBorrowing.start) }}</span>
                        <span><strong>Return by:</strong> {{ formatDate(activeBorrowing.end) }}</span>
                        <span v-if="activeBorrowing.comment"><strong>Comment:</strong> {{ activeBorrowing.comment
                            }}</span>
                        <span v-if="activeBorrowing.incomplete" class="incomplete-note">⚠ Incomplete</span>
                    </div>
                </div>
                <div class="borrow-actions">
                    <el-button type="success" :loading="returnLoading" @click="onReturn">Mark as Returned</el-button>
                </div>
            </template>
        </div>

        <!-- Borrowing history (public) -->
        <div v-if="pastBorrowings.length" class="item-detail__card">
            <h3 class="section-title">Borrowing history</h3>
            <table class="history-table">
                <thead>
                    <tr>
                        <th>Borrower</th>
                        <th>Start</th>
                        <th>End</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(b, i) in pastBorrowings" :key="i">
                        <td>{{ b.borrower }}</td>
                        <td>{{ formatDate(b.start) }}</td>
                        <td>{{ formatDate(b.end) }}</td>
                        <td>
                            <span
                                :class="['badge', b.status === STATUS_RETURNED ? 'badge--returned' : 'badge--cancelled']">
                                {{ borrowingStatusText(b.status) }}
                            </span>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<style lang="scss" scoped>
.item-detail {
    max-width: 700px;
    margin: 0 auto;
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;

    &__header {
        display: flex;
        align-items: flex-start;
        gap: 1rem;

        .back-btn {
            flex-shrink: 0;
            margin-top: 0.2rem;
        }

        .header-main {
            flex-grow: 1;

            .header-title {
                display: flex;
                align-items: center;
                gap: 0.75rem;
                flex-wrap: wrap;

                h2 {
                    margin: 0;
                    font-size: 1.5rem;
                }
            }

            .tags {
                display: flex;
                flex-wrap: wrap;
                gap: 0.375rem;
                margin-top: 0.4rem;
            }
        }
    }

    &__card {
        background: var(--el-bg-color);
        border-radius: 8px;
        padding: 1.25rem 1.5rem;
    }
}

.section-title {
    margin: 0 0 0.75rem;
    font-size: 1rem;
    color: var(--el-text-color-secondary);
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.04em;
}

// Tags
.tag {
    font-size: 0.75rem;
    padding: 0.125rem 0.5rem;
    border-radius: 999px;
    background: var(--el-fill-color);
    color: var(--el-text-color-regular);
    border: 1px solid var(--el-border-color);
}

// Badges
.badges {
    display: flex;
    gap: 0.25rem;
    flex-wrap: wrap;
}

.badge {
    font-size: 0.75rem;
    padding: 0.125rem 0.5rem;
    border-radius: 0.25rem;
    font-weight: 500;

    &--borrowed {
        background: var(--el-color-warning-light-7);
        color: var(--el-color-warning-dark-2);
    }

    &--reserved {
        background: var(--el-color-primary-light-7);
        color: var(--el-color-primary-dark-2);
    }

    &--broken {
        background: var(--el-color-danger-light-7);
        color: var(--el-color-danger-dark-2);
    }

    &--returned {
        background: var(--el-color-success-light-7);
        color: var(--el-color-success-dark-2);
    }

    &--cancelled {
        background: var(--el-fill-color);
        color: var(--el-text-color-secondary);
    }
}

.info {
    &__grid {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }

    &__row {
        display: flex;
        align-items: baseline;
        gap: 0.75rem;

        &--note {
            align-items: flex-start;
        }
    }

    &__label {
        min-width: 80px;
        font-size: 0.8rem;
        text-transform: uppercase;
        letter-spacing: 0.04em;
        color: var(--el-text-color-secondary);
        font-weight: 600;
        flex-shrink: 0;
    }

    &__link {
        color: var(--el-color-primary);
        text-decoration: none;

        &:hover {
            text-decoration: underline;
        }
    }
}


.note-text {
    white-space: pre-wrap;
    line-height: 1.5;
}

.expiry {
    &--ok {
        color: var(--el-color-success-dark-2);
    }

    &--expired {
        color: var(--el-color-danger);
        font-weight: 800;
    }

    &--warning {
        color: var(--el-color-warning-light-7);
        font-weight: 700;
    }
}

// Quantity
.quantity-display {
    font-size: 1.1rem;
    font-weight: 500;
}

.quantity-controls {
    display: flex;
    align-items: center;
    gap: 1rem;
}

.quantity-value {
    font-size: 1.25rem;
    font-weight: 600;
    min-width: 60px;
    text-align: center;
}

.level-controls {
    display: flex;
    gap: 0.5rem;
}

// Borrow section
.borrow-available {
    color: var(--el-color-success);
    font-weight: 500;
    margin: 0 0 0.75rem;
}

.borrow-actions {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
    margin-top: 0.75rem;
}

.borrow-detail {
    display: flex;
    align-items: flex-start;
    gap: 0.75rem;
    flex-wrap: wrap;

    .borrow-info {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
        font-size: 0.9rem;
    }
}

.incomplete-note {
    color: var(--el-color-warning-dark-2);
    font-size: 0.85rem;
}

// Inline form
.inline-form {
    margin-top: 1rem;
    padding: 1rem;
    border: 1px solid var(--el-border-color);
    border-radius: 6px;
    display: flex;
    flex-direction: column;
    gap: 0.75rem;

    h4 {
        margin: 0 0 0.25rem;
        font-size: 0.95rem;
    }
}

.form-field {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;

    label {
        font-size: 0.8rem;
        color: var(--el-text-color-secondary);
        font-weight: 500;
    }

    &--inline {
        flex-direction: row;
        align-items: center;
        gap: 0.5rem;

        label {
            font-size: 0.9rem;
        }
    }
}

// History table
.history-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 0.875rem;

    th,
    td {
        text-align: left;
        padding: 0.5rem 0.75rem;
    }

    th {
        color: var(--el-text-color-secondary);
        font-size: 0.75rem;
        text-transform: uppercase;
        letter-spacing: 0.04em;
        border-bottom: 1px solid var(--el-border-color);
    }

    td {
        border-bottom: 1px solid var(--el-fill-color);
    }

    tr:last-child td {
        border-bottom: none;
    }
}
</style>
