<script setup lang="ts">
import { type CategoryTreeResponse, getCategoryTree, getAllItems, lookupItemByCode, getExpiringItems, type ItemListEntry } from '@/client';
import { ref, computed } from 'vue';
import { ElInput } from 'element-plus';
import { watchDebounced, onClickOutside } from '@vueuse/core';
import { useRouter } from 'vue-router';
import { slugId, isZeroAmount } from '@/utils';
import SvgIcon from '@jamescoyle/vue-icon';
import { mdiFolderOutline, mdiCubeOutline, mdiChevronRight, mdiAlertCircleOutline } from '@mdi/js';

const router = useRouter();

const input = ref('');
const searchResults = ref<ItemListEntry[]>([]);
const searchLoading = ref(false);
const searchOpen = ref(false);
const searchWrapper = ref<HTMLElement | null>(null);

watchDebounced(
  input,
  async (val) => {
    if (val.length < 3) {
      searchResults.value = [];
      searchOpen.value = false;
      return;
    }
    searchLoading.value = true;

    const [codeRes, itemsRes] = await Promise.allSettled([
      lookupItemByCode({ query: { Contents: val } }),
      getAllItems({ query: { Search: val } }),
    ]);

    searchLoading.value = false;

    if (codeRes.status === 'fulfilled' && codeRes.value.data) {
      navigateToItem(codeRes.value.data);
      return;
    }

    searchResults.value = (itemsRes.status === 'fulfilled' ? itemsRes.value.data ?? [] : []).slice(0, 5);
    searchOpen.value = searchResults.value.length > 0;
  },
  { debounce: 300 }
);

onClickOutside(searchWrapper, () => {
  searchOpen.value = false;
});

const navigateToItem = (id: number) => {
  searchOpen.value = false;
  input.value = '';
  router.push({ name: 'item', params: { id } });
};

const formatExpiryDate = (dateStr: string | null | undefined): string => {
  if (!dateStr) return '';
  const date = new Date(dateStr);
  const now = new Date();
  const diffMs = date.getTime() - now.getTime();
  const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
  if (diffDays < 0) return `Expired ${Math.abs(diffDays)}d ago`;
  if (diffDays === 0) return 'Expires today';
  if (diffDays === 1) return 'Expires tomorrow';
  return `Expires in ${diffDays}d`;
};

const isExpired = (dateStr: string | null | undefined): boolean => {
  if (!dateStr) return false;
  return new Date(dateStr) < new Date();
};

const expiringItems = ref<ItemListEntry[]>([]);
const refreshExpiring = async () => {
  expiringItems.value = (await getExpiringItems()).data ?? [];
};
const visibleExpiringItems = computed(() => expiringItems.value.filter(i => !isZeroAmount(i)));

const categoryTree = ref<CategoryTreeResponse[]>();
const refreshCategories = async () => {
  categoryTree.value = (await getCategoryTree()).data;
};
await Promise.all([refreshCategories(), refreshExpiring()]);
</script>

<template>
  <div class="container">
    <div class="storage-header">
      <div class="storage-header__name">
        <h2>Home</h2>
      </div>
    </div>

    <div class="searchBox" ref="searchWrapper">
      <div class="searchBox__label">Search items:</div>
      <div class="searchBox__input-wrap">
        <el-input
          v-model="input"
          placeholder="Search by name, tag, or barcode…"
          :loading="searchLoading"
          clearable
          @clear="searchOpen = false"
        />
        <div v-if="searchOpen" class="searchBox__dropdown">
          <router-link
            v-for="item in searchResults"
            :key="item.id"
            :to="{ name: 'item', params: { id: item.id } }"
            class="searchBox__result"
            @click="searchOpen = false; input = ''"
          >
            <SvgIcon type="mdi" size="1.25rem" :path="mdiCubeOutline" class="result-icon" />
            <span class="result-name">{{ item.name }}</span>
            <span v-if="item.borrowed" class="badge badge--borrowed">Borrowed</span>
            <span v-if="item.broken" class="badge badge--broken">Broken</span>
            <SvgIcon type="mdi" size="1rem" :path="mdiChevronRight" class="result-arrow" />
          </router-link>
        </div>
      </div>
    </div>

    <div v-if="visibleExpiringItems.length > 0" class="expiringSection">
      <div class="expiringSection__header">
        <SvgIcon type="mdi" size="1.25rem" :path="mdiAlertCircleOutline" class="expiringSection__icon" />
        <h3 class="expiringSection__title">Expiring Soon</h3>
      </div>
      <div class="expiringList">
        <router-link
          v-for="item in visibleExpiringItems"
          :key="item.id"
          :to="{ name: 'item', params: { id: item.id } }"
          class="expiringCard"
          :class="{ 'expiringCard--expired': isExpired(item.expiresAt) }"
        >
          <SvgIcon type="mdi" size="1.25rem" :path="mdiCubeOutline" class="expiringCard__icon" />
          <span class="expiringCard__name">{{ item.name }}</span>
          <span class="expiringCard__date" :class="{ 'expiringCard__date--expired': isExpired(item.expiresAt) }">
            {{ formatExpiryDate(item.expiresAt) }}
          </span>
          <span v-if="item.borrowed" class="badge badge--borrowed">Borrowed</span>
          <span v-if="item.broken" class="badge badge--broken">Broken</span>
          <SvgIcon type="mdi" size="1rem" :path="mdiChevronRight" class="expiringCard__arrow" />
        </router-link>
      </div>
    </div>

    <div class="categoryList">
      <router-link
        v-for="category in categoryTree"
        :key="category.id"
        :to="{ name: 'category', params: slugId(category) }"
        class="categoryCard"
      >
        <SvgIcon type="mdi" size="1.75rem" :path="mdiFolderOutline" class="categoryCard__icon" />
        <span class="categoryCard__name">{{ category.name }}</span>
        <SvgIcon type="mdi" size="1rem" :path="mdiChevronRight" class="categoryCard__arrow" />
      </router-link>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.storage-header {
  display: flex;
  margin-bottom: 1.5em;

  &__name {
    flex-grow: 1;
    display: flex;
    justify-content: center;
  }
}

