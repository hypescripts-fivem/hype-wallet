<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from "vue";
import { AnimatePresence, LayoutGroup } from "motion-v";
import CardViewer from "@/components/CardViewer.vue";
import ShownCard from "@/components/ShownCard.vue";
import Wallet from "@/components/Wallet.vue";
import { useDraggable } from "@/composables/useDraggable";
import { fetchNui, isEnvBrowser } from "@/lib/nui";
import { mockAddCard, mockRemoveCard, mockWallet } from "@/mock";
import type { ShownCardPayload, WalletActionResult, WalletCard, WalletPayload } from "@/types";

type NuiMessage =
  | { action: "open"; data: WalletPayload }
  | { action: "close" }
  | { action: "showCard"; data: ShownCardPayload }
  | { action: "hideShownCard" };

const visible = ref(false);
const slots = ref(0);
const cards = ref<WalletCard[]>([]);
const inventory = ref<WalletCard[]>([]);
const selectedId = ref<string | null>(null);
const pickerSlot = ref<number | null>(null);
const actionPending = ref(false);
const showCooldown = ref(3000);
const showPending = ref(false);
const shown = ref<(ShownCardPayload & { key: number }) | null>(null);
let shownTimer: ReturnType<typeof setTimeout> | undefined;
let shownKey = 0;

const selectedCard = computed(() => cards.value.find((card) => card.id === selectedId.value) ?? null);

// The anchor stays mounted while the wallet is closed, so its position is kept between opens
const walletAnchor = ref<HTMLElement | null>(null);
const drag = useDraggable(walletAnchor, "hype-wallet:position");

function applyWallet(payload: WalletPayload) {
  slots.value = Math.max(1, Math.floor(Number(payload.slots) || 1));
  showCooldown.value = Math.max(0, Number(payload.showCooldown) || 3000);
  cards.value = Array.isArray(payload.cards) ? payload.cards.filter((card) => card.slot <= slots.value) : [];
  inventory.value = Array.isArray(payload.inventory) ? payload.inventory : [];
}

function open(payload: WalletPayload) {
  applyWallet(payload);
  selectedId.value = null;
  pickerSlot.value = null;
  visible.value = true;
  // Slot count (and so the wallet height) may differ from last time
  nextTick(drag.refit);
}

function hide() {
  visible.value = false;
  selectedId.value = null;
  pickerSlot.value = null;
}

function close() {
  hide();
  fetchNui("close");
  if (isEnvBrowser) setTimeout(() => open(mockWallet()), 800);
}

// Sends one wallet change to the server; the answer always carries the fresh wallet state
async function walletAction(event: "addCard" | "removeCard", data: Record<string, number>) {
  if (actionPending.value) return null;
  actionPending.value = true;

  try {
    const result = isEnvBrowser
      ? event === "addCard"
        ? mockAddCard(data.inventorySlot, data.slot)
        : mockRemoveCard(data.slot)
      : await fetchNui<WalletActionResult>(event, data);

    if (result?.close) hide();
    return result ?? null;
  } finally {
    actionPending.value = false;
  }
}

async function addCard(card: WalletCard) {
  if (pickerSlot.value === null) return;

  const result = await walletAction("addCard", { inventorySlot: card.slot, slot: pickerSlot.value });
  if (result?.wallet) applyWallet(result.wallet);
  if (result?.ok) pickerSlot.value = null;
}

async function removeCard(card: WalletCard) {
  const result = await walletAction("removeCard", { slot: card.slot });
  if (!result?.wallet) return;

  if (!result.ok) {
    applyWallet(result.wallet);
    return;
  }

  // Let the card fly back into its slot first, then take it out of the wallet
  const wallet = result.wallet;
  selectedId.value = null;
  setTimeout(() => applyWallet(wallet), 380);
}

// The other player's side: a card shown to us, displayed until its time runs out
function displayShownCard(payload: ShownCardPayload) {
  const duration = Math.min(Math.max(Number(payload.duration) || 7000, 1000), 60000);
  shown.value = { ...payload, duration, key: ++shownKey };
  clearTimeout(shownTimer);
  shownTimer = setTimeout(hideShownCard, duration);
}

function hideShownCard() {
  clearTimeout(shownTimer);
  shown.value = null;
}

async function showToNearby(card: WalletCard) {
  if (showPending.value) return;

  showPending.value = true;
  setTimeout(() => (showPending.value = false), showCooldown.value);

  // Outside FiveM there is no other player, so preview the receiving side locally
  if (isEnvBrowser) displayShownCard({ card, duration: 7000, position: "left", closeKey: "BACK" });
  else await fetchNui("showCard", { id: card.id });
}

function onMessage(event: MessageEvent<NuiMessage>) {
  const message = event.data;
  if (message?.action === "open") open(message.data);
  else if (message?.action === "close") hide();
  else if (message?.action === "showCard") displayShownCard(message.data);
  else if (message?.action === "hideShownCard") hideShownCard();
}

function onKeydown(event: KeyboardEvent) {
  if (!visible.value || event.key !== "Escape") return;
  if (pickerSlot.value !== null) pickerSlot.value = null;
  else if (selectedId.value) selectedId.value = null;
  else close();
}

onMounted(() => {
  window.addEventListener("message", onMessage);
  window.addEventListener("keydown", onKeydown);
  if (isEnvBrowser) open(mockWallet());
});

onBeforeUnmount(() => {
  window.removeEventListener("message", onMessage);
  window.removeEventListener("keydown", onKeydown);
  clearTimeout(shownTimer);
});
</script>

<template>
  <main
    class="fixed inset-0 flex items-center justify-end p-12"
    :class="{ 'dev-backdrop': isEnvBrowser, 'cursor-grabbing select-none': drag.dragging.value }"
  >
    <LayoutGroup>
      <div ref="walletAnchor" :class="drag.position.value ? 'fixed' : 'relative'" :style="drag.style.value">
        <AnimatePresence>
          <Wallet
            v-if="visible"
            key="wallet"
            :slots="slots"
            :cards="cards"
            :inventory="inventory"
            :selected-id="selectedId"
            :picker-slot="pickerSlot"
            :pending="actionPending"
            :dragging="drag.dragging.value"
            @select="(card) => (selectedId = card.id)"
            @open-picker="(slot) => (pickerSlot = slot)"
            @close-picker="pickerSlot = null"
            @add-card="addCard"
            @close="close"
            @drag-start="drag.startDrag"
            @reset-position="drag.reset"
          />
        </AnimatePresence>
      </div>

      <CardViewer
        :card="visible ? selectedCard : null"
        :show-pending="showPending"
        :pending="actionPending"
        @close="selectedId = null"
        @show="showToNearby"
        @remove="removeCard"
      />
    </LayoutGroup>

    <ShownCard :shown="shown" />
  </main>
</template>

<style scoped>
.dev-backdrop {
  background: radial-gradient(circle at 30% 40%, #2b3a2f, #0b0d0c 70%);
}
</style>
