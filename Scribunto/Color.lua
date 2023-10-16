local Utility = require( 'Module:Utility' )

local SQUARE_SIZE = 20


local function parseRgbHex( hex )
    hex = hex:gsub( '#', '' )
    return {
    	tonumber( '0x'..hex:sub( 1, 2 ) ),
    	tonumber( '0x'..hex:sub( 3, 4 ) ),
    	tonumber( '0x'..hex:sub( 5, 6 ) )
    }
end


local function selectTextColor( color )
	return ( color[1] * 0.2126 + color[2] * 0.7152 + color[3] * 0.0722 > ( 0.5 * 255 ) ) and 'black' or 'white'
end


local function queryColorTable( tablePrefix )
    local results = Utility.runCachedCargoQuery( 'ColorTable_' .. tablePrefix, {
        tableName = tablePrefix .. '_Colors',
        fields = 'Id, Name, sRGB',
        expiryTime = 60 * 60 * 8,
        options = {
            orderBy = 'Id ASC',
        },
    } )
    for index = 1, #results do
    	results[index].Id = tonumber( results[index].Id )
   	end
   	return results
end


local function findRecord( records, needle )
    if tonumber( needle ) ~= nil then
        needle = tonumber( needle )
    elseif type( needle ) == 'string' then
        needle = mw.text.trim( string.lower( needle ) )
    end

	for index = 1, #records do
        local record = records[index]
        local compared

        if type( needle ) == 'number' then
            compared = record.Id
        else
            compared = string.lower( record.Name )
        end

		if compared == needle then
			return record
		end
	end

	return nil
end


local function selectSubset( records, needles )
    local out = {}
    local needleMap = {}
    local expectedCount = 0

    for index = 1, #needles do
        local needle = needles[index]
        if tonumber( needle ) ~= nil then
            needle = tonumber( needle )
        elseif type( needle ) == 'string' then
            needle = mw.text.trim( string.lower( needle ) )
        end
        
        if needle ~= '' and needleMap[needle] == nil then
	        needleMap[needle] = true
    	    expectedCount = expectedCount + 1
    	end
    end

    for index = 1, #records do
        local record = records[index]
        if needleMap[record.Id] or needleMap[string.lower( record.Name )] then
            out[#out + 1] = record
        end
    end

    if expectedCount ~= #out then
        --error( 'One or more requested colours had not been found in the table' )
        out[#out + 1] = {
        	Id = 0,
        	Name = 'Unset',
        	sRGB = '00000000'
        }
    end

	return out
end


local function makeColoredSquares( records )
    local out = {}

    table.sort( records, function ( a, b ) return a.Id < b.Id end )

    for index = 1, #records do
        local record = records[index]
        out[#out + 1] = string.format(
        	'<div class="color-square" style="height: %dpx; width: %dpx; background: #%s; color: %s" '
                .. 'title="%s (%d)"><span>%d</span></div>',
            SQUARE_SIZE,
            SQUARE_SIZE,
            record.sRGB,
            selectTextColor( parseRgbHex( record.sRGB ) ),
            record.Name,
    	    record.Id,
    	    record.Id
        )
    end

    return string.format( '<div class="color-container">%s</div>', table.concat( out, '' ) )
end


return {
    parseRgbHex = parseRgbHex,
    selectTextColor = selectTextColor,
    queryColorTable = queryColorTable,
    findRecord = findRecord,
    selectSubset = selectSubset,
    makeColoredSquares = makeColoredSquares,

    selectTextColorW = function ( frame )
        return selectTextColor( parseRgbHex( frame.args[1] ) )
    end,

    queryW = function ( frame )
        local record = findRecord( queryColorTable( 'ASE' ), frame.args[1] )
        if record == nil then
            error( 'Color not found: ' .. frame.args[1] )
        end
        return record[frame.args[2]]        
    end,

    makeColoredSquaresW = function ( frame )
        local colors = mw.text.split( frame.args[1], ',', true )
        local records = selectSubset( queryColorTable( 'ASE' ), colors )
        return makeColoredSquares( records )
    end,
}
