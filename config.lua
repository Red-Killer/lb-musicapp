Config = {}

-- Music range settings
Config.MUSIC_RANGE = 50.0 -- Maximum distance to hear music (meters)
Config.POSITION_UPDATE_RANGE = 60.0 -- Slightly larger range for position updates to prevent cutting out

-- Volume settings
Config.DEFAULT_VOLUME = 50.0 -- Default volume percentage
Config.XSOUND_DISTANCE = 15 -- Distance setting for xSound

-- Position update tiers (speed in mph, wait in ms)
Config.UPDATE_TIERS = {
    { speed = 125, wait = 5,   level = 4 },  -- Very high speed: 200 updates/sec
    { speed = 100, wait = 15,  level = 3 },  -- High speed: ~67 updates/sec
    { speed = 75,  wait = 25,  level = 2 },  -- Medium-high speed: 40 updates/sec
    { speed = 25,  wait = 50,  level = 1 },  -- Medium speed: 20 updates/sec
    { speed = 0,   wait = 300, level = 0 },  -- Low/stationary: ~3 updates/sec
}

-- Other settings
Config.MIN_DISTANCE_THRESHOLD = 2.0 -- Minimum distance (meters) before sending position update
Config.TIER_STICKY_TIME = 3000 -- Time (ms) to maintain higher tier after speed drops
