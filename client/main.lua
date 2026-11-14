local config = require 'config.shared'

local isOpen = false

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
    description = 'Gösterilen kartı kapat',
    defaultKey = config.show.closeKey,
    onPressed = function()
        SendNUIMessage({ action = 'hideShownCard' })
    end,
})

RegisterNetEvent('hype-wallet:client:open', function(payload)
    if type(payload) ~= 'table' then return end

    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = payload })
end)

-- Someone nearby showed us a card: display it without taking focus
RegisterNetEvent('hype-wallet:client:showCard', function(card)
    if type(card) ~= 'table' then return end

    SendNUIMessage({
        action = 'showCard',
        data = {
            card = card,
            duration = config.show.duration,
            position = config.show.position,
            closeKey = hideKeybind:getCurrentKey(),
        },
    })
end)

RegisterNetEvent('hype-wallet:client:cardShown', function()
    lib.notify({ title = 'Cüzdan', description = 'Kartını yakınındaki kişiye gösterdin.', type = 'success' })
    playShowAnimation()
end)

RegisterNUICallback('showCard', function(data, cb)
    local target = lib.getClosestPlayer(GetEntityCoords(cache.ped), config.show.distance, false)

    if not target then
        lib.notify({ title = 'Cüzdan', description = 'Yakınında kartı gösterebileceğin kimse yok.', type = 'error' })
        return cb(false)
    end

    TriggerServerEvent('hype-wallet:server:showCard', type(data) == 'table' and data.id, GetPlayerServerId(target))
    cb(true)
end)

---@param result table?
local function walletResult(result)
    if type(result) ~= 'table' then return { ok = false } end
    if result.close then closeWallet() end

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
