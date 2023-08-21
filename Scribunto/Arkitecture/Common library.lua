local Arkitecture = require( 'Module:Arkitecture' )
local Html = Arkitecture.Html


return {
    NamedDataRow = Arkitecture.Component{
        render = function ( self, ctx )
            if not ctx.instance.Value or ctx.instance.Value == '' then
                return ''
            end
            return Html.Element{
                tag = 'div',
                classes = 'arkitect-item arkitect-row-layout arkitect-row-layout-40x60',

                Html.Element{
                    tag = 'div',
                    classes = 'arkitect-item-label arkitect-cell arkitect-corner-l',
                    ctx.instance.Name,
                },
                Html.Element{
                    tag = 'div',
                    classes = 'arkitect-item-value arkitect-cell arkitect-corner-r',
                    ctx.instance.Value,
                },
            }
        end
    },

    NamedDataTable3x2 = Arkitecture.Component{
        _wrap = function ( self, item, labelClass, valueClass )
            return Html.Element{
                tag = 'div',
                classes = 'arkitect-item',

                Html.Element{
                    tag = 'div',
                    classes = 'arkitect-item-label arkitect-cell ' .. labelClass,
                    item.Name,
                },
                Html.Element{
                    tag = 'div',
                    classes = 'arkitect-item-value arkitect-cell ' .. valueClass,
                    item.Value,
                },
            }
        end,

        render = function ( self, ctx )
            return Html.Element{
                tag = 'div',
                classes = 'arkitect-row arkitect-column-layout arkitect-columnlayout-33x33x33 arkitect-table-layout',

                self:_wrap( ctx.instance[1], 'arkitect-corner-tl', 'arkitect-corner-bl' ),
                self:_wrap( ctx.instance[2], '', '' ),
                self:_wrap( ctx.instance[3], 'arkitect-corner-tr', 'arkitect-corner-br' ),
            }
        end
    },

    NamedDataTable2x2 = Arkitecture.Component{
        _wrap = function ( self, item, labelClass, valueClass )
            return Html.Element{
                tag = 'div',
                classes = 'arkitect-item',

                Html.Element{
                    tag = 'div',
                    classes = 'arkitect-item-label arkitect-cell ' .. labelClass,
                    item.Name,
                },
                Html.Element{
                    tag = 'div',
                    classes = 'arkitect-item-value arkitect-cell ' .. valueClass,
                    item.Value,
                },
            }
        end,

        render = function ( self, ctx )
            return Html.Element{
                tag = 'div',
                classes = 'arkitect-row arkitect-column-layout arkitect-column-layout-50x50 arkitect-table-layout',

                self:_wrap( ctx.instance[1], 'arkitect-corner-tl', 'arkitect-corner-bl' ),
                self:_wrap( ctx.instance[2], 'arkitect-corner-tr', 'arkitect-corner-br' ),
            }
        end
    },

    ClassicHeader = Arkitecture.Component{
        render = function ( self, ctx, instance )
            return Arkitecture.HtmlElement {
                tag = 'div',
                classes = 'arkitect-component-header',

                Arkitecture.HtmlElement {
                    tag = 'div',
                    classes = 'arkitect-infobox-title',
                    instance.Name
                }
            }
        end
    },

    SegmentedHeader = Arkitecture.Component{
        CELL_WIDTH = 220,
        MIN_LENGTH_TO_START_SCALING = 16,
        MAX_FONT_SIZE = 24,
        CHARACTER_WIDTH = 11,


        _makeTitleAutoFitFontSizeCss = function ( self, text )
            local len = mw.ustring.len( text )
            if len < self.MIN_LENGTH_TO_START_SCALING then
                return nil
            end

            return {
                style = string.format( 'font-size: %dpx',
                    math.floor( self.CELL_WIDTH / ( self.CHARACTER_WIDTH * len ) * self.MAX_FONT_SIZE - 0.5 ) )
            }
        end,

        render = function ( self, ctx, instance )
            return Arkitecture.HtmlElement {
                tag = 'div',
                classes = 'arkitect-row-layout arkitect-row-layout-25x75 arkitect-segmented-header',

                Arkitecture.HtmlElement {
                    tag = 'div',
                    classes = 'arkitect-cell arkitect-secondary-background',
                    instance.LeftValue
                },
                Arkitecture.HtmlElement {
                    tag = 'div',
                    classes = 'arkitect-cell arkitect-infobox-title',
                    attributes = self:_makeTitleAutoFitFontSizeCss( instance.Name ),
                    instance.Name
                }
            }
        end
    },

    Checkmark = Arkitecture.Component{
        render = function ( self, ctx )
            local val = ctx.instance.Value
            return {
                Arkitecture.File{
                    name = val == true and 'Check mark.svg'
                        or val == false and 'X mark.svg'
                        or 'Missing.png',
                    width = 20,
                    link = false
                },
                ' ',
                val == true and Arkitecture.Translatable{ 'Yes' }
                    or val == false and Arkitecture.Translatable{ 'No' }
                    or Arkitecture.Translatable{ 'Unknown' },
            }
        end
    },
}
