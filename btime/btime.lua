-- Logic transcribed from JavaScript to Lua from Ino at https://github.com/EdenServer/eden-web/blob/develop/client/src/components/Ballista.jsx

_addon.author   = 'Godmode'
_addon.name     = 'btime'
_addon.version  = '1.1.0'

require 'common'

local config =
{
    interval = 1800, -- 30 minutes
    lsmes = false,
    echo = true
}

local tick = 0

function vanaDateToVanaTime(year, month, day, hour, minute)
    hour = hour or 0
    minute = minute or 0
    return (year - 886) * 518400 + (month - 1) * 43200 + (day - 1) * 1440 + hour * 60 + minute
end
  
function vanaDateToTimestamp(year, month, day, hour, minute)
    hour = hour or 0
    minute = minute or 0
    return 1 * ((vanaDateToVanaTime(year, month, day, hour, minute) * 60) / 25 + 1009810800)
end

----------------------------------------------------------------------------------------------------
-- func: main
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
function main(advance)
    local DaysInMoonCycle = 84
    local vanaEpoch = math.floor(((os.time() - 1009810800) * 25) / 60)

    local vanaDate =
    {
        year = math.floor(vanaEpoch / 518400 + 886),
        month = (math.floor(vanaEpoch / 43200) % 12) + 1,
        day = (math.floor(vanaEpoch / 1440) % 30) + 1,
        weekDay = math.floor((vanaEpoch % 11520) / 1440),
        hour = math.floor((vanaEpoch % 1440) / 60),
        minute = math.floor(vanaEpoch % 60),
        dayOfMoon = ((math.floor(vanaEpoch / 1440) + 38) % DaysInMoonCycle) - DaysInMoonCycle / 2,
    }

    advance = advance or 0
    vanaDate.day = vanaDate.day + (vanaDate.day % 2) + advance;
    while vanaDate.day > 30 do
        vanaDate.month = vanaDate.month + 1;
        vanaDate.day = vanaDate.day - 30;
    end
    while vanaDate.month > 12 do
        vanaDate.year = vanaDate.year + 1
        vanaDate.month = vanaDate.month - 12;
    end

    local match = {}
    local case = (vanaDate.day - 1) % 6

    if case == 1 then
        match.zone = 'Jugner'
        if vanaDate.month <= 4 then
          match.team1 = 'SAN'
          match.team2 = 'BAS'
        elseif vanaDate.month <= 8 then
          match.team1 = 'BAS'
          match.team2 = 'WIN'
        else
          match.team1 = 'SAN'
          match.team2 = 'WIN'
        end
    elseif case == 3 then
        match.zone = 'Pashhow'
        if vanaDate.month <= 4 then
          match.team1 = 'BAS'
          match.team2 = 'WIN'
        elseif vanaDate.month <= 8 then
          match.team1 = 'SAN'
          match.team2 = 'WIN'
        else
          match.team1 = 'SAN'
          match.team2 = 'BAS'
        end
    elseif case == 5 then
        match.zone = 'Meriphataud'
        if vanaDate.month <= 4 then
          match.team1 = 'SAN'
          match.team2 = 'WIN'
        elseif vanaDate.month <= 8 then
          match.team1 = 'SAN'
          match.team2 = 'BAS'
        else
          match.team1 = 'BAS'
          match.team2 = 'WIN'
        end
    end

    match.levelCap = 75
    if vanaDate.day < 26 then
      match.levelCap = math.floor((vanaDate.day - 1) / 6) * 10 + 30
    end
  
    match.entryStart = vanaDateToTimestamp(vanaDate.year, vanaDate.month, vanaDate.day - 1, 12)
    match.entryEnd = vanaDateToTimestamp(vanaDate.year, vanaDate.month, vanaDate.day - 1, 22)
    match.start = vanaDateToTimestamp(vanaDate.year, vanaDate.month, vanaDate.day)
    match.finish = vanaDateToTimestamp(vanaDate.year, vanaDate.month, vanaDate.day + 1, 0)

    if os.time() > match.entryEnd then
      return main(2)
    end

    local matchString = string.format(
        "[%s vs %s][Lv%i %s] Signup from %s to %s",
        match.team1,
        match.team2,
        match.levelCap,
        match.zone,
        os.date('%I:%M:%S %p', match.entryStart),
        os.date('%I:%M:%S %p', match.entryEnd)
    )

    if config.echo == true then
        AshitaCore:GetChatManager():QueueCommand(string.format("/echo %s", matchString), 1)
    end
    if config.lsmes == true then
        AshitaCore:GetChatManager():QueueCommand(string.format("/lsmes %s", matchString), 1)
    end
end

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Event called when the addon is being rendered.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()
    local now = os.time()
    if now > tick then
        tick = now + config.interval
        main()
    end
end)

----------------------------------------------------------------------------------------------------
-- func: command
-- desc: Event called when a command was entered.
----------------------------------------------------------------------------------------------------
ashita.register_event('command', function(command, ntype)
    local args = command:args()
    if (args[1] ~= '/btime') then
        return false
    end

    if args[2] == 'show' then
        tick = os.time() + config.interval
        main()
    elseif args[2] == 'echo' then
        config.echo = not config.echo
        print(string.format("/echo settings is: %s", config.lsmes and "ON" or "OFF"))
    elseif args[2] == 'lsmes' then
        config.lsmes = not config.lsmes
        print(string.format("/lsmes SETTING is: %s", config.lsmes and "ON" or "OFF"))
    end
    return true
end)
