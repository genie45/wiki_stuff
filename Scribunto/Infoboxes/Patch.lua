local Arkitecture = require( 'Module:Arkitecture' )
local ColumnTypes = Arkitecture.Cargo.ColumnTypes
local ParameterTypes = Arkitecture.ParameterTypes
local ParameterConstraint = Arkitecture.ParameterConstraints

local Text = require( 'Module:Infoboxes/Patch/strings' )


return Arkitecture.makeRenderer{
    RequiredLibraries = {
        'Module:Arkitecture/Common library',
    },

    PrivateComponents = {
        GameBar = Arkitecture.Component{
            render = function ( self, ctx )
                return Arkitecture.Html.Element{
                    tag = 'div',
                    classes = 'arkitect-game-bar',
                    Arkitecture.File{
                        name = ctx.instance.Game .. '.png',
                        width = 16,
                        link = ctx.instance.Game,
                    },
                    Arkitecture.Html.NonBreakingSpace,
                    Arkitecture.Link( ctx.instance.Game ),
                }
            end
        },

        TargetCell = Arkitecture.Component{
            render = function ( self, ctx )
                if ctx.instance.Date == nil then
                    return ctx:expandComponent{
                        Component = 'Checkmark',
                        Value = false,
                    }
                end

                return {
                    ctx:expandComponent{
                        Component = 'Checkmark',
                        Value = true
                    },
                    Arkitecture.Html.NewLine,
                    ctx.instance.Date,
                }
            end
        }
    },

    CargoSetup = {
        Patch = {
            { 'Major', ColumnTypes.INTEGER, },
            { 'Minor', ColumnTypes.INTEGER, },
            { 'ClientReleaseDate',
                ColumnTypes.DATE,
                Optional = true,
            },
            { 'ServerReleaseDate',
                ColumnTypes.DATE,
                Optional = true,
            },
            { 'Platform',
                ColumnTypes.STRING,
                Values = {
                    'PC',
                    'Xbox',
                    'PlayStation',
                    'Switch',
                },
            },
        },
    },

    Parameters = {
        game = ParameterTypes.GAME,
        platform = ParameterTypes.STRING,
        major = ParameterTypes.INTEGER,
        minor = ParameterTypes.INTEGER,
        type = {
            ParameterTypes.STRING,
            AllowedValues = { 'major', 'minor', 'initial' },
        },
        date = {
            ParameterTypes.DATE,
            Optional = true,
        },
        client = {
            ParameterTypes.DATE,
            Optional = true,
        },
        server = {
            ParameterTypes.DATE,
            Optional = true,
        },
        previous = ParameterTypes.GAME_VERSION,
        next = ParameterTypes.GAME_VERSION,
    },


    injectParameters = function ( self, ctx )
        local title = mw.title.getCurrentTitle().baseText

        local platform, major, minor = title:match( '(%w+) (%d+)%.(%d+)' )
        if major == nil then
            major, minor = title:match( '(%d+)%.(%d+)' )
        end

        if major == nil or minor == nil then
            error( 'Titles of patch articles should follow either of these formats: "[.../]major.minor", "[.../]platform major.minor".' )
        end

        local out = {
            platform = platform or 'PC',
            major = major,
            minor = minor,
        }

        if ctx:getParameter( 'date' ) ~= nil then
            out.client = ctx:getParameter( 'date' )
            out.server = ctx:getParameter( 'date' )
        end

        -- TODO: implement when genie makes a decision
        out.game = 'ARK: Survival Evolved'

        return out
    end,

    ---
    --- @class PatchInfo
    --- @field platform string
    --- |"'PC'"
    --- |"'Xbox'"
    --- |"'PlayStation'"
    --- |"'Switch'"
    --- @field major integer
    --- @field minor integer
    ---

    ---
    --- Packs all information identifying a patch into a single structure. Ideally, we'd retrieve it from the title
    --- directly rather than relying on wikitext-end to give it to us. But this is easier (... and faster) than parsing
    --- the title in Lua...
    --- @param ctx Arkitecture.RendererContext
    --- @return PatchInfo 
    _packPatchInfo = function ( self, ctx )
        return {
            platform = ctx:getParameter( 'platform' ),
            major = ctx:getParameter( 'major' ),
            minor = ctx:getParameter( 'minor' ),
        }
    end,

    PLATFORM_ICONS = {
        Xbox = 'Xbox One.svg',
        PlayStation = 'PS.svg',
        Switch = 'Nintendo Switch.svg',
    },

    _makePlatformIcons = function ( self, pInfo )
        if self.PLATFORM_ICONS[pInfo.platform] then
            return Arkitecture.File{
                name = self.PLATFORM_ICONS[pInfo.package],
                width = 20,
                link = false
            }
        end

        if pInfo.platform == 'PC' then
            -- Steam, always
            local icons = {
                Arkitecture.File{
                    name = 'Steam.svg',
                    width = 20,
                    link = false
                }
            }
            -- EOS, at or after 311.74
            if pInfo.major > 311 or ( pInfo.major == 311 and pInfo.minor >= 74 ) then
                icons[#icons + 1] = Arkitecture.File{
                    name = 'Epic Games.svg',
                    width = 20,
                    link = false
                }
            end
            -- Stadia, at or after 678.10
            if pInfo.major > 678 or ( pInfo.major == 678 and pInfo.minor >= 10 ) then
                icons[#icons + 1] = Arkitecture.File{
                    name = 'Stadia.svg',
                    width = 20,
                    link = false
                }
            end

            return table.concat( icons, Arkitecture.Html.NonBreakingSpace )
        end

        error( 'Platform not recognised in _makePlatformIcons, someone did not update it when adding a platform: '
            .. pInfo.platform )
    end,

    getSetup = function ( self, ctx )
        local pInfo = self:_packPatchInfo( ctx )

        local clientDate = ctx:getParameter( 'client' )
        local serverDate = ctx:getParameter( 'server' )

        return {
            {
                {
                    Component = 'GameBar',
                    Game = ctx:getParameter( 'game' ),
                },
                {
                    Component = 'SegmentedHeader',
                    LeftValue = self:_makePlatformIcons( pInfo ),
                    Name = string.format( '%d.%d', pInfo.major, pInfo.minor ),
                },
            },
            {
                {
                    Component = 'NamedDataRow',
                    Name = Text.ITEM_TYPE,
                    Value = ( {
                        initial = Text.ROW_TYPE_INITIAL_RELEASE,
                        major = Text.ROW_TYPE_MAJOR,
                        minor = Text.ROW_TYPE_MINOR,
                    } )[ctx:getParameter( 'type' )],
                }
            },
            {
                Caption = Text.SECTION_AVAILABILITY,
                Component = 'NamedDataTable2x2',
                {
                    Name = Text.SECTION_AVAILABILITY_ITEM_CLIENT,
                    Value = ctx:expandComponent{
                        Component = 'TargetCell',
                        Date = ctx:getParameter( 'client' )
                    },
                },
                {
                    Name = Text.SECTION_AVAILABILITY_ITEM_SERVER,
                    Value = ctx:expandComponent{
                        Component = 'TargetCell',
                        Date = ctx:getParameter( 'server' )
                    },
                },
            },
            {
                Caption = Text.SECTION_CHRONOLOGY,
                {
                    Component = 'NamedDataRow',
                    Name = Text.SECTION_CHRONOLOGY_ITEM_PREVIOUS,
                    Value = Arkitecture.Link( ctx:getParameter( 'previous' ) ),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Text.SECTION_CHRONOLOGY_ITEM_NEXT,
                    Value = Arkitecture.Link( ctx:getParameter( 'next' ) ),
                },
            },

            {
                Component = 'NewCargoRow',
                Table = 'Patch',

                Platform = ctx:getParameter( 'platform' ),
                Major = ctx:getParameter( 'major' ),
                Minor = ctx:getParameter( 'minor' ),
                ClientReleaseDate = ctx:getParameter( 'client' ),
                ServerReleaseDate = ctx:getParameter( 'server' ),
            }
        }
    end
}
