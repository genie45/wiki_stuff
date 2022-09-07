{
    function throttle( func, wait ) {
        var context, args, timeout, previous = Date.now() - wait;
        var run = function () {
            timeout = null;
            previous = Date.now();
            func.apply( context, args );
        };
        return function () {
            context = this;
            args = arguments;
            if ( !timeout ) {
                timeout = setTimeout( run, Math.max( wait - ( Date.now() - previous ), 0 ) );
            }
        };
    }

    var pageTitle = $( '#firstHeading' ).get( 0 );
    var $stickyHeaderCnt = $( '<header id="ark-sticky-header">' )
        .insertAfter( '#wikigg-header' );
    var isVisible = false;
    var $stickyName = $( '<a class="sticky-wiki-name">' )
        .attr( 'href', mw.config.get( 'wgScriptPath' ) )
        .text( mw.config.get( 'wgSiteName' ) )
        .appendTo( $stickyHeaderCnt );
    var $stickySearch = $( '<div role="search" class="sticky-search-box vector-search-box">' )
        .appendTo( $stickyHeaderCnt );
    var $stickyButtonsCnt = $( '<div class="sticky-buttons">' )
        .appendTo( $stickyHeaderCnt );

    var handleScroll = throttle( function () {
        if ( pageTitle.getBoundingClientRect().bottom < 0 ) {
            if ( !isVisible ) {
                isVisible = true;
                $stickyHeaderCnt.addClass( 'is-visible' );
            }
        } else {
            isVisible = false;
            $stickyHeaderCnt.removeClass( 'is-visible' );
        }
    }, 100 );
        
    handleScroll();
    window.addEventListener( 'scroll', handleScroll, {
        passive: !0
    } );
}