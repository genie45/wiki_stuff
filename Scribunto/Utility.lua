local p = {}
local cache = require( 'mw.ext.LuaCache' )


function p.formatNumberToPlacesMax(num, places)
	return (string.format('%.'..places..'f', num):gsub("%.?0+$", ""))
end


function p.doesFileExist( name )
    local title = mw.title.new( ( IS_ENGLISH_WIKI and 'File:' or 'Media:' ) .. name )
    return title.exists or title.fileExists
end



function p.merge(dst, src)
	for k, v in pairs(src) do
		if v == nil and dst[k] ~= nil then
			dst[k] = nil
		elseif type(dst[k]) == 'table' and type(v) == 'table' then
			dst[k] = p.merge(dst[k], v)
		else
			dst[k] = v
		end
	end
	return dst
end


function p.deepcopy(orig)
	if type(orig) == 'table' then
		local copy = {}
		for k, v in pairs(orig) do
			copy[p.deepcopy(k)] = p.deepcopy(v)
		end
		return copy
	end
	return orig
end


function p.removeDuplicatesFromList(t)
    -- borrowed from: https://www.mediawiki.org/w/index.php?title=Module:TableTools
    if not t then
        return {}
    end
    local ret, exists = {}, {}
    for i, v in ipairs(t) do
        if not exists[v] then
            ret[#ret + 1] = v
            exists[v] = true
        end
    end
    return ret
end


function p.getUnqualifiedBlueprintPath(descriptor)
	-- Return nothing if descriptor is empty.
	if not descriptor then
		return nil
	end
	-- Remove double quotes from beginning and the end.
	if descriptor:sub(1, 1) == '"' then
		descriptor = descriptor:sub(2, -2)
	end
	-- Check if descriptor is a likely clean blueprint path, and exit early.
	local descriptorStart = 'Blueprint\''
	local descriptorEnd = '\''
	if descriptor:sub(1, #descriptorStart) ~= descriptorStart then
		return descriptor
	end
	-- Remove descriptor.
	return descriptor:sub(#descriptorStart+1, -#descriptorEnd-1)
end


function p.getUnqualifiedBlueprintPathW(f)
	return p.getUnqualifiedBlueprintPath(f.args[1]) or ''
end


function p.getBlueprintClassName(blueprintPath, withSuffix)
	-- Return nothing if blueprint path is empty.
	if not blueprintPath then
		return nil
	end
	local className = blueprintPath:match('%.([%w_]+)$')
	if withSuffix and className:sub(-2) ~= '_C' then
		return className .. '_C'
	elseif not withSuffix and className:sub(-2) == '_C' then
		className, _ = className:gsub('_C$', '', 1)
	end
	return className
end


function p.getBlueprintClassNameW(f)
	return p.getBlueprintClassName(f.args[1], not (f.args.withSuffix == '' or f.args.withSuffix == 'no')) or ''
end


function p.getQualifiedBlueprintPath(blueprintPath)
	blueprintPath = p.getUnqualifiedBlueprintPath(blueprintPath)
	if blueprintPath:sub(#blueprintPath-1) == '_C' then
		blueprintPath = blueprintPath:sub(1, -3)
	end
	return '"Blueprint\'' .. blueprintPath .. '\'"'
end


function p.getQualifiedBlueprintPathW(f)
	return p.getQualifiedBlueprintPath(f.args[1]) or ''
end


function p.callCachedFunction( cacheKey, expiryTime, expensiveLogic )
	local cached = cache.get( cacheKey )
	if cached == nil then
	    cached = expensiveLogic()
	    cache.set( cacheKey, cached, expiryTime )
    end
	return cached
end


local inProcessCargoCache = {}
function p.runCachedCargoQuery( cacheKey, options )
	cacheKey = 'Query__' .. cacheKey

    if options.inProcess and inProcessCargoCache[cacheKey] then
        return inProcessCargoCache[cacheKey]
    end

	local cached = cache.get( cacheKey )
	if cached == nil then
	    cached = mw.ext.cargo.query( options.tableName, options.fields, options.options )

        if options.key then
            local map = {}
            local row
            for index = 1, #cached do
                row = cached[index]
                map[row[options.key]] = row
            end
            cached = map
        end

	    cache.set( cacheKey, cached, options.expiryTime )
        if options.inProcess then
            inProcessCargoCache[cacheKey] = cached
        end
    end
	return cached
end


return p
