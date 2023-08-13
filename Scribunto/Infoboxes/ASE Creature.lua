local Arkitecture = require( 'Module:Arkitecture' )
local ColumnTypes = Arkitecture.Cargo.ColumnTypes
local ParameterTypes = Arkitecture.ParameterTypes
local ParameterConstraint = Arkitecture.ParameterConstraints


return Arkitecture.makeRenderer{
    BundledComponents = {
        SplitCreatureHeader = Arkitecture.Component{
            render = function ( self, ctx, instance )
                return {
                    Arkitecture.HtmlElement {
                        tag = 'div',
                        classes = 'arkitect-left arkitect-X2-25',
                        child = Arkitecture.File {
                            name = instance.Icon .. '.png',
                            width = 43
                        },
                    },
                    Arkitecture.HtmlElement {
                        tag = 'div',
                        classes = 'arkitect-left arkitect-X2-75',
                        text = instance.Name
                    }
                }
            end
        },
        KillXP = Arkitecture.Component{
            CargoSetup = {
                ASE_KillXP = {
                    { ColumnTypes.STRING, 'Name' },
                    { ColumnTypes.NUMBER, 'Value' },
                },
            },

            render = function ( self, ctx, instance )
            end
        },
        CreatureSpawningMap = Arkitecture.Component{
            CargoSetup = {
                ASE_Spawning = {
                    -- Not a fan of hardcoding here but it's better than lists I guess (lists suck) ~alex
                    { ColumnTypes.STRING, 'Name' },
                    { ColumnTypes.BOOL  , 'TheIsland' },
                    { ColumnTypes.BOOL  , 'TheCenter' },
                    { ColumnTypes.BOOL  , 'ScorchedEarth' },
                    { ColumnTypes.BOOL  , 'Ragnarok' },
                    { ColumnTypes.BOOL  , 'Aberration' },
                    { ColumnTypes.BOOL  , 'Extinction' },
                    { ColumnTypes.BOOL  , 'Valguero' },
                    { ColumnTypes.BOOL  , 'Genesis1' },
                    { ColumnTypes.BOOL  , 'CrystalIsles' },
                    { ColumnTypes.BOOL  , 'Genesis2' },
                    { ColumnTypes.BOOL  , 'LostIsland' },
                    { ColumnTypes.BOOL  , 'Fjordur' },
                }
            },

            render = function ( self, ctx, instance )
            end
        },
    },
    CargoSetup = {
        ASE_Entities = {
            { ColumnTypes.STRING, 'Name'           },
            { ColumnTypes.STRING, 'VariantOf'      , Nullable = true },
            { ColumnTypes.STRING, 'Class'          , Nullable = true},
            { ColumnTypes.BOOL  , 'IsClassPartial' },
            { ColumnTypes.LIST  , 'Groups'         , ColumnTypes.STRING },
        },
        ASE_EntityReleaseInfo = {
            { ColumnTypes.STRING, 'Name' },
            { ColumnTypes.STRING, 'GameVersion' },
        },
    },


    getParameters = function ( self )
        return {
            -- Creature name.
            { ParameterTypes.STRING, 'name' },

            -- Path to the creature's class. May be null on un-/freshly released creatures.
            { ParameterTypes.CLASS_PATH, 'blueprintPath', Nullable = true },
            -- If given, this is the name of the creature this one is a variant of.
            { ParameterTypes.STRING, 'base', Nullable = true },
            -- If true, the class acts as a template for other creatures, does not appear in any of official maps, and
            -- should not be used by the player.
            { ParameterTypes.BOOL,   'isTemplate' },
            { ParameterConstraint.ONLY_ONE, 'base', 'isTemplate' },

            -- Version by platform target this creature was added in. EOS and Stadia are deduced from PC.
            { ParameterTypes.GAME_VERSION, 'versionAdded/PC', Nullable = true },
            { ParameterTypes.GAME_VERSION, 'versionAdded/Xbox', Nullable = true },
            { ParameterTypes.GAME_VERSION, 'versionAdded/PS', Nullable = true },
            { ParameterTypes.GAME_VERSION, 'versionAdded/Switch', Nullable = true },
            { ParameterTypes.GAME_VERSION, 'versionAdded/Mobile', Nullable = true },

        },
    end

    getUnits = function ( self, ctx )
        return {
            {
                Component = 'SplitCreatureHeader',
                Name = ctx:getParameter( 'name' ),
            },
            {
                Caption = Arkitecture.Translatable{ 'Release Information',
                            ES = 'Localisation test',
                            FR = 'A localisation test' },
                {
                    Component = 'ReleaseVersionGrid',
                    PC = ctx:getParameter( 'versionAdded/PC' ),
                    Xbox = ctx:getParameter( 'versionAdded/Xbox' ),
                    PS = ctx:getParameter( 'versionAdded/PS' ),
                    Switch = ctx:getParameter( 'versionAdded/Switch' ),
                    Mobile = ctx:getParameter( 'versionAdded/Mobile' ),
                },
            },

            Arkitecture.Cargo.Row( 'ASE_Entities', {
                Name           = { ParameterTypes.STRING     , 'name' },
                VariantOf      = { ParameterTypes.STRING     , 'base' },
                Class          = { ParameterTypes.CLASS_PATH , 'blueprintPath' },
                IsClassPartial = { ParameterTypes.BOOL       , 'base',
                                   Default = false },
                Groups         = { ParameterTypes.STRING_LIST, 'groups',
                                   Default = Arkitecture.Translatable{ 'Unspecified',
                                               ES = 'Localisation test' } },
            } ),
        }
    end
}
