<template>
  <header>
    <div class="wrapper mt-2">
      <img src="/logo.png" class="logo mr-4" alt="ZENETYS" />
      <nav>
        <RouterLink to="/"></RouterLink>
      </nav>
    </div>
  </header>

  <RouterView />
</template>

<script setup>
import { RouterLink, RouterView } from 'vue-router'
</script>

<style>
.logo {
  width: 160px;
  height: auto;
}

header .wrapper {
  display: flex;
  place-items: flex-start;
  flex-wrap: wrap;
}
</style>
