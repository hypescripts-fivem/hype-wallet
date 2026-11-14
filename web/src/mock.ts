import type { WalletActionResult, WalletCard, WalletPayload } from "@/types";

// Only used when the page runs outside FiveM (pnpm dev): a tiny stand-in for the server

const background = "https://i.ibb.co/vxvGzg1/card.png";

// Same shape and formats as Qbox character data: YYYY-MM-DD birth dates, "M"/"F" sex
const holder = {
  firstname: "Jordan",
  lastname: "Miller",
  birthdate: "1996-07-21",
  sex: "M",
  nationality: "American",
  citizenid: "HYP48291",
};

type StoredCard = Omit<WalletCard, "id" | "slot">;

const definitions: Record<string, StoredCard> = {
  card_id: { item: "card_id", label: "ID Card", accent: "#3b82f6", background, holder },
  card_driver_car: { item: "card_driver_car", label: "Driver License", accent: "#10b981", background, holder },
  card_weapon: { item: "card_weapon", label: "Weapon License", accent: "#ef4444", background, holder },
  card_taxi: { item: "card_taxi", label: "Taxi License", accent: "#eab308", background, holder },
  card_driver_boat: { item: "card_driver_boat", label: "Boat License", accent: "#06b6d4", background, holder },
};

const SLOTS = 8;
const wallet = new Map<number, StoredCard>([
  [1, definitions.card_id],
  [2, definitions.card_driver_car],
  [3, definitions.card_weapon],
  [4, definitions.card_taxi],
]);
const inventory = new Map<number, StoredCard>([[12, definitions.card_driver_boat]]);

export function mockWallet(): WalletPayload {
  return {
    slots: SLOTS,
    showCooldown: 3000,
    cards: [...wallet].map(([slot, card]) => ({ ...card, slot, id: `${slot}:${card.item}` })),
    inventory: [...inventory].map(([slot, card]) => ({ ...card, slot, id: `inv:${slot}` })),
  };
}

export function mockAddCard(inventorySlot: number, slot: number): WalletActionResult {
  const card = inventory.get(inventorySlot);
  if (!card || wallet.has(slot)) return { ok: false, wallet: mockWallet() };

  inventory.delete(inventorySlot);
  wallet.set(slot, card);
  return { ok: true, wallet: mockWallet() };
}

export function mockRemoveCard(slot: number): WalletActionResult {
  const card = wallet.get(slot);
  if (!card) return { ok: false, wallet: mockWallet() };

  wallet.delete(slot);
  const free = Math.max(0, ...inventory.keys()) + 1;
  inventory.set(free, card);
  return { ok: true, wallet: mockWallet() };
}
