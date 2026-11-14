export interface CardHolder {
  firstname?: string;
  lastname?: string;
  birthdate?: string;
  sex?: string;
  nationality?: string;
  citizenid?: string;
}

export interface WalletCard {
  id: string;
  /** Wallet slot (1-based) for stored cards, inventory slot for inventory cards */
  slot: number;
  item: string;
  label: string;
  accent?: string;
  background: string;
  holder: CardHolder;
  mugShot?: string;
}

export interface ShownCardPayload {
  card: WalletCard;
  duration: number;
  position: "left" | "right";
  closeKey?: string;
}

export interface WalletPayload {
  slots: number;
  showCooldown?: number;
  cards: WalletCard[];
  inventory: WalletCard[];
}

export interface WalletActionResult {
  ok: boolean;
  close?: boolean;
  wallet?: WalletPayload;
}
