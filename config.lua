Config = {}

-- Music range settings
Config.MUSIC_RANGE = 50.0 -- Maximum distance to hear music (meters)
Config.POSITION_UPDATE_RANGE = 60.0 -- Slightly larger range for position updates to prevent cutting out

-- Volume settings
Config.DEFAULT_VOLUME = 50.0 -- Default volume percentage
Config.XSOUND_DISTANCE = 15 -- Distance setting for xSound

-- Position update tiers (speed in mph, wait in ms)
Config.UPDATE_TIERS = {
    { speed = 125, wait = 10,  level = 4 },  -- Very high speed: 20 updates/sec
    { speed = 100, wait = 25, level = 3 },  -- High speed: 10 updates/sec
    { speed = 80,  wait = 50, level = 2 },  -- Medium-high speed: 5 updates/sec
    { speed = 30,  wait = 75, level = 1 },  -- Medium speed: ~3 updates/sec
    { speed = 0,   wait = 500, level = 0 }, -- Low/stationary: 1 update/sec
}

-- Other settings
Config.MIN_DISTANCE_THRESHOLD = 2.0 -- Minimum distance (meters) before sending position update
Config.TIER_STICKY_TIME = 3000 -- Time (ms) to maintain higher tier after speed drops
