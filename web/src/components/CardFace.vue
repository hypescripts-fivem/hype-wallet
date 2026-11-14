<script setup lang="ts">
import { computed } from "vue";
import type { WalletCard } from "@/types";

const props = defineProps<{ card: WalletCard }>();

const SEX_LABELS: Record<string, string> = { M: "Erkek", F: "Kadın", Male: "Erkek", Female: "Kadın" };

const fullName = computed(() => {
  const { firstname, lastname } = props.card.holder;
  return [firstname, lastname].filter(Boolean).join(" ") || "—";
});

const fields = computed(() => {
  const { birthdate, sex, nationality } = props.card.holder;
  return [
    { label: "Doğum Tarihi", value: birthdate || "—" },
    { label: "Cinsiyet", value: (sex && SEX_LABELS[sex]) || sex || "—" },
    { label: "Uyruk", value: nationality || "—" },
  ];
});
</script>

<template>
  <!-- Sizes are in cqw so the same face renders proportionally in the wallet and in the full view -->
  <div class="card-face">
    <div
      class="card-face__inner"
      :style="{ backgroundImage: `url(${card.background})`, '--accent': card.accent ?? '#3b82f6' }"
    >
      <header class="card-face__header">
        <span class="card-face__dot" />
        <span class="card-face__title">{{ card.label }}</span>
      </header>

      <div class="card-face__body">
        <div class="card-face__photo">
          <img v-if="card.mugShot" :src="card.mugShot" alt="" />
          <svg v-else viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
            <path d="M12 12a4.5 4.5 0 1 0 0-9 4.5 4.5 0 0 0 0 9Zm0 2.25c-4.14 0-7.5 2.52-7.5 5.63 0 .62.5 1.12 1.13 1.12h12.74c.62 0 1.13-.5 1.13-1.12 0-3.11-3.36-5.63-7.5-5.63Z" />
          </svg>
        </div>

        <dl class="card-face__fields">
          <div class="card-face__field card-face__field--wide">
            <dt>Ad Soyad</dt>
            <dd>{{ fullName }}</dd>
          </div>
          <div v-for="field in fields" :key="field.label" class="card-face__field">
            <dt>{{ field.label }}</dt>
            <dd>{{ field.value }}</dd>
          </div>
        </dl>
      </div>

      <footer class="card-face__footer">
        <span>Vatandaş No</span>
        <span class="card-face__mono">{{ card.holder.citizenid || "—" }}</span>
      </footer>
    </div>
  </div>
</template>

<style scoped>
.card-face {
  container-type: inline-size;
  width: 100%;
}

.card-face__inner {
  position: relative;
  aspect-ratio: 3 / 2;
  overflow: hidden;
  border-radius: 3.4cqw;
  background-color: #f4f7f6;
  background-size: 100% 100%;
  color: #0f2540;
  box-shadow:
    0 0 0 0.3cqw rgb(0 0 0 / 0.08),
    0 1.2cqw 4cqw rgb(0 0 0 / 0.45);
  user-select: none;
}

.card-face__header {
  display: flex;
  height: 8.7cqw;
  align-items: center;
  gap: 1.8cqw;
  padding: 0 20cqw 0 4cqw;
}

.card-face__dot {
  width: 2cqw;
  height: 2cqw;
  flex-shrink: 0;
  border-radius: 999px;
  background: var(--accent);
  box-shadow: 0 0 0 0.5cqw color-mix(in srgb, var(--accent) 25%, transparent);
}

.card-face__title {
  overflow: hidden;
  font-size: 3.6cqw;
  font-weight: 800;
  letter-spacing: 0.06em;
  text-overflow: ellipsis;
  text-transform: uppercase;
  white-space: nowrap;
}

.card-face__body {
  display: grid;
  grid-template-columns: 24cqw 1fr;
  gap: 4cqw;
  padding: 5cqw 4cqw 0;
}

.card-face__photo {
  display: grid;
  aspect-ratio: 3 / 4;
  place-items: center;
  overflow: hidden;
  border: 0.3cqw solid rgb(15 37 64 / 0.15);
  border-radius: 1.6cqw;
  background: rgb(15 37 64 / 0.07);
  color: rgb(15 37 64 / 0.25);
}

.card-face__photo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.card-face__photo svg {
  width: 60%;
}

.card-face__fields {
  display: grid;
  grid-template-columns: 1fr 1fr;
  align-content: start;
  gap: 3cqw 3cqw;
  margin: 0;
}

.card-face__field--wide {
  grid-column: span 2;
}

.card-face__field dt {
  font-size: 2cqw;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: rgb(15 37 64 / 0.55);
  text-transform: uppercase;
}

.card-face__field dd {
  overflow: hidden;
  margin: 0.4cqw 0 0;
  font-size: 3.4cqw;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.card-face__field--wide dd {
  font-size: 4.4cqw;
}

.card-face__footer {
  position: absolute;
  right: 4cqw;
  bottom: 3.4cqw;
  left: 4cqw;
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  font-size: 2cqw;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: rgb(15 37 64 / 0.55);
  text-transform: uppercase;
}

.card-face__mono {
  font-family: ui-monospace, "Cascadia Mono", Consolas, monospace;
  font-size: 3.2cqw;
  letter-spacing: 0.12em;
  color: #0f2540;
}
</style>
