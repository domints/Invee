<script setup lang="ts">
import { type CategoryTreeResponse, getCategoryTree, getRootStorage, type StorageListEntry } from '@/client';
import StorageList from '@/components/StorageList.vue';
import { ref } from 'vue';
import { ElInput } from 'element-plus';
import { slugId } from '@/utils';

const input = ref('')
//const rootStorages = ref<StorageListEntry[]>();
const errors = ref();
// const storagesResponse = await getRootStorage();
// if (storagesResponse.error) {
//   errors.value = storagesResponse.error;
// }
// else {
//   rootStorages.value = storagesResponse.data;
// }

const categoryTree = ref<CategoryTreeResponse[]>();
const refreshCategories = async () => {
  categoryTree.value = (await getCategoryTree()).data;
}
await refreshCategories();
</script>

<template>
  <div class="container">
    <div class="storage-header">
      <div class="storage-header__name">
        <h2>Home</h2>
      </div>
    </div>
    <div class="searchBox">
      <div class="searchBox__label">Search items: </div><el-input v-model="input" placeholder="Please input" />
    </div>
    <div class="categoryList">
      <ul>
        <li v-for="category in categoryTree">
          <router-link :to="{ name: 'category', params: slugId(category) }">{{ category.name }}</router-link>
        </li>
      </ul>
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

.searchBox {
  display: flex;

  &__label {
    width: fit-content;
    text-wrap: nowrap;
    display: flex;
    align-items: center;
    padding-right: 1rem;
  }
}
</style>
