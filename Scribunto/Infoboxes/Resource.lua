local Arkitecture = require( 'Module:Arkitecture' )
local ColumnTypes = Arkitecture.Cargo.ColumnTypes
local ParameterTypes = Arkitecture.ParameterTypes
local ParameterConstraint = Arkitecture.ParameterConstraints
local SpawnCommands = require( 'Module:Infobox spawn command section' )

local Text = require( 'Module:Infoboxes/Resource/strings' )


return Arkitecture.makeRenderer{
    RequiredLibraries = {
        'Module:Arkitecture/Common library',
    },

    PrivateComponents = {
        SpawnCommand = Arkitecture.Component{
            render = function ( self, ctx )
                if not ctx.instance.Targets and (
                    ctx.instance.BlueprintPath or ctx.instance.Short or ctx.instance.ItemId
                ) then
                    ctx.instance.Targets = {
                        {
                            blueprintPath = ctx.instance.BlueprintPath,
                            short = ctx.instance.Short,
                            itemId = ctx.instance.ItemId,
                        }
                    }
                end

                if not ctx.instance.Targets or #ctx.instance.Targets == 0 then
                    return ''
                end

                local results = SpawnCommands.renderUnwrapped( ctx.instance.Type, ctx.instance.Targets )

                if #results == 1 then
                    return Arkitecture.Html.Element {
                        tag = 'div',
                        classes = 'arkitect-spawn-command',
                        results[1][2],
                    }
                end

                -- TODO: tabbers, WIP
            end
        },
    },

    CargoSetup = {
    },

    Parameters = {
        name = {
            ParameterTypes.STRING,
            Default = Arkitecture.CURRENT_PAGE_TITLE,
        },
        image = {
            ParameterTypes.FILE,
            Optional = true,
        },
        type = {
            ParameterTypes.STRING,
            Default = 'Resource',
        },
        description = {
            ParameterTypes.STRING,
            Optional = true,
        },
        combustible = {
            ParameterTypes.BOOL,
            Default = false,
        },
        weight = {
            ParameterTypes.FLOAT,
            Optional = true,
        },
        stackSize = {
            ParameterTypes.INTEGER,
            Optional = true,
            Default = 1,
        },
        spoilsIn = {
            ParameterTypes.FLOAT,
            Optional = true,
        },
        spoilsTo = {
            ParameterTypes.STRING,
            Optional = true,
        },
        foundInBeacons = {
            ParameterTypes.STRING,
            Optional = true,
        },
        exchangeQuantity = {
            ParameterTypes.INTEGER,
            Optional = true,
            Default = 1,
        },
        hexagons = {
            ParameterTypes.INTEGER,
            Optional = true,
        },
        blueprintPath = {
            ParameterTypes.STRING,
            Optional = true,
        },
        itemId = {
            ParameterTypes.INTEGER,
            Optional = true,
        },
        gfi = {
            ParameterTypes.STRING,
            Optional = true,
        },
    },

    getSetup = function ( self, ctx )
        return {
            {
                {
                    Component = 'ClassicHeader',
                    Name = ctx:getParameter( 'name' ),
                    Image = ctx:getParameter( 'image' ),
                },
            },
            {
                Caption = Text.SECTION_RESOURCE,
                {
                    Component = 'NamedDataRow',
                    Name = Text.ROW_TYPE,
                    Value = ctx:getParameter( 'type' ),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Text.ROW_COMBUSTIBLE,
                    Value = ctx:expandComponent{
                        Component = 'Checkmark',
                        Value = ctx:getParameter( 'combustible' ),
                    },
                },
            },
            {
                Caption = Text.SECTION_ITEM,
                {
                    Component = 'NamedDataRow',
                    Name = Text.ROW_WEIGHT,
                    Value = ctx:getParameter( 'weight' ),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Text.ROW_STACK_SIZE,
                    Value = ctx:getParameter( 'stackSize' ),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Text.ROW_SPOILS,
                    Value = ( function ()
                        local time = ctx:getParameter( 'spoilsIn' )
                        local toItem = ctx:getParameter( 'spoilsTo' )

                        if time == nil and toItem == nil then
                            return nil
                        elseif time ~= nil and toItem ~= nil then
                            return string.format( Text.ROW_SPOILS_TO_IN_N_F, toItem, time )
                        elseif time == nil and toItem ~= nil then
                            return string.format( Text.ROW_SPOILS_TO_IN_UNKNOWN_F, toItem )
                        elseif time ~= nil and toItem == nil then
                            return string.format( Text.ROW_SPOILS_TO_UNKNOWN_IN_N_F, time )
                        end
                    end )(),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Text.ROW_BEACONS,
                    -- TODO: we can probably have a centralised loot table
                    Value = ctx:getParameter( 'foundInBeacons' ),
                },
            },
            {
                Caption = Text.SECTION_SPAWN_COMMANDS,
                Collapsible = true,
                CollapsedByDefault = true,

                Component = 'SpawnCommand',
                Object = SpawnCommands.ClassType.Item,
                BlueprintPath = ctx:getParameter( 'blueprintPath' ),
                ItemId = ctx:getParameter( 'itemId' ),
                Short = ctx:getParameter( 'gfi' ),
            },
            {
                Caption = Text.SECTION_HEXAGON_STORE,
                {
                    Component = 'NamedDataRow',
                    Name = Text.ROW_HEXAGON_PURCHASE_AMOUNT,
                    Value = ctx:getParameter( 'exchangeQuantity' )
                        and string.format(
                            Text.ROW_HEXAGON_PURCHASE_AMOUNT_VALUE_F,
                            ctx:getParameter( 'exchangeQuantity' )
                        )
                        or nil,
                },
                {
                    Component = 'NamedDataRow',
                    Name = Text.ROW_HEXAGON_PURCHASE_AMOUNT,
                    Value = ctx:getParameter( 'hexagons' ),
                },
            },

            --{
            --    SideEffect = true,
            --    Arkitecture.JoinCategory( Text.CATEGORY_ ),
            --},
        }
    end
}
