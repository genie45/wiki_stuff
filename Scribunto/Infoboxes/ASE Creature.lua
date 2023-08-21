local Arkitecture = require( 'Module:Arkitecture' )
local ColumnTypes = Arkitecture.Cargo.ColumnTypes
local ParameterTypes = Arkitecture.ParameterTypes
local ParameterConstraint = Arkitecture.ParameterConstraints


return Arkitecture.makeRenderer{
    RequiredLibraries = {
        'Module:Arkitecture/Common library',
    },

    BundledComponents = {
        ReleaseVersionGrid = Arkitecture.Component{
            Platforms = {
                {
                    Name = 'Steam',
                    Icon = 'Steam.svg',
                    Property = 'PC'
                },
                {
                    Name = 'Epic Store',
                    Icon = 'Epic Games.svg',
                    Property = 'PC',
                    MinVersion = '300.0' -- TODO:
                },
                {
                    Name = 'Xbox',
                    Icon = 'Xbox One.svg',
                    Property = 'Xbox'
                },
                {
                    Name = 'PlayStation',
                    Icon = 'PS.svg',
                    Property = 'PS'
                },
                {
                    Name = 'Nintendo Switch',
                    Icon = 'Nintendo Switch.svg',
                    Property = 'Switch'
                },
            },

            _renderVersion = function ( self, ctx, platform )
                local version = ctx.instance[platform.Property]
                local iconInstance = Arkitecture.File {
                    name = platform.Icon,
                    alt = platform.Name,
                    width = 20,
                }

                if not version then
                    return Arkitecture.HtmlElement{
                        tag = 'div',
                        classes = 'arkitect-cell',
    
                        iconInstance,
                        Arkitecture.Html.NewLine,
                        Arkitecture.Html.Small( Arkitecture.Translatable{ 'Not available' } ),
                    }
                end

                return Arkitecture.HtmlElement {
                    tag = 'div',
                    classes = 'arkitect-cell',

                    iconInstance,
                    Arkitecture.Link {
                        target = version,
                        label = version,
                    },
                    Arkitecture.Html.NewLine,
                    Arkitecture.Html.Small( '[PH]RELDATE' ),
                }
            end,

            render = function ( self, ctx )
                local el = {
                    tag = 'div',
                    classes = 'arkitect-columnlayout arkitect-column-layout-3 arkitect-columnlayout-33x33x33 arkitect-aligned-center arkitect-component-version-box',
                }
                for index = 1, #self.Platforms do
                    el[#el + 1] = self:_renderVersion( ctx, self.Platforms[index] )
                end
                return Arkitecture.HtmlElement( el )
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

        }
    end,

    getUnits = function ( self, ctx )
        return {
            {
                Component = 'SegmentedHeader',
                LeftValue = Arkitecture.File {
                    name = ctx:getParameter( 'name' ) .. '.png',
                    alt = '',
                    fallback = 'Missing.png',
                    width = 43
                },
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
            {
                Caption = Arkitecture.Translatable{ 'Creature' },
                {
                    Component = 'NamedDataRow',
                    Name = Arkitecture.Translatable{ 'Group' },
                    Value = ctx:getParameter( 'group' ),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Arkitecture.Translatable{ 'Diet' },
                    Value = ctx:getParameter( 'diet' ),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Arkitecture.Translatable{ 'Temperament' },
                    Value = ctx:getParameter( 'temperament' ),
                },
            },
            {
                Caption = Arkitecture.Translatable{ 'Domestication' },
                {
                    Component = 'NamedDataTable',
                    {
                        Name = Arkitecture.Translatable{ 'Tameable?' },
                        Value = ctx:expandComponent{
                            Component = "Checkmark",
                            Value = ctx:getParameter( 'canBeTamed' )
                        },
                    },
                    {
                        Name = Arkitecture.Translatable{ 'Rideable?' },
                        Value = ctx:expandComponent{
                            Component = "Checkmark",
                            Value = ctx:getParameter( 'canBeRidden' )
                        },
                    },
                    {
                        Name = Arkitecture.Translatable{ 'Breedable?' },
                        Value = ctx:expandComponent{
                            Component = "Checkmark",
                            Value = ctx:getParameter( 'canBeBred' )
                        },
                    },
                },
                {
                    Component = 'NamedDataRow',
                    Name = Arkitecture.Translatable{ 'Diet' },
                    Value = ctx:getParameter( 'diet' ),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Arkitecture.Translatable{ 'Temperament' },
                    Value = ctx:getParameter( 'temperament' ),
                },
            },

--            Arkitecture.Cargo.Row( 'ASE_Entities', {
--                Name           = { ParameterTypes.STRING     , 'name' },
--                VariantOf      = { ParameterTypes.STRING     , 'base' },
--                Class          = { ParameterTypes.CLASS_PATH , 'blueprintPath' },
--                IsClassPartial = { ParameterTypes.BOOL       , 'base',
--                                   Default = false },
--                Groups         = { ParameterTypes.STRING_LIST, 'groups',
--                                   Default = Arkitecture.Translatable{ 'Unspecified',
--                                               ES = 'Localisation test' } },
--            } ),
        }
    end
}
