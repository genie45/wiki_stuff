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
        if not mw.title.new( FILE_EXISTS_TITLE_PREFIX .. spec.name ).exists then
            spec.name = spec.fallback
        end
    end

    return string.format( '[[File:%s|%spx]]', spec.name, spec.width )
end


local function Link( spec )
    return string.format( '[[%s|%s]]', spec.target, spec.label )
end


local LOCAL_TRANSLATABLE_KEY = string.upper( mw.language.getContentLanguage():getCode() )
local function Translatable( variants )
    return variants[LOCAL_TRANSLATABLE_KEY] or variants[0]
end


local function HtmlElement( spec )
    -- TODO: attributes

    -- Combine all classes into a single string if table
    if type( spec.classes ) == 'table' then
        spec.classes = table.concat( spec.classes, ' ' )
    end

    -- Move child/text into a local. They're currently functionally identical.
    local inner
    if type( spec.text ) == 'table' then
        inner = Translatable( spec.text )
    else
        inner = spec.text or spec.child or ''
    end


    -- Choose a possibly quicker specialised template
    if spec.tag and spec.classes then
        return string.format( '<%s class="%s">%s</%s>', spec.tag, spec.classes, inner, spec.tag )
    end
    return string.format( '<%s>%s</%s>', spec.tag, inner, spec.tag )
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
    function RendererContext.methods.getString( self, string )
        return renderer.parameters[ name ]
    end
    function RendererContext.methods.getParameter( self, name )
        return renderer.parameters[ name ]
    end


local ComponentContext = Class( function ( self, renderer, properties )
    self._renderer = renderer
    self.properties = properties
end )
    function RendererContext.methods.getParameter( self, name )
        return renderer.parameters[ name ]
    end
-- #endregion


-- #region Parameter handling
local ParameterTypes = {
    STRING = '_M_PT_STRING',
    CLASS_PATH = '_M_PT_CLASS_PATH',
    BOOL = '_M_PT_BOOL',
    NUMBER = '_M_PT_NUMBER',
    GAME_VERSION = '_M_PT_GVER',
}
local ParameterConstraints = {
    ONLY_ONE = ( function ( params )
        -- TODO: implement
        return true
    end ),
}


-- #endregion


-- #region Renderer



local Renderer = Class( function ( self, template )
    self.frame = mw.getCurrentFrame()
    self.parentFrame = self.frame:getParent()
    self.componentRegistry = {}
    self.parameters = {}
end )
    function Renderer.methods.loadParameters( self )
    end
    function Renderer.methods.getParameter( self, name )
        return self.frame.args[ name ] or self.parentFrame:getParent()
    end
    function Renderer.methods.registerComponent( self, name, implementation )
        self.componentRegistry[name] = implementation
    end
    function Renderer.methods.render( self )
        local html = {}

        local units = self.template:getUnits()
        for index = 1, #units do
            local unit = units[index]

            -- Hotpath: avoid using HtmlElement to construct the unit container as it may be result in costly string
            -- copies.
            html[#html + 1] = '<div class="arkitect-unit">'
            if unit.Caption then
                html[#html + 1] = HtmlElement{
                    tag = 'h3',
                    classes = 'arkitect-unit-caption',
                    text = unit.Caption
                }
            end
            self:_processNodeSet( html, unit )
            html[#html + 1] = '</div>'
        end

        return HtmlElement{
            tag = 'aside',
            classes = 'arkitect noexcerpt',
            attributes = {
                role = 'region',
            },
            child = table.concat( html, '' ),
        }
    end
    function Renderer.methods._processNodeSet( self, html, unit )
        if type( unit ) == 'string' then
            html[#html + 1] = unit
            return
        elseif unit.Component then
            self:_processComponent( html, unit )
            return
        end
        for index = 1, #unit do
            html[#html + 1] = self:_processNodeSet( html, unit[index] )
        end
    end
    function Renderer.methods._processComponent( self, html, instance )
        local componentSingleton = self.componentRegistry[unit.Component]
        if componentSingleton == nil then
            error( 'Infobox requires component but component not registered: ' .. unit.Component )
        end
        html[#html + 1] = componentSingleton:render( nil, instance )
    end


local function makeRenderer( template )
    local __templateBoundRendererImpl = Class( function ( self )
        Renderer.constructor( self, template )
    end, Renderer )
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
