return {
    -- Cüzdanı açan envanter itemi
    walletItem = 'wallet',

    -- Cüzdandaki kart yuvası sayısı
    slots = 8,

    -- Cüzdanı açan komut (kapatmak için false)
    command = 'cuzdan',

    -- Kartta özel background tanımlı değilse kullanılacak görsel
    defaultBackground = 'https://i.ibb.co/vxvGzg1/card.png',

    -- Kartı yakındaki oyuncuya gösterme
    show = {
        distance = 3.0,          -- Kartın gösterilebileceği en uzak mesafe
        duration = 7000,         -- Kartın karşı tarafın ekranında kalma süresi (ms)
        position = 'right',      -- Karşı tarafın ekranında kartın çıkacağı taraf: 'right' veya 'left'
        cooldown = 3000,         -- İki gösterme arasındaki bekleme süresi (ms)
        closeKey = 'BACK',       -- Gösterilen kartı erken kapatma tuşu (oyuncu ayarlardan değiştirebilir)

        -- Gösteren oyuncunun animasyonu, kapatmak için false
        animation = {
            dict = 'paper_1_rcm_alt1-9',
            clip = 'player_one_dual-9',
            prop = 'prop_franklin_dl',
            duration = 3000,
        },
    },

    -- Cüzdanda görünecek kartlar; sıralama yuva sırasını belirler.
    -- `label` bir dil anahtarıdır (locales/*.json, `card.*`); düz metin de yazılabilir.
    -- Her karta ayrıca `background = 'https://...'` verilebilir.
    cards = {
        { item = 'card_id',           label = 'card.id',           accent = '#3b82f6' },
        { item = 'card_driver_car',   label = 'card.driver_car',   accent = '#10b981' },
        { item = 'card_driver_motor', label = 'card.driver_motor', accent = '#f59e0b' },
        { item = 'card_driver_boat',  label = 'card.driver_boat',  accent = '#06b6d4' },
        { item = 'card_driver_plane', label = 'card.driver_plane', accent = '#8b5cf6' },
        { item = 'card_weapon',       label = 'card.weapon',       accent = '#ef4444' },
        { item = 'card_taxi',         label = 'card.taxi',         accent = '#eab308' },
    },
}
