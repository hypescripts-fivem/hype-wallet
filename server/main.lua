local config = require 'config.shared'

local ox_inventory = exports.ox_inventory
local MAX_MUGSHOT_LENGTH = 512 * 1024

local cardNames = {}
local cardByItem = {}
for i = 1, #config.cards do
    local card = config.cards[i]
    cardNames[i] = card.item
    cardByItem[card.item] = card
end

---@type table<number, string> player -> id of the wallet they have open
local openWallets = {}

---@type table<number, number>
local lastShown = {}

---@type table<number, boolean>
local busy = {}

---@param value any
---@return string?
local function text(value)
    if type(value) == 'string' or type(value) == 'number' then
        return tostring(value)
    end
end

---@param value any
---@return string?
local function mugShot(value)
    if type(value) == 'string'
        and #value <= MAX_MUGSHOT_LENGTH
        and value:find('^data:image/[%w.+-]+;base64,') then
        return value
    end
end

--- Sent as a locale key so every player reads it in their own language
---@param src number
---@param key string locale key
---@param kind 'success' | 'error' | 'inform'
local function notify(src, key, kind)
    TriggerClientEvent('hype-wallet:client:notify', src, key, kind)
end

---@param card table config entry
---@param id string
---@param metadata table?
---@return table
local function buildCard(card, id, metadata)
    metadata = type(metadata) == 'table' and metadata or {}

    return {
        id = id,
        item = card.item,
        label = card.label,
        accent = card.accent,
        background = card.background or config.defaultBackground,
        holder = {
            firstname = text(metadata.firstname),
            lastname = text(metadata.lastname),
            birthdate = text(metadata.birthdate),
            sex = text(metadata.sex),
            nationality = text(metadata.nationality),
            citizenid = text(metadata.citizenid),
        },
        mugShot = mugShot(metadata.mugShot),
    }
end

-- Storage: one KVP entry per wallet slot, so a large mugshot never rewrites the whole wallet

---@param walletId string
---@param slot integer
local function kvpKey(walletId, slot)
    return ('wallet:%s:%d'):format(walletId, slot)
end

---@param walletId string
---@param slot integer
---@return { name: string, metadata: table }?
local function getStoredCard(walletId, slot)
    local raw = GetResourceKvpString(kvpKey(walletId, slot))
    local entry = raw and json.decode(raw)

    if type(entry) == 'table' and type(entry.name) == 'string' then
        return entry
    end
end

---@param walletId string
---@param slot integer
---@param entry { name: string, metadata: table }?
local function setStoredCard(walletId, slot, entry)
    if entry then
        SetResourceKvp(kvpKey(walletId, slot), json.encode(entry))
    else
        DeleteResourceKvp(kvpKey(walletId, slot))
    end
end

---@param slot any
---@return integer?
local function walletSlot(slot)
    slot = tonumber(slot)
    if slot and math.type(slot) == 'integer' and slot >= 1 and slot <= config.slots then
        return slot
    end
end

---@return string
local function newWalletId()
    local id, marker

    -- `wallet:<id>` marks an id as taken, even while all of its slots are empty
    repeat
        id = ('%x%04x'):format(os.time(), math.random(0, 0xffff))
        marker = ('wallet:%s'):format(id)
    until not GetResourceKvpString(marker)

    SetResourceKvp(marker, '1')
    return id
end

---@param src number
---@param walletId string
---@return boolean
local function hasWallet(src, walletId)
    local slots = ox_inventory:Search(src, 'slots', config.walletItem) or {}

    for i = 1, #slots do
        local metadata = slots[i].metadata
        if type(metadata) == 'table' and metadata.walletId == walletId then return true end
    end

    return false
end

--- The wallet the player has open, as long as it is still in their inventory
---@param src number
---@return string?
local function getOpenWallet(src)
    local walletId = openWallets[src]
    if walletId and hasWallet(src, walletId) then return walletId end

    openWallets[src] = nil
end

