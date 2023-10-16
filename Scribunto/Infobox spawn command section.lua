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


function p.renderUnwrapped( metaClassType, targets )
    if #targets == 0 then
        return nil
    end

    local results = {}
    local isEntity = metaClassType == ClassType.ENTITY

    for index = 1, #targets do
        local target = targets[index]

        if target.name ~= '' and target.blueprintPath ~= '' then
            local html = {}

    		if target.note ~= nil then
	    		html[#html + 1] = target.note
		    end
    		html[#html + 1] = makeCommandSet( isEntity, target.blueprintPath, target.short, target.tekgram, target.itemId )

            results[#results + 1] = {
                target.name,
                table.concat( html, '\n\n' )
            }
        end
    end

    if #results == 0 then
        return nil
    end

    return results
end


-- Arkitexure invoked entrypoint
function p.spawnCommand( f )
	local args = f.args
	local parentArgs = f:getParent().args

	-- Infobox arguments
	local blueprintPath = guardStringArgument(parentArgs, 'blueprintpath')
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
		-- Reduce to null if empty.
		if blueprintPath == '' then
			blueprintPath = nil
		end
	end
	
	-- Remove object descriptor elements from the blueprint path if one is valid.
	if blueprintPath ~= nil then
		blueprintPath = Utility.getUnqualifiedBlueprintPath(blueprintPath)
	end
	
    local targets = {}
    local isFirstBase = false
	
	-- Main class
	if (not isBaseClassIncomplete) and (blueprintPath or entityId or shortItemName) then
        isFirstBase = true
        targets[1] = {
            name = 'Main spawn target, this name will not be displayed',
            blueprintPath = blueprintPath,
            short = shortItemName,
            itemId = itemId,
            tekgram = tekgram,
            note = baseNote
        }
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
		elseif (not isEntity) and mw.ustring.find(argName, 'gfi ', 0, true) == 1 then
			variantName = mw.ustring.sub(argName, 4)
		end
		
		if variantName ~= nil then
			variantName = mw.text.trim(variantName)
			if variantName ~= '' then
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
					variants[variantName].bp = tempVariantBP
				else
					variants[variantName].short = mw.text.trim(argValue)
				end
			end
		end
	end
	
    -- Convert our variants collection into Spawnables
    for index = 1, #variantOrder do
        local variantName = variantOrder[index]
        local variantInfo = variants[variantName]
        targets[#targets + 1] = {
            name = variantName,
            blueprintPath = variantInfo.bp,
            short = variantInfo.short,
        }
    end

    local results = p.renderUnwrapped( isEntity and ClassType.ENTITY or ClassType.ITEM, targets )
	-- Return nothing if no command was generated
	if results == nil then
		return ''
	end

    local html = {}
    
    html[#html + 1] = '<div class="info-arkitex info-module">'
    html[#html + 1] = '<div class="info-arkitex info-unit">'
    html[#html + 1] = '<div class="info-arkitex info-X1-100">'
    html[#html + 1] = '<div style="text-align:left; padding:0 8px 0 8px;" class="mw-collapsible mw-collapsed">' .. "'''[[" .. captionLinkTarget .. "|Spawn Command]]'''"
    html[#html + 1] = '<div class="mw-collapsible-content" style="text-align:left;font-size:0.8em;word-wrap:break-word;width:310px">'

    for index = 1, #results do
        local result = results[index]
        html[#html + 1] = '<div class="info-arkitex-spawn-commands-entry">'
        if not ( isFirstBase and index == 1 ) then
            html[#html + 1] = '<p style="font-size:1.1em;font-weight:bold;">Variant ' .. result[1] .. '</p>'
        end
        html[#html + 1] = result[2]
        html[#html + 1] = '</div>'
    end
	
    html[#html + 1] = '</div>'
    html[#html + 1] = '</div>'
    html[#html + 1] = '</div>'
    html[#html + 1] = '</div>'
    html[#html + 1] = '</div>'

	return table.concat( html, '' )
end


return p
