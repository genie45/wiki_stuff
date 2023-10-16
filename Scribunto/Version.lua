local Utility = require( 'Module:Utility' )
local legacyModule = require( 'Module:Version/legacy' )


-- TODO: export in Arkitecture (tho we don't need it all loaded) or a support module ~alex
local _Arkitecture__ParameterTypes_Game_CargoTablePrefixes = {
    ['ARK: Survival Evolved'] = 'ASE',
    ['ARK: Survival Ascended'] = 'ASA',
    ['ARK 2'] = 'A2',
}

-- TODO: no mobile handling


---
--- @class VersionRecord
--- @field Platform string
--- @field Major integer
--- @field Minor integer
--- TODO: ...
---

---
--- @class UnloadedVersionToken
--- @field __INCOMPLETE bool
--- @field Platform string
--- @field Major integer
--- @field Minor integer
---


local function parseVersion( str, defaultPlatform )
    if str == nil then
        return nil
    end
    local platform, major, minor = str:match( '(%w+) (%d+)%.(%d+)' )
    if major == nil then
        major, minor = str:match( '(%d+)%.(%d+)' )
    end
    if major == nil or minor == nil then
        return nil
    end
    return {
        __INCOMPLETE = true,
        Platform = platform or defaultPlatform or 'PC',
        Major = major,
        Minor = minor,
    }
end


local function stringifyVersion( record )
    if record.Platform == 'PC' then
        return string.format( '%d.%d', record.Major, record.Minor )
    end
    return string.format( '%s %d.%d', record.Platform, record.Major, record.Minor )
end


local function queryVersionTable( game, options )
    local results = mw.ext.cargo.query(
        game .. '_Patch',
        'Platform, Major, Minor, ClientReleaseDate, ServerReleaseDate',
        options
    )
    for index = 1, #results do
        local result = results[index]
        result.Major = tonumber( result.Major )
        result.Minor = tonumber( result.Minor )
    end
    return results
end


local function findVersion( game, token )
    local results = queryVersionTable(
        game,
        {
            where = string.format(
                'Platform = \'%s\' AND Major = %d AND Minor = %d',
                token.Platform,
                token.Major,
                token.Minor
            ),
        }
    )
    if #results == 0 then
        return nil
    end
    assert( #results == 1, '#results == 1' )
    -- TODO: ideally we'll have an middleware layer here to take care of this based on the abstract schema in Arkit
    results[1].Major = tonumber( results[1].Major )
    results[1].Minor = tonumber( results[1].Minor )
    return results[1]
end


local function findLatestVersion( game, platform )
    local results = queryVersionTable(
        game,
        {
            where = string.format(
                'Platform = \'%s\'',
                platform
            ),
            orderBy = 'GREATEST( COALESCE( ClientReleaseDate, 0 ), COALESCE( ServerReleaseDate, 0 ) ) DESC, '
                .. 'Major DESC, Minor DESC',
            limit = 1,
        }
    )
    assert( #results == 1, '#results == 1' )
    -- TODO: ideally we'll have an middleware layer here to take care of this based on the abstract schema in Arkit
    results[1].Major = tonumber( results[1].Major )
    results[1].Minor = tonumber( results[1].Minor )
    return results[1]
end


return Utility.merge( legacyModule, {
    parseVersion = parseVersion,
    stringifyVersion = stringifyVersion,
    findLatestVersion = findLatestVersion,
    findLatestVersionNameW = function ( frame )
        -- HACK: transition hack
        if frame.args[2] == 'Mobile' then
            return legacyModule.getCurrentVersionName( 'Mobile' )
        end
        return stringifyVersion( findLatestVersion( frame.args[1], frame.args[2] ) )
    end,
    findVersionEarliestReleaseDateW = function ( frame )
        -- HACK: transition hack
        if frame.args[2] == 'Mobile' then
            return legacyModule.getReleaseDate( 'Mobile', legacyModule.getVersionIndex( 'Mobile', frame.args[3] ) )
        end
        -- TODO: needs to actually meet the condition lol ~alex
        local v = findVersion( frame.args[1], parseVersion( frame.args[3], frame.args[2] ) )
        return v.ClientReleaseDate or v.ServerReleaseDate
    end,
} )
