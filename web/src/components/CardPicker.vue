<script setup lang="ts">
import { motion } from "motion-v";
import { Badge, Spinner } from "@vezironi/veyra-ui";
import CardFace from "@/components/CardFace.vue";
import type { WalletCard } from "@/types";

defineProps<{
  slotNumber: number;
  inventory: WalletCard[];
  pending?: boolean;
}>();

const emit = defineEmits<{
  pick: [card: WalletCard];
  cancel: [];
}>();

function holderName(card: WalletCard) {
  return [card.holder.firstname, card.holder.lastname].filter(Boolean).join(" ") || "İsimsiz";
}
</script>

<template>
  <!-- Sheet over the card stack: picks a card from the inventory for one empty slot -->
  <motion.div
    class="absolute inset-0 flex flex-col overflow-hidden rounded-[14px] border border-border bg-bg-surface shadow-2xl"
    :initial="{ y: '100%' }"
    :animate="{ y: 0 }"
    :exit="{ y: '100%' }"
    :transition="{ type: 'spring', stiffness: 380, damping: 36 }"
  >
    <div class="flex items-center gap-2 border-b border-border px-4 py-3">
      <p class="text-sm font-semibold text-text-primary">Kart ekle</p>
      <Badge variant="muted">Yuva {{ String(slotNumber).padStart(2, "0") }}</Badge>
      <Spinner v-if="pending" size="sm" class="ml-auto" />
      <button
        type="button"
        aria-label="Vazgeç"
        class="flex size-7 cursor-pointer items-center justify-center rounded-md text-text-faint transition-colors hover:bg-bg-muted hover:text-text-primary focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
        :class="{ 'ml-auto': !pending }"
        @click="emit('cancel')"
      >
        <svg class="size-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
          <path d="M18 6 6 18M6 6l12 12" />
        </svg>
      </button>
    </div>

    <div v-if="inventory.length" class="flex-1 overflow-y-auto p-2">
      <p class="px-2 pt-1 pb-2 text-[11px] text-text-muted">Envanterindeki kartlar · seçtiğin kart envanterden alınır</p>

      <button
        v-for="card in inventory"
        :key="card.id"
        type="button"
        class="group flex w-full cursor-pointer items-center gap-3 rounded-lg p-2 text-left transition-colors hover:bg-bg-muted focus-visible:outline-2 focus-visible:outline-ring disabled:cursor-not-allowed disabled:opacity-50"
        :disabled="pending"
        @click="emit('pick', card)"
      >
        <div class="w-[92px] shrink-0">
          <CardFace :card="card" />
        </div>
        <div class="min-w-0 flex-1">
          <p class="truncate text-sm font-semibold text-text-primary">{{ card.label }}</p>
          <p class="truncate text-xs text-text-muted">{{ holderName(card) }}</p>
        </div>
        <span class="text-xs font-semibold text-text-faint transition-colors group-hover:text-text-primary">Ekle</span>
      </button>
    </div>

    <div v-else class="grid flex-1 place-content-center gap-1 p-6 text-center">
      <p class="text-sm font-semibold text-text-primary">Eklenecek kart yok</p>
      <p class="text-xs text-text-muted">Envanterinde cüzdana konabilecek bir kart bulunmuyor.</p>
    </div>
  </motion.div>
</template>