---@param src number
---@param walletId string
---@return table
local function getWalletPayload(src, walletId)
    local cards = {}

    for slot = 1, config.slots do
        local entry = getStoredCard(walletId, slot)
        local card = entry and cardByItem[entry.name]

        if card then
            local data = buildCard(card, ('%d:%s'):format(slot, entry.name), entry.metadata)
            data.slot = slot
            cards[#cards + 1] = data
        end
    end

    -- Cards in the inventory that can be put into the wallet
    local inventory = {}
    local found = ox_inventory:Search(src, 'slots', cardNames) or {}

    -- Search returns the slot list directly when only one item name is searched
    if #cardNames == 1 then
        found = { [cardNames[1]] = found }
    end

    for i = 1, #config.cards do
        local card = config.cards[i]
        local slots = found[card.item]

        if type(slots) == 'table' then
            for j = 1, #slots do
                local item = slots[j]
                local data = buildCard(card, ('inv:%d'):format(item.slot), item.metadata)
                data.slot = item.slot
                inventory[#inventory + 1] = data
            end
        end
    end

    return {
        slots = config.slots,
        showCooldown = config.show.cooldown,
        cards = cards,
        inventory = inventory,
    }
end

---@param src number
---@param item table? wallet inventory slot; the first wallet found is used when omitted
local function openWallet(src, item)
    if not item then
        local slots = ox_inventory:Search(src, 'slots', config.walletItem) or {}
        item = slots[1]
    end

    if not item then
        notify(src, 'notify.no_wallet', 'error')
        return
    end

    local metadata = type(item.metadata) == 'table' and item.metadata or {}

    if type(metadata.walletId) ~= 'string' then
        metadata.walletId = newWalletId()
        ox_inventory:SetMetadata(src, item.slot, metadata)
    end

    openWallets[src] = metadata.walletId
    TriggerClientEvent('hype-wallet:client:open', src, getWalletPayload(src, metadata.walletId))
end

--- Runs a wallet change for one player at a time and answers with the fresh wallet state
---@param src number
---@param fn fun(walletId: string): boolean
local function walletAction(src, fn)
    if busy[src] then return { ok = false } end

    local walletId = getOpenWallet(src)
    if not walletId then
        notify(src, 'notify.wallet_gone', 'error')
        return { ok = false, close = true }
    end

    busy[src] = true
    local success, ok = pcall(fn, walletId)
    busy[src] = nil

    if not success then
        lib.print.error(ok)
        ok = false
    end

    return { ok = ok == true, wallet = getWalletPayload(src, walletId) }
end

lib.callback.register('hype-wallet:server:addCard', function(src, inventorySlot, targetSlot)
    return walletAction(src, function(walletId)
        local slot = walletSlot(targetSlot)
        if not slot or getStoredCard(walletId, slot) then
            notify(src, 'notify.slot_taken', 'error')
            return false
        end

        local item = tonumber(inventorySlot) and ox_inventory:GetSlot(src, tonumber(inventorySlot))
        if not item or not cardByItem[item.name] then
            notify(src, 'notify.card_not_found', 'error')
            return false
        end

        -- Remove first, store after: a failed removal never creates a copy
        if not ox_inventory:RemoveItem(src, item.name, 1, nil, item.slot) then
            notify(src, 'notify.card_take_failed', 'error')
            return false
        end

        setStoredCard(walletId, slot, { name = item.name, metadata = item.metadata or {} })
        return true
    end)
end)

lib.callback.register('hype-wallet:server:removeCard', function(src, targetSlot)
    return walletAction(src, function(walletId)
        local slot = walletSlot(targetSlot)
        local entry = slot and getStoredCard(walletId, slot)
        if not entry then return false end

        if not ox_inventory:CanCarryItem(src, entry.name, 1, entry.metadata) then
            notify(src, 'notify.inventory_full', 'error')
            return false
        end

        -- Clear first, give after; put it back if the inventory refuses
        setStoredCard(walletId, slot, nil)

        if not ox_inventory:AddItem(src, entry.name, 1, entry.metadata) then
            setStoredCard(walletId, slot, entry)
            notify(src, 'notify.card_give_failed', 'error')
            return false
        end

        return true
    end)
end)

---@param src number
---@param target any
---@return boolean
local function isNearbyPlayer(src, target)
    if math.type(target) ~= 'integer' or target <= 0 or target == src or not GetPlayerName(target) then return false end
    if GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return false end

    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    if playerPed <= 0 or targetPed <= 0 then return false end

    -- Small tolerance for movement between the client check and this one
    return #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed)) <= config.show.distance + 1.0
end

RegisterNetEvent('hype-wallet:server:showCard', function(cardId, target)
    local src = source --[[@as number]]
    if type(cardId) ~= 'string' then return end

    local now = GetGameTimer()
    if lastShown[src] and now - lastShown[src] < config.show.cooldown then return end
    lastShown[src] = now

    local walletId = getOpenWallet(src)
    if not walletId then return end

    -- Only a card stored in the player's own open wallet can be shown
    local slot, itemName = cardId:match('^(%d+):(.+)$')
    slot = walletSlot(slot)
    local entry = slot and getStoredCard(walletId, slot)
    local card = entry and entry.name == itemName and cardByItem[entry.name]

    if not card then
        notify(src, 'notify.card_not_in_wallet', 'error')
        return
    end

    target = tonumber(target)
    if not isNearbyPlayer(src, target) then
        notify(src, 'notify.no_one_nearby', 'error')
        return
    end

    TriggerClientEvent('hype-wallet:client:showCard', target, buildCard(card, cardId, entry.metadata))
    TriggerClientEvent('hype-wallet:client:cardShown', src)
end)

RegisterNetEvent('hype-wallet:server:closed', function()
    openWallets[source] = nil
end)

AddEventHandler('playerDropped', function()
    openWallets[source] = nil
    lastShown[source] = nil
    busy[source] = nil
end)

exports.qbx_core:CreateUseableItem(config.walletItem, function(source, item)
    openWallet(source, item)
end)

if config.command then
    lib.addCommand(config.command, { help = locale('command.open') }, function(source)
        openWallet(source)
    end)
end

exports('OpenWallet', openWallet)

--- Whether one of the wallets in the player's inventory holds the card
---@param src number
---@param itemName string
---@param citizenid string? only count cards issued to this citizen
---@return boolean
local function hasCardInWallet(src, itemName, citizenid)
    local wallets = ox_inventory:Search(src, 'slots', config.walletItem) or {}

    for i = 1, #wallets do
        local metadata = wallets[i].metadata
        local walletId = type(metadata) == 'table' and metadata.walletId

        if type(walletId) == 'string' then
            for slot = 1, config.slots do
                local entry = getStoredCard(walletId, slot)

                if entry and entry.name == itemName
                    and (not citizenid or (type(entry.metadata) == 'table' and entry.metadata.citizenid == citizenid)) then
                    return true
                end
            end
        end
    end

    return false
end

exports('HasCardInWallet', hasCardInWallet)
