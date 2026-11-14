<script setup lang="ts">
import { computed, ref } from "vue";
import { AnimatePresence, motion } from "motion-v";
import { Badge, Kbd } from "@vezironi/veyra-ui";
import CardFace from "@/components/CardFace.vue";
import CardPicker from "@/components/CardPicker.vue";
import type { WalletCard } from "@/types";

const props = defineProps<{
  slots: number;
  cards: WalletCard[];
  inventory: WalletCard[];
  selectedId: string | null;
  pickerSlot: number | null;
  pending?: boolean;
  dragging?: boolean;
}>();

const emit = defineEmits<{
  select: [card: WalletCard];
  close: [];
  dragStart: [event: PointerEvent];
  resetPosition: [];
  openPicker: [slot: number];
  closePicker: [];
  addCard: [card: WalletCard];
}>();

const CARD_WIDTH = 340;
const CARD_HEIGHT = CARD_WIDTH / 1.5;
// Visible strip of each card (its title band) while it sits in the stack
const STRIDE = 44;
// Hovered card (with the ones behind it) rises a little, the cards in front of it make room
const LIFT = 26;
const SPREAD = 72;
const TOP_PAD = 30;
const FRONT_HEIGHT = CARD_HEIGHT - STRIDE + 20;

const spring = { type: "spring", stiffness: 420, damping: 32, mass: 0.8 } as const;

const hovered = ref<number | null>(null);

const slotList = computed(() =>
  Array.from({ length: props.slots }, (_, index) => ({
    index,
    card: props.cards.find((card) => card.slot === index + 1) ?? null,
  })),
);

const areaHeight = computed(() => TOP_PAD + props.slots * STRIDE + FRONT_HEIGHT);

function offsetFor(index: number) {
  const active = hovered.value;
  if (active === null || props.selectedId || props.pickerSlot !== null) return 0;
  // Cards behind rise with the hovered one so their title strips stay fully reachable
  return index <= active ? -LIFT : SPREAD;
}

function onHandlePointerDown(event: PointerEvent) {
  if ((event.target as HTMLElement).closest("button")) return;
  hovered.value = null;
  emit("dragStart", event);
}

function select(card: WalletCard) {
  hovered.value = null;
  emit("select", card);
}
</script>

<template>
  <motion.section
    class="wallet"
    :style="{ width: `${CARD_WIDTH + 40}px` }"
    :initial="{ opacity: 0, y: 40, scale: 0.96 }"
    :animate="{ opacity: 1, y: 0, scale: 1 }"
    :exit="{ opacity: 0, y: 40, scale: 0.96 }"
    :transition="spring"
  >
    <!-- Drag handle; double click puts the wallet back to its default place -->
    <header
      class="flex touch-none items-center gap-x-2.5 px-5 pt-4 pb-1 select-none"
      :class="dragging ? 'cursor-grabbing' : 'cursor-grab'"
      title="Sürükleyerek taşı · çift tıkla: varsayılan konum"
      @pointerdown="onHandlePointerDown"
      @dblclick="emit('resetPosition')"
    >
      <svg class="size-4 text-text-faint" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1" />
        <path d="M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4" />
      </svg>
      <p class="text-sm font-semibold text-text-primary">Cüzdan</p>
      <Badge variant="muted">{{ cards.length }}/{{ slots }}</Badge>

      <svg class="ml-auto size-4 text-text-faint" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <circle cx="9" cy="6" r="1.5" /><circle cx="15" cy="6" r="1.5" />
        <circle cx="9" cy="12" r="1.5" /><circle cx="15" cy="12" r="1.5" />
        <circle cx="9" cy="18" r="1.5" /><circle cx="15" cy="18" r="1.5" />
      </svg>

      <button
        type="button"
        aria-label="Kapat"
        class="flex size-7 cursor-pointer items-center justify-center rounded-md text-text-faint transition-colors hover:bg-bg-muted hover:text-text-primary focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring"
        @click="emit('close')"
      >
        <svg class="size-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
          <path d="M18 6 6 18M6 6l12 12" />
        </svg>
      </button>
    </header>

    <div class="relative mx-5 overflow-hidden" :style="{ height: `${areaHeight}px` }" @mouseleave="hovered = null">
      <div
        v-for="{ index, card } in slotList"
        :key="card?.id ?? `empty-${index}`"
        class="pointer-events-none absolute inset-x-0 *:pointer-events-auto"
        :style="{ top: `${TOP_PAD + index * STRIDE}px`, zIndex: index + 1 }"
      >
        <!-- The wrapper stays put while its card moves, so only the card itself may receive the pointer -->
        <motion.button
          v-if="card"
          type="button"
          class="block w-full cursor-pointer rounded-[12px] text-left outline-none focus-visible:ring-2 focus-visible:ring-ring"
          :aria-label="card.label"
          :layout-id="card.id"
          :animate="{ y: offsetFor(index) }"
          :transition="spring"
          :while-press="{ scale: 0.98 }"
          @mouseenter="hovered = index"
          @focus="hovered = index"
          @blur="hovered = null"
          @click="select(card)"
        >
          <CardFace :card="card" />
        </motion.button>

        <motion.button
          v-else
          type="button"
          class="empty-slot group"
          :aria-label="`Yuva ${index + 1}: kart ekle`"
          :style="{ height: `${CARD_HEIGHT}px` }"
          :animate="{ y: offsetFor(index) }"
          :transition="spring"
          @mouseenter="hovered = null"
          @click="emit('openPicker', index + 1)"
        >
          <span>Boş yuva</span>
          <span class="tabular-nums group-hover:hidden">{{ String(index + 1).padStart(2, "0") }}</span>
          <span class="hidden text-text-primary group-hover:inline">+ Kart ekle</span>
        </motion.button>
      </div>

      <!-- Front pocket: covers the lower part of the stack like a real wallet. It makes room like the cards do,
           but by lowering its top edge so the bottom (and the hint row) stays in place -->
      <motion.div
        class="front-pocket"
        :style="{ zIndex: slots + 1 }"
        :initial="false"
        :animate="{ top: TOP_PAD + slots * STRIDE + offsetFor(slots) }"
        :transition="spring"
        @mouseenter="hovered = null"
      >
        <div class="grid flex-1 place-content-center gap-1">
          <p class="front-pocket__emboss">HYPE</p>
          <p v-if="!cards.length" class="text-center text-xs text-text-muted">Cüzdanında kart yok</p>
        </div>

        <div class="flex items-center justify-between text-[11px] text-text-muted">
          <span>{{ cards.length ? "Görüntülemek için karta tıkla" : "Eklemek için boş yuvaya tıkla" }}</span>
          <span class="flex items-center gap-1.5"><Kbd>ESC</Kbd> Kapat</span>
        </div>
      </motion.div>

      <AnimatePresence>
        <CardPicker
          v-if="pickerSlot !== null"
          key="picker"
          :style="{ zIndex: slots + 2 }"
          :slot-number="pickerSlot"
          :inventory="inventory"
          :pending="pending"
          @pick="emit('addCard', $event)"
          @cancel="emit('closePicker')"
        />
      </AnimatePresence>
    </div>

    <div class="h-5" />
  </motion.section>
