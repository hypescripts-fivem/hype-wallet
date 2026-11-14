<script setup lang="ts">
import { AnimatePresence, motion } from "motion-v";
import { Button, Kbd } from "@vezironi/veyra-ui";
import CardFace from "@/components/CardFace.vue";
import type { WalletCard } from "@/types";

defineProps<{ card: WalletCard | null; showPending?: boolean; pending?: boolean }>();

const emit = defineEmits<{ close: []; show: [card: WalletCard]; remove: [card: WalletCard] }>();

const spring = { type: "spring", stiffness: 300, damping: 30 } as const;
</script>

<template>
  <AnimatePresence>
    <motion.div
      v-if="card"
      key="backdrop"
      class="fixed inset-0 z-40 bg-black/55 backdrop-blur-[3px]"
      :initial="{ opacity: 0 }"
      :animate="{ opacity: 1 }"
      :exit="{ opacity: 0 }"
      @click="emit('close')"
    />
  </AnimatePresence>

  <AnimatePresence>
    <motion.div
      v-if="card"
      key="viewer"
      class="pointer-events-none fixed inset-0 z-50 flex flex-col items-center justify-center gap-5 p-6"
      :exit="{ opacity: 1 }"
    >
      <motion.div
        class="pointer-events-auto w-[min(620px,90vw)]"
        :layout-id="card.id"
        :transition="spring"
        @click="emit('close')"
      >
        <CardFace :card="card" />
      </motion.div>

      <motion.div
        class="pointer-events-auto flex items-center gap-3 rounded-xl border border-border bg-bg-surface/90 py-2 pr-2 pl-4 shadow-2xl"
        :initial="{ opacity: 0, y: 12 }"
        :animate="{ opacity: 1, y: 0, transition: { delay: 0.15 } }"
        :exit="{ opacity: 0, y: 12, transition: { duration: 0.12 } }"
      >
        <p class="text-sm font-semibold text-text-primary">{{ card.label }}</p>
        <span class="flex items-center gap-1.5 text-xs text-text-faint"><Kbd>ESC</Kbd> Geri</span>
        <Button size="sm" variant="secondary" @click="emit('close')">Cüzdana dön</Button>
        <Button size="sm" variant="outline" :disabled="pending" @click="emit('remove', card)">Cüzdandan çıkar</Button>
        <Button size="sm" variant="primary" :disabled="showPending" @click="emit('show', card)">
          <span class="flex items-center gap-1.5">
            <svg class="size-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M2.06 12.35a1 1 0 0 1 0-.7 10.75 10.75 0 0 1 19.88 0 1 1 0 0 1 0 .7 10.75 10.75 0 0 1-19.88 0" />
              <circle cx="12" cy="12" r="3" />
            </svg>
            Yakındakine göster
          </span>
        </Button>
      </motion.div>
    </motion.div>
  </AnimatePresence>
</template>