/* ── Search box ── */
.searchBox {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 2rem;

  &__label {
    white-space: nowrap;
    color: var(--el-text-color-regular);
    font-size: 0.9rem;
  }

  &__input-wrap {
    position: relative;
    flex: 1;
    max-width: 480px;
  }

  &__dropdown {
    position: absolute;
    top: calc(100% + 4px);
    left: 0;
    right: 0;
    z-index: 1000;
    background: var(--el-bg-color-overlay);
    border: 1px solid var(--el-border-color-light);
    border-radius: var(--el-border-radius-base);
    box-shadow: var(--el-box-shadow-light);
    overflow: hidden;
  }

  &__result {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.55rem 0.75rem;
    text-decoration: none;
    color: var(--el-text-color-primary);
    transition: background 0.15s;

    &:hover {
      background: var(--el-fill-color-light);
    }

    & + & {
      border-top: 1px solid var(--el-border-color-lighter);
    }

    .result-icon {
      flex-shrink: 0;
      color: var(--el-text-color-secondary);
    }

    .result-name {
      flex: 1;
      font-size: 0.9rem;
    }

    .result-arrow {
      flex-shrink: 0;
      color: var(--el-text-color-placeholder);
    }
  }
}

/* ── Badge helpers (shared with ItemListItem) ── */
.badge {
  font-size: 0.72rem;
  padding: 0.1rem 0.35rem;
  border-radius: 0.25rem;

  &--borrowed {
    background-color: var(--el-color-warning-light-7);
    color: var(--el-color-warning-dark-2);
  }

  &--broken {
    background-color: var(--el-color-danger-light-7);
    color: var(--el-color-danger-dark-2);
  }
}

/* ── Expiring Soon section ── */
.expiringSection {
  margin-bottom: 2rem;

  &__header {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.75rem;
  }

  &__icon {
    color: var(--el-color-warning);
    flex-shrink: 0;
  }

  &__title {
    margin: 0;
    font-size: 1rem;
    font-weight: 600;
    color: var(--el-text-color-primary);
  }
}

.expiringList {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.expiringCard {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.65rem 1rem;
  border: 1px solid var(--el-color-warning-light-5);
  border-radius: var(--el-border-radius-base);
  background: var(--el-color-warning-light-9);
  text-decoration: none;
  color: var(--el-text-color-primary);
  transition: background 0.15s, border-color 0.15s, box-shadow 0.15s;

  &:hover {
    background: var(--el-color-warning-light-7);
    border-color: var(--el-color-warning-light-3);
    box-shadow: var(--el-box-shadow-light);
  }

  &--expired {
    border-color: var(--el-color-danger-light-5);
    background: var(--el-color-danger-light-9);

    &:hover {
      background: var(--el-color-danger-light-7);
      border-color: var(--el-color-danger-light-3);
    }
  }

  &__icon {
    flex-shrink: 0;
    color: var(--el-text-color-secondary);
  }

  &__name {
    flex: 1;
    font-size: 0.9rem;
    font-weight: 500;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__date {
    font-size: 0.78rem;
    color: var(--el-color-warning-dark-2);
    white-space: nowrap;

    &--expired {
      color: var(--el-color-danger-dark-2);
      font-weight: 600;
    }
  }

  &__arrow {
    flex-shrink: 0;
    color: var(--el-text-color-placeholder);
  }
}

/* ── Category grid ── */
.categoryList {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(175px, 1fr));
  gap: 0.75rem;
}

.categoryCard {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  padding: 0.75rem 1rem;
  border: 1px solid var(--el-border-color-light);
  border-radius: var(--el-border-radius-base);
  background: var(--el-bg-color);
  text-decoration: none;
  color: var(--el-text-color-primary);
  transition: background 0.15s, border-color 0.15s, box-shadow 0.15s;

  &:hover {
    background: var(--el-fill-color-light);
    border-color: var(--el-color-primary-light-5);
    box-shadow: var(--el-box-shadow-light);
  }

  &__icon {
    flex-shrink: 0;
    color: var(--el-color-primary);
  }

  &__name {
    flex: 1;
    font-size: 0.9rem;
    font-weight: 500;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__arrow {
    flex-shrink: 0;
    color: var(--el-text-color-placeholder);
  }
}
</style>