</template>

<style scoped>
.wallet {
  position: relative;
  overflow: hidden;
  border: 1px solid var(--color-border);
  border-radius: 22px;
  background:
    radial-gradient(120% 80% at 50% 0%, rgb(255 255 255 / 0.05), transparent 60%),
    var(--color-bg-surface);
  box-shadow:
    inset 0 0 0 5px var(--color-bg-surface),
    inset 0 0 0 6px rgb(255 255 255 / 0.06),
    0 30px 80px rgb(0 0 0 / 0.6);
}

/* Stitching around the wallet edge */
.wallet::after {
  position: absolute;
  inset: 9px;
  border: 1px dashed rgb(255 255 255 / 0.08);
  border-radius: 16px;
  content: "";
  pointer-events: none;
}

.empty-slot {
  display: flex;
  width: 100%;
  cursor: pointer;
  justify-content: space-between;
  padding: 0 14px;
  border: 1px dashed rgb(255 255 255 / 0.1);
  border-radius: 12px;
  /* Opaque so it hides the card sitting below it in the stack */
  background:
    linear-gradient(180deg, rgb(255 255 255 / 0.03), transparent 40px),
    var(--color-bg-surface);
  box-shadow: 0 -6px 14px rgb(0 0 0 / 0.35);
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  line-height: 30px;
  color: var(--color-text-faint);
  text-align: left;
  text-transform: uppercase;
  transition:
    border-color 0.15s,
    color 0.15s;
}

.empty-slot:hover,
.empty-slot:focus-visible {
  border-color: rgb(255 255 255 / 0.28);
  color: var(--color-text-muted);
  outline: none;
}

.front-pocket {
  position: absolute;
  inset-inline: -1px;
  bottom: 0;
  display: flex;
  flex-direction: column;
  padding: 14px;
  border: 1px solid var(--color-border);
  border-radius: 14px;
  background:
    linear-gradient(180deg, rgb(255 255 255 / 0.05), transparent 30%),
    var(--color-bg-muted);
  box-shadow: 0 -12px 24px rgb(0 0 0 / 0.45);
}

.front-pocket::before {
  position: absolute;
  inset: 6px;
  border: 1px dashed rgb(255 255 255 / 0.07);
  border-radius: 10px;
  content: "";
  pointer-events: none;
}

.front-pocket__emboss {
  font-size: 22px;
  font-weight: 800;
  letter-spacing: 0.6em;
  text-align: center;
  color: transparent;
  text-shadow:
    0 1px 0 rgb(255 255 255 / 0.06),
    0 -1px 0 rgb(0 0 0 / 0.6);
  background: var(--color-bg-elevated);
  background-clip: text;
  padding-left: 0.6em;
}
</style>
