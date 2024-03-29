local Arkitecture = require( 'Module:Arkitecture' )
local Html = Arkitecture.Html

local Text = require( 'Module:Arkitecture/Common library/strings' )


return {
    NamedDataRow = Arkitecture.Component{
        render = function ( self, ctx )
            if not ctx.instance.Value or ctx.instance.Value == '' then
                return ''
            end
            return Html.Element{
                tag = 'div',
                classes = 'arkitect-item arkitect-row-layout arkitect-row-layout-' .. ( ctx.instance.Dimensions
                    or '40x60' ),

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
        _wrapItem = function ( self, item, labelClass, valueClass )
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

                self:_wrapItem( ctx.instance[1], 'arkitect-corner-tl', 'arkitect-corner-bl' ),
                self:_wrapItem( ctx.instance[2], '', '' ),
                self:_wrapItem( ctx.instance[3], 'arkitect-corner-tr', 'arkitect-corner-br' ),
            }
        end
    },

    NamedDataTable2x2 = Arkitecture.Component{
        _wrapItem = function ( self, item )
            return Html.Element{
                tag = 'div',
                classes = 'arkitect-item',

                Html.Element{
                    tag = 'div',
                    classes = 'arkitect-item-label arkitect-cell arkitect-corner-t',
                    item.Name,
                },
                Html.Element{
                    tag = 'div',
                    classes = 'arkitect-item-value arkitect-cell arkitect-corner-b',
                    item.Value,
                },
            }
        end,

        render = function ( self, ctx )
            -- Special layout for when both items have equal values.
            if ctx.instance[1].Value == ctx.instance[2].Value then
                return Html.Element{
                    tag = 'div',
                    classes = { 'arkitect-row arkitect-column-layout arkitect-column-layout-50x50',
                                'arkitect-table-layout arkitect-table-layout-unified' },

                    Html.Element{
                        tag = 'div',
                        classes = 'arkitect-item',
        
                        Html.Element{
                            tag = 'div',
                            classes = 'arkitect-item-label arkitect-cell arkitect-corner-t',
                            ctx.instance[1].Name,
                        },
                        Html.Element{
                            tag = 'div',
                            classes = 'arkitect-item-label arkitect-cell arkitect-corner-t',
                            ctx.instance[2].Name,
                        },
                        Html.Element{
                            tag = 'div',
                            classes = 'arkitect-item-value arkitect-cell arkitect-corner-b',
                            ctx.instance[1].Value,
                        },
                    }
                }
            end

            return Html.Element{
                tag = 'div',
                classes = 'arkitect-row arkitect-column-layout arkitect-column-layout-50x50 arkitect-table-layout',

                self:_wrapItem( ctx.instance[1] ),
                self:_wrapItem( ctx.instance[2] ),
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
                },
                instance.Image and Arkitecture.Html.Element{
                    tag = 'div',
                    classes = 'arkitect-infobox-image',
                    Arkitecture.File{
                        name = instance.Image,
                        altText = '',
                        width = 228,
                    },
                } or '',
                instance.Description and Arkitecture.Html.Element{
                    tag = 'div',
                    classes = 'arkitect-description quote',
                    Arkitecture.Html.Element{
                        tag = 'div',
                        classes = 'quote-left',
                        '“',
                    },
                    Arkitecture.Html.Element{
                        tag = 'p',
                        instance.Description,
                    },
                    Arkitecture.Html.Element{
                        tag = 'div',
                        classes = 'quote-right',
                        '„',
                    },
                } or '',
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
                    classes = 'arkitect-cell arkitect-secondary-background arkitect-infobox-title arkitect-corner-l',
                    instance.LeftValue
                },
                Arkitecture.HtmlElement {
                    tag = 'div',
                    classes = 'arkitect-cell arkitect-infobox-title arkitect-corner-r',
                    attributes = self:_makeTitleAutoFitFontSizeCss( instance.Name ),
                    instance.Name
                }
            }
        end
    },

    FloatingNote = Arkitecture.Component{
        render = function ( self, ctx )
            if ctx.instance.Value == nil then
                return nil
            end

            return Arkitecture.Html.Element{
                tag = 'div',
                classes = 'arkitect-note arkitect-row-layout arkitect-row-layout-25x75',
                Arkitecture.Html.Element{
                    tag = 'p',
                    ctx.instance.Value,
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
                val == true and Text.CHECKMARK_YES
                    or val == false and Text.CHECKMARK_NO
                    or TEXT.CHECKMARK_UNKNOWN,
            }
        end
    },
}
