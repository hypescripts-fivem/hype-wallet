local config = require 'config.shared'

local isOpen = false

---@param key string locale key
---@param kind 'success' | 'error' | 'inform'
local function notify(key, kind)
    lib.notify({ title = locale('notify.title'), description = locale(key), type = kind })
end

--- Card labels are locale keys (or plain text), resolved in the player's own language
---@param card table
---@return table
local function localizeCard(card)
    if type(card) == 'table' and type(card.label) == 'string' then
        card.label = locale(card.label)
    end

    return card
end

---@param list any
local function localizeCards(list)
    if type(list) ~= 'table' then return end

    for i = 1, #list do
        localizeCard(list[i])
    end
end

---@param payload table?
---@return table?
local function localizeWallet(payload)
    if type(payload) == 'table' then
        localizeCards(payload.cards)
        localizeCards(payload.inventory)
    end

    return payload
end

--- `ui.*` locale strings for the interface, without the `ui.` prefix
---@return table<string, string>
local function uiStrings()
    local strings = {}

    for key, value in pairs(lib.getLocales()) do
        if key:sub(1, 3) == 'ui.' then
            strings[key:sub(4)] = value
        end
    end

    return strings
end

local function closeWallet()
    if not isOpen then return end

    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('hype-wallet:server:closed')
end

local function playShowAnimation()
    local animation = config.show.animation
    if not animation then return end

    local ped = cache.ped
    local prop

    lib.requestAnimDict(animation.dict)

    if animation.prop then
        local model = lib.requestModel(animation.prop)
        local coords = GetEntityCoords(ped)

        prop = CreateObject(model, coords.x, coords.y, coords.z + 0.2, true, true, true)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005), 0.1, 0.02, -0.03, -90.0, 170.0, 79.0, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(model)
    end

    TaskPlayAnim(ped, animation.dict, animation.clip, 3.0, -1, -1, 50, 0, false, false, false)
    RemoveAnimDict(animation.dict)

    SetTimeout(animation.duration, function()
        if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
        StopAnimTask(ped, animation.dict, animation.clip, 1.0)
    end)
end

local hideKeybind = lib.addKeybind({
    name = 'hype_wallet_hide_card',
    description = locale('keybind.hide_card'),
    defaultKey = config.show.closeKey,
    onPressed = function()
        SendNUIMessage({ action = 'hideShownCard' })
    end,
})

RegisterNetEvent('hype-wallet:client:open', function(payload)
    if type(payload) ~= 'table' then return end

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = localizeWallet(payload) })
end)

-- Someone nearby showed us a card: display it without taking focus
RegisterNetEvent('hype-wallet:client:showCard', function(card)
    if type(card) ~= 'table' then return end

    SendNUIMessage({
        action = 'showCard',
        data = {
            card = localizeCard(card),
            duration = config.show.duration,
            position = config.show.position,
            closeKey = hideKeybind:getCurrentKey(),
        },
    })
end)

RegisterNetEvent('hype-wallet:client:cardShown', function()
    notify('notify.card_shown', 'success')
    playShowAnimation()
end)

RegisterNUICallback('showCard', function(data, cb)
    local target = lib.getClosestPlayer(GetEntityCoords(cache.ped), config.show.distance, false)

    if not target then
        notify('notify.no_one_nearby', 'error')
        return cb(false)
    end

    TriggerServerEvent('hype-wallet:server:showCard', type(data) == 'table' and data.id, GetPlayerServerId(target))
    cb(true)
end)

---@param result table?
local function walletResult(result)
    if type(result) ~= 'table' then return { ok = false } end
    if result.close then closeWallet() end
    localizeWallet(result.wallet)

    return result
end

RegisterNUICallback('addCard', function(data, cb)
    if type(data) ~= 'table' then return cb({ ok = false }) end

    cb(walletResult(lib.callback.await('hype-wallet:server:addCard', false, data.inventorySlot, data.slot)))
end)

RegisterNUICallback('removeCard', function(data, cb)
    if type(data) ~= 'table' then return cb({ ok = false }) end

    cb(walletResult(lib.callback.await('hype-wallet:server:removeCard', false, data.slot)))
end)

RegisterNetEvent('hype-wallet:client:notify', function(key, kind)
    if type(key) ~= 'string' then return end

    notify(key, kind == 'success' and 'success' or kind == 'inform' and 'inform' or 'error')
end)

-- The interface asks for its texts once it has loaded
RegisterNUICallback('ready', function(_, cb)
    cb(uiStrings())
end)

-- ox_lib reloads the locale in its own handler first; send the new texts after it
AddEventHandler('ox_lib:setLocale', function()
    SetTimeout(0, function()
        SendNUIMessage({ action = 'setLocale', data = uiStrings() })
    end)
end)

RegisterNUICallback('close', function(_, cb)
    isOpen = false
    SetNuiFocus(false, false)
    TriggerServerEvent('hype-wallet:server:closed')
    cb(1)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource and isOpen then
        SetNuiFocus(false, false)
    end
end)

exports('CloseWallet', closeWallet)
