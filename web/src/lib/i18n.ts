import { ref } from "vue";

// English fallbacks, used outside FiveM (pnpm dev) and for any key the game has not sent.
// The game sends the `ui.*` keys of locales/<lang>.json without the `ui.` prefix.
const fallback: Record<string, string> = {
  "wallet.title": "Wallet",
  "wallet.drag_hint": "Drag to move · double click: default position",
  "wallet.close": "Close",
  "wallet.slot_label": "Slot %s: add card",
  "wallet.empty_slot": "Empty slot",
  "wallet.add_card": "+ Add card",
  "wallet.no_cards": "Your wallet is empty",
  "wallet.hint_view": "Click a card to view it",
  "wallet.hint_add": "Click an empty slot to add a card",
  "picker.title": "Add card",
  "picker.slot": "Slot %s",
  "picker.cancel": "Cancel",
  "picker.hint": "Cards in your inventory · the card you pick is taken from it",
  "picker.add": "Add",
  "picker.empty_title": "No cards to add",
  "picker.empty_text": "There is no card in your inventory that fits in the wallet.",
  "picker.unnamed": "Unnamed",
  "card.name": "Full Name",
  "card.birthdate": "Date of Birth",
  "card.sex": "Sex",
  "card.nationality": "Nationality",
  "card.citizenid": "Citizen ID",
  "card.male": "Male",
  "card.female": "Female",
  "viewer.back": "Back",
  "viewer.return": "Back to wallet",
  "viewer.remove": "Remove from wallet",
  "viewer.show": "Show to nearby",
  "shown.title": "A card is being shown to you",
  "shown.close": "Close",
};

const messages = ref<Record<string, string>>({});

export function setLocale(strings: unknown) {
  if (!strings || typeof strings !== "object") return;

  const next: Record<string, string> = {};
  for (const [key, value] of Object.entries(strings)) {
    if (typeof value === "string") next[key] = value;
  }
  messages.value = next;
}

/** Looks a text up at render time, so a language change applies right away. `%s`/`%d` take the arguments in order. */
export function t(key: string, ...args: (string | number)[]): string {
  const text = messages.value[key] ?? fallback[key] ?? key;
  let index = 0;
  return text.replace(/%[sd]/g, (match) => (index < args.length ? String(args[index++]) : match));
}
