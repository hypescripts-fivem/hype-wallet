<script setup lang="ts">
import { computed } from "vue";
import { AnimatePresence, motion } from "motion-v";
import { Kbd } from "@vezironi/veyra-ui";
import CardFace from "@/components/CardFace.vue";
import type { ShownCardPayload } from "@/types";

// `key` changes for every new show so a replacing card animates in again
const props = defineProps<{ shown: (ShownCardPayload & { key: number }) | null }>();

const KEY_LABELS: Record<string, string> = { BACK: "Backspace", RETURN: "Enter", ESCAPE: "Esc" };

const side = computed(() => (props.shown?.position === "left" ? -1 : 1));
const keyLabel = computed(() => {
  const key = props.shown?.closeKey;
  return key ? (KEY_LABELS[key] ?? key) : null;
});
</script>

<template>
  <!-- Shown without NUI focus: it never takes the pointer from the game -->
  <div
    class="pointer-events-none fixed inset-y-0 z-[60] flex items-center"
    :class="shown?.position === 'left' ? 'left-10' : 'right-10'"
  >
    <AnimatePresence>
      <motion.aside
        v-if="shown"
        :key="shown.key"
        class="flex w-[400px] flex-col gap-2"
        :initial="{ opacity: 0, x: 90 * side, rotate: 4 * side }"
        :animate="{ opacity: 1, x: 0, rotate: 0 }"
        :exit="{ opacity: 0, x: 90 * side }"
        :transition="{ type: 'spring', stiffness: 260, damping: 26 }"
      >
        <div class="flex items-center gap-2 rounded-lg border border-border bg-bg-surface/90 px-3 py-2 shadow-xl">
          <span class="size-1.5 rounded-full bg-success" />
          <p class="text-xs font-semibold text-text-primary">Sana bir kart gösteriliyor</p>
          <span v-if="keyLabel" class="ml-auto flex items-center gap-1.5 text-[11px] text-text-muted">
            <Kbd>{{ keyLabel }}</Kbd> Kapat
          </span>
        </div>

        <CardFace :card="shown.card" />

        <div class="h-1 overflow-hidden rounded-full bg-bg-muted">
          <motion.div
            class="h-full origin-left rounded-full bg-inverse/70"
            :initial="{ scaleX: 1 }"
            :animate="{ scaleX: 0 }"
            :transition="{ duration: shown.duration / 1000, ease: 'linear' }"
          />
        </div>
      </motion.aside>
    </AnimatePresence>
  </div>
</template>
