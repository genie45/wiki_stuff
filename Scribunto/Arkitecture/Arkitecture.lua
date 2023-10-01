---
--- Arkitecture
--- =====
---
--- This module performs infobox rendering on the ARK Wiki, validating data and managing Cargo tables. This is a
--- replacement for the old wikitext-based Arkitexure model.
---
--- In this model, there are three primary types of units:
---
--- - Components: Small, stateless, self-contained objects that generate HTML (and virtual Arkitecture units) from
---   information in an instance.
---
--- - Infoboxes: TODO
---
--- @author [[User:alex4401]] (https://github.com/alex4401)
---

local Utility = require( 'Module:Utility' )


-- TODO: move to Utility
local function appendTable( target, values )
    for index = 1, #values do
        target[#target + 1] = values[index]
    end
end


-- #region Class abstraction
local function Class( constructor, parent )
    local methods
    if parent ~= nil then
        methods = Utility.deepcopy( parent.methods )
    else
        methods = {}
    end
    if constructor == nil and parent ~= nil then
        constructor = parent.constructor
    end
	local class = {
        constructor = constructor,
        parent = parent,
        methods = methods,
        new = function ( self, ... )
            local inst = { mt = {
                class = self,
                __index = self.methods,
                __tostring = self.methods.toString
            } }
            setmetatable( inst, inst.mt )
            if self.constructor ~= nil then
                self.constructor( inst, unpack( {...} ) )
            end
            return inst
        end
	}
    setmetatable( class, { __call = class.new } )
    return class
end
-- #endregion


-- #region HTML/wikitext building

local FILE_EXISTS_TITLE_PREFIX = string.upper( mw.language.getContentLanguage():getCode() ) == 'en' and 'File:'
    or 'Media:'

-- @param table spec Consists of:
--     - name: string
--     - fallback: string, optional
--     - width: number
local function File( spec )
    if spec.fallback then
        if not spec.name or mw.title.new( FILE_EXISTS_TITLE_PREFIX .. spec.name ).exists then
            spec.name = spec.fallback
        end
    end

    local attrs = {}
    if spec.link ~= nil then
        attrs[#attrs + 1] = 'link=' .. ( spec.link or '' )
    end
    if spec.altText ~= nil then
        attrs[#attrs + 1] = 'alt=' .. ( spec.altText or '' )
    end

    -- Normalise file name. This is rather slow.
    spec.name = spec.name:gsub( '/sandbox', '' ):gsub( '[:/]', '_' ):gsub( '__', '_' )

    -- Choose a specialised format template and build the final element
    if #attrs == 0 then
        return string.format( '[[File:%s|%spx]]', spec.name, spec.width )
    else
        return string.format( '[[File:%s|%spx|%s]]', spec.name, spec.width, table.concat( attrs, '|' ) )
    end
end


local function Link( spec )
    if type( spec ) == 'string' then
        spec = { target = spec, label = spec }
    end
    if spec == nil or spec.target == nil then
        return ''
    end
    return string.format( '[[%s|%s]]', spec.target, spec.label )
end


local function JoinCategory( spec )
    if type( spec ) == 'string' then
        spec = { target = spec }
    end
    if spec == nil or spec.target == nil then
        return ''
    end
    if spec.sortKey then
        return string.format( '[[Category:%s|%s]]', spec.target, spec.sortKey )
    end
    return string.format( '[[Category:%s]]', spec.target )
end


local LOCAL_TRANSLATABLE_KEY = string.upper( mw.language.getContentLanguage():getCode() )
local function Translatable( variants )
    return variants[LOCAL_TRANSLATABLE_KEY] or variants[1]
end

local function Date( date )
    if not date or date == '' then
        return ''
    end
    return mw.language.getContentLanguage():formatDate( 'M j, Y', date )
end


local Html
Html = {
    ---
    --- @class HtmlElementOptions: string[]
    --- HTML element options.
    --- @see Html.Element
    --- @field tag string Tag name.
    --- @field classes? string|string[] CSS classes.
    --- @field attributes? { [string]: string|number } Element attributes.
    ---


    ---
    --- Constructs an HTML element string.
    ---
    --- @param spec HtmlElementOptions
    Element = function ( spec )
        if not spec.tag then
            error( 'HtmlElement must have a tag specified' )
        end

        -- Combine all children into a single string
        local inner = table.concat( spec, '' )

        return string.format( '%s%s</%s>', Html.StartElement( spec ), inner, spec.tag )
    end,


    StartElement = function ( spec )
        if not spec.tag then
            error( 'HtmlElement must have a tag specified' )
        end

        -- Combine all classes into a single string if table
        if type( spec.classes ) == 'table' then
            spec.classes = table.concat( spec.classes, ' ' )
        end

        -- Build an attributes string
        local attrs
        if spec.attributes then
            attrs = {}
            for name, value in pairs( spec.attributes ) do
                attrs[#attrs + 1] = string.format( '%s="%s"', name, tostring( value ) )
            end
            attrs = table.concat( attrs, ' ' )
        end

        -- Choose a specialised format template and build the final element
        if spec.attributes and spec.classes then
            return string.format( '<%s class="%s" %s>', spec.tag, spec.classes, attrs )
        elseif spec.attributes then
            return string.format( '<%s %s>', spec.tag, attrs )
        elseif spec.classes then
            return string.format( '<%s class="%s">', spec.tag, spec.classes )
        end
        return string.format( '<%s>', spec.tag )
    end,

    --- HTML new line (br element) as a string.
    NewLine = '<br/>',

    Space = '&#32;',
    NonBreakingSpace = '&nbsp;',

    --- Faster, but not extensible <small> tag generator.
    ---
    --- @see Html.Element
    --- @param inner string
    Small = function ( inner )
        return string.format( '<small>%s</small>', inner )
    end,
}


--- @deprecated
local function HtmlElement( spec )
    return Html.Element( spec )
end
-- #endregion


-- #region Components
local Component = function ( implementation )
    -- TODO: don't really need a class here at the moment as we don't inject methods
    if not implementation.render then
        error( 'Method render not implemented on a component.' )
    end
    return implementation
end


local RendererContext = Class( function ( self, renderer )
    self.renderer = renderer
end )
    function RendererContext.methods.getParameter( self, name )
        return self.renderer:getParameter( name )
    end
    function RendererContext.methods.hasParameterValueUnchecked( self, name )
        return self.renderer:hasParameterValueUnchecked( name )
    end
    function RendererContext.methods.expandComponent( self, instance )
        return self.renderer:expandComponent( instance )
    end
    function RendererContext.methods.getCargoTablePrefix( self, instance )
        return self.renderer:getCargoTablePrefix( instance )
    end


local ComponentContext = Class( function ( self, renderer, instance )
    self._renderer = renderer
    self.instance = instance
end )
    function ComponentContext.methods.expandComponent( self, instance )
        return self._renderer:expandComponent( instance )
    end
    function ComponentContext.methods.callParserFunction( self, name, args )
        return self._renderer.parentFrame:callParserFunction( name, args )
    end
    function ComponentContext.methods.getCargoTablePrefix( self )
        return self._renderer:getCargoTablePrefix()
    end
-- #endregion


-- #region Parameter handling
local ParameterTypes = {
    STRING = '_M_PT_STRING',
    CLASS_PATH = '_M_PT_CLASS_PATH',
    BOOL = '_M_PT_BOOL',
    NUMBER = '_M_PT_NUMBER',
    INTEGER = '_M_PT_NUMBER_INT',
    GAME_VERSION = '_M_PT_GVER',
    DATE = '_M_PT_DATE',
    GAME = {
        '_M_PT_STRING',
        AllowedValues = {
            'ARK: Survival Evolved',
            'ARK: Survival Ascended',
            'ARK 2',
        },
        _CargoTablePrefixes = {
            ['ARK: Survival Evolved'] = 'ASE',
            ['ARK: Survival Ascended'] = 'ASA',
            ['ARK 2'] = 'A2',
        }
    },
}
local ParameterConstraints = {
    ONLY_ONE = ( function ( params )
        -- TODO: implement
        return true
    end ),
}


-- #endregion


-- #region Renderer
local DEFAULT_COMPONENTS = {}


local Renderer = Class( function ( self )
    self.frame = mw.getCurrentFrame()
    self.parentFrame = self.frame:getParent()
    self.componentRegistry = {}
    self._parameterCacheKeySet = {}
    self.template = self.mt.class.template or nil

    for name, interfaceImplementation in pairs( DEFAULT_COMPONENTS ) do
        self:registerComponent( name, interfaceImplementation )
    end

    if self.template.RequiredLibraries then
        for index = 1, #self.template.RequiredLibraries do
            for name, interfaceImplementation in pairs( require( self.template.RequiredLibraries[index] ) ) do
                self:registerComponent( name, interfaceImplementation )
            end
        end
        self.template.RequiredLibraries = nil
    end

    if self.template.PrivateComponents then
        for name, interfaceImplementation in pairs( self.template.PrivateComponents ) do
            self:registerComponent( name, interfaceImplementation )
        end
        self.template.PrivateComponents = nil
    end
end )
    function Renderer.methods._normaliseParameter( self, paramSpec, value )
        if value == nil then
            return paramSpec.Default
        end

        if type( paramSpec ) == 'string' then
            paramSpec = { paramSpec }
        end

        value = mw.text.trim( value )

        if paramSpec[1] == ParameterTypes.BOOL then
            value = mw.ustring.lower( value )
            -- TODO: move the LUT to avoid making a new one each time we reach this condition
            return ( {
                yes = true,
                [1] = true,
                no = false,
                [0] = false,
            } )[value]
        elseif paramSpec[1] == ParameterTypes.NUMBER or paramSpec[1] == ParameterTypes.INTEGER then
            value = tonumber( value )
        end

        return value
    end
    function Renderer.methods.hasParameterValueUnchecked( self, name )
        -- Still expensive as we're accessing the argument value via frame, but skip normalisation, and unlike
        -- getParameter this is NOT cached. Therefore this does not care about any mutations later on.
        local value = self._parameterCache[name] or self.frame.args[name] or self.parentFrame.args[name]
        if value ~= nil then
            value = mw.text.trim( value )
            value = value ~= ''
        else
            value = false
        end
        return value
    end
    function Renderer.methods._injectParameters( self, tbl )
        if tbl ~= nil then
            for name, value in pairs( tbl ) do
                if name ~= '__NEXT' then
                    self._parameterCache[name] = value
                end
            end
            if tbl.__NEXT ~= nil then
                self:_injectParameters( tbl.__NEXT() )
            end
        end
    end
    function Renderer.methods.getParameter( self, name )
        if not self._parameterCacheKeySet[name] then
            if not self._parameterCache then
                self._parameterCache = {}
                if self.template.injectParameters then
                    self:_injectParameters( self.template:injectParameters( RendererContext( self ) ) )
                end
            end

            -- Retrieve the parameter value from our parameter cache (this will only succeed on injected parameters),
            -- module call frame, or template frame (in that order).
            local value = self._parameterCache[name] or self.frame.args[name] or self.parentFrame.args[name]
            if value == nil then
                local lowerCaseName = name:lower()
                if lowerCaseName ~= name then
                    value = self.frame.args[lowerCaseName] or self.parentFrame.args[lowerCaseName]
                end
            end

            local config = self.template.Parameters[name]
            if config == nil then
                error( 'Attempted to access an undefined parameter: ' .. name )
            end

            self._parameterCache[name] = self:_normaliseParameter( config, value )
            self._parameterCacheKeySet[name] = true
        end
        return self._parameterCache[name]
    end
    function Renderer.methods.getParameterDetached( self, config, name )
        local value = self.frame.args[name] or self.parentFrame.args[name]
        return self:_normaliseParameter( config, value )
    end
    function Renderer.methods.registerComponent( self, name, interfaceImplementation )
        self.componentRegistry[name] = interfaceImplementation
    end
    function Renderer.methods.render( self )
        local html = {}

        local units = self.template.getSetup( self.template, RendererContext( self ) )
        for index = 1, #units do
            local unit = units[index]

            if unit.SideEffect then
                -- Render these nodes directly into output
                self:_processNodeSet( html, unit )
            elseif unit ~= nil then
                -- Render the nodes into a separate HTML list
                local unitHtml = {}
                self:_processNodeSet( unitHtml, unit )

                if #unitHtml > 0 then
                    self:_wrapUnit( unit, unitHtml, html )
                end
            end
        end

        return self:_wrapResult( table.concat( html, '' ) )
    end
    function Renderer.methods._wrapResult( self, inHtml )
        return inHtml
    end
    function Renderer.methods._wrapUnit( self, unit, inHtml, outHtml )
        appendTable( outHtml, inHtml )
    end
    function Renderer.methods._processNodeSet( self, html, unit )
        if not unit then
            return
        elseif type( unit ) == 'string' then
            html[#html + 1] = unit
            return
        elseif unit.__VIRTUAL then
            return
        elseif unit.Component then
            html[#html + 1] = self:expandComponent( unit )
            return
        end
        for index = 1, #unit do
            self:_processNodeSet( html, unit[index] )
        end
    end
    function Renderer.methods.expandComponent( self, instance, customRegistry )
        local componentSingleton = ( customRegistry and customRegistry.componentRegistry[instance.Component] )
            or self.componentRegistry[instance.Component]
        if componentSingleton == nil then
            error( 'Infobox requires component but component not registered: ' .. instance.Component )
        end
        local rendered = componentSingleton:render( ComponentContext( self, instance ), instance )
        if rendered == '' then
            return nil
        elseif type( rendered ) == 'table' then
            rendered = table.concat( rendered, '' )
        end
        return rendered
    end
    function Renderer.methods.getCargoTablePrefix( self, skip )
        if skip then
            return ''
        end
        if self._cargoTablePrefix == nil then
            local out = self:getParameterDetached( { ParameterTypes.STRING, Optional = true }, 'tablePrefix' )

            if out == nil and self.template.Parameters.game == ParameterTypes.GAME then
                local game = self:getParameterDetached( ParameterTypes.GAME, 'game' )
                if game ~= nil then
                    out = ParameterTypes.GAME._CargoTablePrefixes[game]
                end
            end

            if out ~= nil then
                out = out .. '_'
            else
                out = ''
            end

            self._cargoTablePrefix = out
        end
        return self._cargoTablePrefix
    end
    function Renderer.methods.makeCargoTables( self )
        local out = {}
        
        for tableName, tableSpec in pairs( self.template.CargoSetup ) do
            local params = {
                '_table=' .. self:getCargoTablePrefix( tableSpec.Unprefixed ) .. tableName,
            }

            for index = 1, #tableSpec do
                local columnSpec = tableSpec[index]
                local columnName = columnSpec[1]
                local columnType = columnSpec[2]

                local flags = {}
                if not columnSpec.Optional then
                    flags[#flags + 1] = 'mandatory'
                end

                params[#params + 1] = string.format( '%s = %s (%s)', columnName, columnType,
                    table.concat( flags, '; ' ) )
            end

            out[#out + 1] = self.frame:callParserFunction( '#cargo_declare', params )
        end

        return table.concat( out )
    end


local InfoboxRenderer = Class( nil, Renderer )
    function InfoboxRenderer.methods._wrapResult( self, inHtml )
        return Html.Element{
            tag = 'div',
            classes = 'arkitect noexcerpt',
            attributes = {
                role = 'region',
            },
            inHtml,
        }
    end
    function InfoboxRenderer.methods._wrapUnit( self, unit, inHtml, outHtml )
        -- Determine if this unit should be made collapsible by the user. At least four components are
        -- required inside. JavaScript is needed for collapsibles to work.
        local isCollapsible = unit.Collapsible == true or ( unit.Collapsible ~= false and #inHtml > 3 )
        -- Render a container for the unit and concatenate unit's HTML list into the main one. This should
        -- be fairly cheap as strings are passed by reference in Lua.
        local unitTagSpec = {
            tag = 'div',
            classes = {
                'arkitect-unit',
            },
        }
        if isCollapsible then
            unitTagSpec.classes[2] = unit.CollapsedByDefault and 'arkitect-is-collapsed' or nil
            unitTagSpec.attributes = {
                ['data-arkitecture-collapsible'] = true,
            }
        end
        outHtml[#outHtml + 1] = Html.StartElement( unitTagSpec )
        if unit.Caption then
            outHtml[#outHtml + 1] = HtmlElement{
                tag = 'div',
                classes = 'arkitect-unit-caption',
                unit.Caption,
            }
        end
        appendTable( outHtml, inHtml )
        outHtml[#outHtml + 1] = '</div>'
    end


local function makeRenderer( template )
    local __templateBoundRendererImpl = Class( nil, Renderer )
        __templateBoundRendererImpl.template = template
        function __templateBoundRendererImpl.render()
            return __templateBoundRendererImpl():render()
        end
        function __templateBoundRendererImpl.makeCargoTables()
            return __templateBoundRendererImpl():makeCargoTables()
        end
    return __templateBoundRendererImpl
end


local function makeInfoboxRenderer( template )
    local __templateBoundRendererImpl = Class( nil, InfoboxRenderer )
        __templateBoundRendererImpl.template = template
        function __templateBoundRendererImpl.render()
            return __templateBoundRendererImpl():render()
        end
        function __templateBoundRendererImpl.makeCargoTables()
            return __templateBoundRendererImpl():makeCargoTables()
        end
    return __templateBoundRendererImpl
end

-- #endregion


-- #region Cargo
local Cargo = {
    ColumnTypes = {
        INTEGER = 'Integer',
        FLOAT = 'Float',
        STRING = 'String',
        TEXT = 'Text',
        BOOL = 'Boolean',
        DATE = 'Date',
    }
}

-- TODO: extract as much logic as possible
DEFAULT_COMPONENTS.NewCargoRow = Component{
    render = function ( self, ctx )
        local params = {
            '_table = ' .. ctx:getCargoTablePrefix() .. ctx.instance.Table,
        }

        -- TODO: private field access, shouldn't really have this dependency here
        local tableSpec = ctx._renderer.template.CargoSetup[ctx.instance.Table]
        if tableSpec == nil then
            error( 'Attempted to add a row to an unknown Cargo table: ' .. ctx.instance.Table )
        end

        for index = 1, #tableSpec do
            local columnSpec = tableSpec[index]
            local columnName = columnSpec[1]
            local columnType = columnSpec[2]

            local value = ctx.instance[columnName]

            if value ~= nil then
                if columnType == Cargo.ColumnTypes.BOOL then
                    value = value == true and '1' or value == false and '0' or nil
                end
                -- TODO: implement more conversions
            end

            if value == nil and columnSpec.Default ~= nil then
                value = columnSpec.Default
            end
            if value == nil and not columnSpec.Optional then
                error( string.format( 'Found validation errors when inserting a row into Cargo table %s: column %s' ..
                    'required but value not given.', ctx.instance.Table, columnName ) )
            end

            if not ( value == nil and columnSpec.Optional ) then
                if type( value ) ~= 'string' then
                    value = tostring( value )
                end

                params[#params + 1] = string.format( '%s = %s', columnName, value )
            end
        end

        return ctx:callParserFunction( '#cargo_store', params )
    end
}

-- #endregion



return {
    Class = Class,

    File = File,
    Link = Link,
    JoinCategory = JoinCategory,
    Date = Date,
    HtmlElement = HtmlElement,
    Translatable = Translatable,

    Html = Html,

    ParameterTypes = ParameterTypes,
    ParameterConstraints = ParameterConstraints,

    Component = Component,
    RendererContext = RendererContext,
    ComponentContext = ComponentContext,

    makeRenderer = makeRenderer,
    makeInfoboxRenderer = makeInfoboxRenderer,

    Cargo = Cargo
}
