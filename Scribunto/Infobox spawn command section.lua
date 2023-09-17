local Utility = require('Module:Utility')

local p = {}


local function copyClipboard( contents )
	return '<code class="copy-clipboard"><span class="copy-content">' .. contents .. '</span></code>'
end


local function getExampleShortCommand( isEntity, identifier )
	if isEntity then
		return 'cheat summon ' .. identifier
	else
		return 'cheat gfi ' .. identifier .. ' 1 0 0'
	end
end


local function getExampleBPCommand( isEntity, identifier, short )
	if isEntity then
		return string.format( 'cheat SpawnDino %s 500 0 0 35', Utility.getQualifiedBlueprintPath( identifier ) )
	else
		return string.format( 'cheat giveitem %s 1 0 0', Utility.getQualifiedBlueprintPath( identifier ) )
	end
end


local function getTekgramUnlockCommand( bp )
	return string.format( 'cheat unlockengram %s', Utility.getQualifiedBlueprintPath( bp ) )
end

local function getIdBasedItemCommand( identifier )
	return 'cheat giveitemnum ' .. identifier .. ' 1 0 0'
end


local function makeCommandSet( isEntity, blueprintPath, shortItemName, tekgramBP, itemId )
	local OR = '<br/><b>or</b><br/>'
	
	local commands = ''
	local canShowSummon = isEntity and blueprintPath ~= nil
	local canShowGFI = not isEntity and shortItemName ~= nil
	
	-- ID-based item command
	if not isEntity and itemId then
		commands = copyClipboard(getIdBasedItemCommand(itemId))
		if blueprintPath or shortItemName then
			commands = commands .. OR
		end
	end
	
	-- Loose, short commands
	if canShowSummon then
		commands = commands .. copyClipboard( getExampleShortCommand( true, Utility.getBlueprintClassName(
            blueprintPath, true ) ) )
	elseif canShowGFI then
		commands = commands .. copyClipboard(getExampleShortCommand(false, shortItemName))
	end
		
	-- "or" between the two forms
	if blueprintPath and (canShowSummon or canShowGFI) then
		commands = commands .. OR
	end
		
	-- Strict, BP-reliant command
	if blueprintPath then
		commands = commands .. copyClipboard(getExampleBPCommand(isEntity, blueprintPath))
	end
	
	if tekgramBP then
		commands = commands .. '<br/><b>Unlock [[Tekgram]]</b><br/>'
				   .. copyClipboard(getTekgramUnlockCommand(tekgramBP))
	end
	
	return commands
end


local function guardStringArgument( args, name )
	local v = args[name] or nil
	if v ~= nil then
		v = mw.text.trim(v)
		if #v == 0 then
			v = nil
		end
	end
	return v
end


---
--- @class Spawnable
--- @field name string
--- @field blueprintPath ?string
--- @field short ?string
--- @field itemId ?number
--- @field tekgram ?string
--- @field note ?string
---


local ClassType = {
    ITEM = 0,
    ENTITY = 1,
}
p.ClassType = ClassType


