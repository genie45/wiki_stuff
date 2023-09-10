local Arkitecture = require( 'Module:Arkitecture' )
local ColumnTypes = Arkitecture.Cargo.ColumnTypes
local ParameterTypes = Arkitecture.ParameterTypes
local ParameterConstraint = Arkitecture.ParameterConstraints

local Text = require( 'Module:Infoboxes/Patch/strings' )


-- TODO: publish via Module:Version
local function parseVersion( str, defaultPlatform )
    if str == nil then
        return nil
    end
    local platform, major, minor = str:match( '(%w+) (%d+)%.(%d+)' )
    if major == nil then
        major, minor = str:match( '(%d+)%.(%d+)' )
    end
    if major == nil or minor == nil then
        return nil
    end
    return platform or defaultPlatform or 'PC', major, minor
end


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
                    Arkitecture.Date( ctx.instance.Date ),
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

    _makeVersionStringFromRecord = function ( self, record )
        if record.Platform == 'PC' then
            return string.format( '%d.%d', record.Major, record.Minor )
        end
        return string.format( '%s %d.%d', record.Platform, record.Major, record.Minor )
    end,

    injectParameters = function ( self, ctx )
        local title = mw.title.getCurrentTitle().baseText
        local platform, major, minor = parseVersion( title )

        if major == nil or minor == nil then
            error( 'Titles of patch articles should follow either of these formats: "[.../]major.minor", '
                .. '"[.../]platform major.minor".' )
        end

        local out = {
            platform = platform,
            major = major,
            minor = minor,
        }

        if ctx:getParameter( 'date' ) ~= nil then
            out.client = ctx:getParameter( 'date' )
            out.server = ctx:getParameter( 'date' )
        end

        -- Fetch previous and next version from Cargo
        -- TODO: forced chronology needs to be exported
        if not ctx:hasParameterValueUnchecked( 'previous' ) then
            local results = mw.ext.cargo.query( ctx:getCargoTablePrefix() .. 'Patch', 'Platform, Major, Minor', {
                where = string.format(
                    'Platform = \'%s\' AND ( ( Major < %d ) OR ( Major = %d AND Minor < %d ) )',
                    platform, major, major, minor
                ),
                orderBy = 'GREATEST( COALESCE( ClientReleaseDate, 0 ), COALESCE( ServerReleaseDate, 0 ) ) DESC, '
                    .. 'Major DESC, Minor DESC',
                limit = 1
            } )
            if #results ~= 0 then
                out.previous = self:_makeVersionStringFromRecord( results[1] )
            end
        end
        if not ctx:hasParameterValueUnchecked( 'next' ) then
            local results = mw.ext.cargo.query( ctx:getCargoTablePrefix() .. 'Patch', 'Platform, Major, Minor', {
                where = string.format(
                    'Platform = \'%s\' AND ( ( Major > %d ) OR ( Major = %d AND Minor > %d ) )',
                    platform, major, major, minor
                ),
                orderBy = 'GREATEST( COALESCE( ClientReleaseDate, 0 ), COALESCE( ServerReleaseDate, 0 ) ) ASC, '
                    .. 'Major ASC, Minor ASC',
                limit = 1
            } )
            if #results ~= 0 then
                out.next = self:_makeVersionStringFromRecord( results[1] )
            end
        end

        out.__NEXT = ( function ()
            local out = {}
            -- If not specified already, determine type
            if not ctx:hasParameterValueUnchecked( 'type' ) then
                local _, prevMajor, prevMinor = parseVersion( ctx:getParameter( 'previous' ), platform )
                out.type = prevMajor == nil and 'initial'
                    or prevMajor == major and 'minor'
                    or 'major'
            end
            return out
        end )

        return out
    end,

    ---
    --- @class PatchInfo
    --- @field platform string
    --- |"'PC'"
    --- |"'Xbox'"
    --- |"'PS'"
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
        PS = 'PS.svg',
        Switch = 'Nintendo Switch.svg',
    },

    _makePlatformIcons = function ( self, pInfo )
        local width = 24

        if self.PLATFORM_ICONS[pInfo.platform] then
            return Arkitecture.File{
                name = self.PLATFORM_ICONS[pInfo.platform],
                width = width,
                link = false
            }
        end

        if pInfo.platform == 'PC' then
            -- Steam, always
            local icons = {
                Arkitecture.File{
                    name = 'Steam.svg',
                    width = width,
                    link = false
                }
            }
            -- EOS, at or after 311.74
            if pInfo.major > 311 or ( pInfo.major == 311 and pInfo.minor >= 74 ) then
                icons[#icons + 1] = Arkitecture.File{
                    name = 'Epic Games.svg',
                    width = width,
                    link = false
                }
            end
            -- Stadia, at or after 678.10
            if pInfo.major > 678 or ( pInfo.major == 678 and pInfo.minor >= 10 ) then
                icons[#icons + 1] = Arkitecture.File{
                    name = 'Stadia.svg',
                    width = width,
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
                {
                    Component = 'NamedDataRow',
                    Dimensions = '25x75',
                    Name = Text.ROW_TYPE,
                    Value = ( {
                        initial = Text.ROW_TYPE_INITIAL_RELEASE,
                        major = Text.ROW_TYPE_MAJOR,
                        minor = Text.ROW_TYPE_MINOR,
                    } )[ctx:getParameter( 'type' )],
                },
            },
            {
                Caption = Text.SECTION_AVAILABILITY,
                Component = 'NamedDataTable2x2',
                {
                    Name = Text.SECTION_AVAILABILITY_ROW_CLIENT,
                    Value = ctx:expandComponent{
                        Component = 'TargetCell',
                        Date = ctx:getParameter( 'client' )
                    },
                },
                {
                    Name = Text.SECTION_AVAILABILITY_ROW_SERVER,
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
                    Name = Text.SECTION_CHRONOLOGY_ROW_PREVIOUS,
                    Value = Arkitecture.Link( ctx:getParameter( 'previous' ) ),
                },
                {
                    Component = 'NamedDataRow',
                    Name = Text.SECTION_CHRONOLOGY_ROW_NEXT,
                    Value = Arkitecture.Link( ctx:getParameter( 'next' ) ),
                },
            },

            {
                SideEffect = true,
                Arkitecture.JoinCategory( Text.CATEGORY_CHANGELOG ),
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
