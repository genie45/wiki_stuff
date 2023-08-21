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

    return string.format( '[[File:%s|%spx]]', spec.name, spec.width )
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


local LOCAL_TRANSLATABLE_KEY = string.upper( mw.language.getContentLanguage():getCode() )
local function Translatable( variants )
    return variants[LOCAL_TRANSLATABLE_KEY] or variants[1]
end


local Html = {
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

        -- Combine all classes into a single string if table
        if type( spec.classes ) == 'table' then
            spec.classes = table.concat( spec.classes, ' ' )
        end

        -- Combine all children into a single string
        local inner = table.concat( spec, '' )

        -- Build an attributes string
        local attrs
        if spec.attributes then
            attrs = {}
            for name, value in pairs( spec.attributes ) do
                attrs[#attrs + 1] = string.format( '%s="%s"', name, value )
            end
            attrs = table.concat( attrs, ' ' )
        end

        -- Choose a specialised format template and build the final element
        if spec.attributes and spec.classes then
            return string.format( '<%s class="%s" %s>%s</%s>', spec.tag, spec.classes, attrs, inner, spec.tag )
        elseif spec.attributes then
            return string.format( '<%s %s>%s</%s>', spec.tag, attrs, inner, spec.tag )
        elseif spec.classes then
            return string.format( '<%s class="%s">%s</%s>', spec.tag, spec.classes, inner, spec.tag )
        end
        return string.format( '<%s>%s</%s>', spec.tag, inner, spec.tag )
    end,

    --- HTML new line (br element) as a string.
    NewLine = '<br/>',

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
    function RendererContext.methods.expandComponent( self, instance )
        return self.renderer:expandComponent( instance )
    end


local ComponentContext = Class( function ( self, renderer, instance )
    self._renderer = renderer
    self.instance = instance
end )
    function ComponentContext.methods.expandComponent( self, instance )
        return self._renderer:expandComponent( instance )
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
}
local ParameterConstraints = {
    ONLY_ONE = ( function ( params )
        -- TODO: implement
        return true
    end ),
}


-- #endregion


-- #region Renderer



local Renderer = Class( function ( self )
    self.frame = mw.getCurrentFrame()
    self.parentFrame = self.frame:getParent()
    self.componentRegistry = {}
    self._parameterCache = {}
    self._parameterCacheKeySet = {}
    self._parameterSet = nil
    self.template = self.mt.class.template or nil

    if self.template.RequiredLibraries then
        for index = 1, #self.template.RequiredLibraries do
            for name, interfaceImplementation in pairs( require( self.template.RequiredLibraries[index] ) ) do
                self:registerComponent( name, interfaceImplementation )
            end
        end
        self.template.RequiredLibraries = nil
    end

    if self.template.BundledComponents then
        for name, interfaceImplementation in pairs( self.template.BundledComponents ) do
            self:registerComponent( name, interfaceImplementation )
        end
        self.template.BundledComponents = nil
    end
end )
    function Renderer.methods.loadParameters( self )
    end
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
    function Renderer.methods.getParameter( self, name )
        if not self._parameterCacheKeySet[name] then
            local value = self.frame.args[ name ] or self.parentFrame.args[ name ]

            if not self._parameterSet then
                self._parameterSet = self.template.Parameters
            end

            local config = self._parameterSet[name]
            if config == nil then
                error( 'Attempted to access an undefined parameter: ' .. name )
            end

            self._parameterCache[name] = self:_normaliseParameter( config, value )
            self._parameterCacheKeySet[name] = true
        end
        return self._parameterCache[name]
    end
    function Renderer.methods.registerComponent( self, name, interfaceImplementation )
        self.componentRegistry[name] = interfaceImplementation
    end
    function Renderer.methods.render( self )
        local html = {}

        local units = self.template.getSetup( self.template, RendererContext( self ) )
        for index = 1, #units do
            local unit = units[index]

            -- Hotpath: avoid using HtmlElement to construct the unit container as it may be result in costly string
            -- copies.
            html[#html + 1] = '<div class="arkitect-unit">'
            if unit.Caption then
                html[#html + 1] = HtmlElement{
                    tag = 'div',
                    classes = 'arkitect-unit-caption',
                    unit.Caption
                }
            end
            self:_processNodeSet( html, unit )
            html[#html + 1] = '</div>'
        end

        return HtmlElement{
            tag = 'div',
            classes = 'arkitect noexcerpt',
            attributes = {
                role = 'region',
            },

            table.concat( html, '' ),
        }
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
        local componentSingleton = ( customRegistry and customRegistry.componentRegistry[instance.Component])
            or self.componentRegistry[instance.Component]
        if componentSingleton == nil then
            error( 'Infobox requires component but component not registered: ' .. instance.Component )
        end
        local rendered = componentSingleton:render( ComponentContext( self, instance ), instance )
        if type( rendered ) == 'table' then
            rendered = table.concat( rendered, '' )
        end
        return rendered
    end


local function makeRenderer( template )
    local __templateBoundRendererImpl = Class( nil, Renderer )
        __templateBoundRendererImpl.template = template
        function __templateBoundRendererImpl.render()
            return __templateBoundRendererImpl():render()
        end
    return __templateBoundRendererImpl
end

-- #endregion



return {
    Class = Class,

    File = File,
    Link = Link,
    HtmlElement = HtmlElement,
    Translatable = Translatable,

    Html = Html,

    ParameterTypes = ParameterTypes,
    ParameterConstraints = ParameterConstraints,

    Component = Component,
    RendererContext = RendererContext,
    ComponentContext = ComponentContext,

    makeRenderer = makeRenderer,

    Cargo = {
        ColumnTypes = {},
        Row = function() end
    }
}