function p.makeUnwrapped( metaClassType, targets, isFirstBase )
    if #targets == 0 then
        return nil
    end

    local html = {}
    local isEntity = metaClassType == ClassType.ENTITY

    for index = 1, #targets do
        local target = targets[index]

        if not ( isFirstBase and index == 1 ) then
            html[#html + 1] = '<span style="font-size:1.1em;font-weight:bold;">Variant ' .. target.name .. '</span><br/>'
        end

		if target.note ~= nil then
			html[#html + 1] = target.note .. '<br/>\n'
		end

		html[#html + 1] = makeCommandSet( isEntity, target.blueprintPath, target.short, target.tekgram, target.itemId )
    end

    local out = table.concat( html, '' )
    if out == '' then
        return nil
    end
    return out
end


function p.spawnCommand( f )
	local args = f.args
	local parentArgs = f:getParent().args

	-- Infobox arguments
	local blueprintPath = guardStringArgument(parentArgs, 'blueprintpath')
	local entityClassName = guardStringArgument(parentArgs, 'entityId')
	local shortItemName = guardStringArgument(parentArgs, 'gfi')
	local tekgram = guardStringArgument(parentArgs, 'tekgram')
	local itemId = guardStringArgument(parentArgs, 'itemid')
	local incompleteBaseClassArg = parentArgs.incompleteBaseClass or parentArgs.incompleteData or args.baseClassIsTemplate
	local isBaseClassIncomplete = incompleteBaseClassArg ~= nil and incompleteBaseClassArg:lower() == 'yes' or false
	local baseNote = guardStringArgument(parentArgs, 'spawncommandnote')

	-- Check if type is specified
	if args.type == nil then
		return 'error: "type" has to be specified (creature or item) for spawn command section to be generated'
	end
	
	-- Own hardcoded arguments
	local isEntity = args.type == 'creature'
	local captionLinkTarget = args.linkTarget or ''
	local variantOrderList = args.variantOrder or ''
	
	-- Fill in info from variables set by Dv if creature
	if isEntity then
		if blueprintPath == nil then
			blueprintPath = mw.ext.VariablesLua.var( 'blueprintpath' )
		end
		if entityClassName == nil then
			entityClassName = mw.ext.VariablesLua.var( 'entityId' )
		end
		-- Reduce to null if empty.
		if blueprintPath == '' then
			blueprintPath = nil
		end
		if entityClassName == '' then
			entityClassName = nil
		end
	end
	
	-- Remove object descriptor elements from the blueprint path if one is valid.
	if blueprintPath ~= nil then
		blueprintPath = Utility.getUnqualifiedBlueprintPath(blueprintPath)
	end
	
	-- Auto-generate class name for entities
	if isEntity and entityClassName == nil and blueprintPath ~= nil then
		entityClassName = Utility.getBlueprintClassName(blueprintPath, true)
	end
	
	-- Display flags
	local canShowSummon = isEntity and entityClassName ~= nil
	local canShowGFI = not isEntity and shortItemName ~= nil

	-- Variable for generated commands text
	local commands = ''
	
	-- Main class
	if (not isBaseClassIncomplete) and (blueprintPath or entityId or shortItemName) then
		commands = makeCommandSet(isEntity, blueprintPath, shortItemName, tekgram, itemId)
		if baseNote ~= nil then
			commands = baseNote .. '<br/>\n' .. commands
		end
	end
	
	-- Initialize variants from variantOrderList
	-- We use an external list provided by the template to retain order of the variants.
	local variants = {}
	local variantOrder = {}
	if variantOrderList ~= '' then
		for _, variantName in ipairs(mw.text.split(variantOrderList, ';')) do
			if variants[variantName] == nil then
				variants[variantName] = {}
				table.insert(variantOrder, variantName)
			end
		end
	end
	
	-- Collect variants (and their details) from arguments
	for argName, argValue in pairs(parentArgs) do
		argName = mw.text.trim(argName)
		local variantName = nil
		local isBP = false
		
		-- Detect if this parameter is a BP/short ID
		if mw.ustring.find(argName, 'blueprintpath ', 0, true) == 1 then
			variantName = mw.ustring.sub(argName, 14)
			isBP = true
		elseif isEntity and mw.ustring.find(argName, 'entityId ', 0, true) == 1 then
			variantName = mw.ustring.sub(argName, 9)
		elseif (not isEntity) and mw.ustring.find(argName, 'gfi ', 0, true) == 1 then
			variantName = mw.ustring.sub(argName, 4)
		end
		
		if variantName ~= nil then
			variantName = mw.text.trim(variantName)
			if #variantName > 0 then
				-- Ensure the variant is initialized.
				if variants[variantName] == nil then
					variants[variantName] = {}
					table.insert(variantOrder, variantName)
				end
			
				-- Save the value.
				if isBP then
					local tempVariantBP = mw.text.trim(argValue)
					if tempVariantBP ~= nil then
						-- Remove object descriptor from the blueprint path.
						tempVariantBP = Utility.getUnqualifiedBlueprintPath(tempVariantBP)
					end
					variants[variantName]['bp'] = tempVariantBP
				else
					variants[variantName]['short'] = mw.text.trim(argValue)
				end
			end
		end
	end
	
	-- Generate commands for variants
	local firstRendered = isBaseClassIncomplete
	for index, variantName in ipairs(variantOrder) do
		local spawnInfo = variants[variantName]
		-- Auto-generate class name for entities
		if isEntity and spawnInfo.bp and not spawnInfo.short then
			spawnInfo.short = Utility.getBlueprintClassName(spawnInfo.bp, true)
		end
		
		if spawnInfo.bp or spawnInfo.short then
			if not firstRendered then
				commands = commands .. '<br/>'
			end
			firstRendered = false
			commands = commands .. '<span style="font-size:1.1em;font-weight:bold;">Variant ' .. variantName .. '</span><br/>'
			commands = commands .. makeCommandSet(isEntity, spawnInfo.bp, spawnInfo.short)
		end
	end

	-- Return nothing if no command was generated
	if #commands == 0 then
		return ''
	end
	
	local out = '<div class="info-arkitex info-module">'
				.. '<div class="info-arkitex info-unit">'
				   .. '<div class="info-arkitex info-X1-100">'
				      .. '<div style="text-align:left; padding:0 8px 0 8px;" class="mw-collapsible mw-collapsed">' .. "'''[[" .. captionLinkTarget .. "|Spawn Command]]'''"
				    	 .. '<div class="mw-collapsible-content" style="text-align:left;font-size:0.8em;word-wrap:break-word;width:310px">'
				    		.. commands
				    	 .. '</div>'
				      .. '</div>'
				   .. '</div>'
				.. '</div>'
			 .. '</div>'
	return out
end


return p
