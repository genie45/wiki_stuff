var Text, instance, intersectPoint, isMobile;
var isBoundToTitle = !mw.config.get( 'wgIsMainPage' );


function StickyHeader() {
    this.$search = $( '#p-search' );
    this.$searchInput = this.$search.find( '#searchInput' );
    this.$searchParent = this.$search.parent();
    
    this.isVisible = false;
    this.$stickyHeaderCnt = $( '<header id="ark-sticky-header">' )
        .insertAfter( '#wikigg-header' );
    this.$stickyName = $( '<a>' )
        .attr( 'href', mw.config.get( 'wgScriptPath' ) || '/' )
        .prepend( $( '<img width=36 height=36 alt="" />' )
            .attr( 'src', $( 'link[rel="icon"]' ).attr( 'href' ) ) )
        .appendTo( $( '<div class="ark-sticky-header__page-box">' ).appendTo( this.$stickyHeaderCnt ) );
    this._buildNameBox();
    this.$stickySearchContainer = $( '<div class="ark-sticky-header__search-box">' )
        .appendTo( this.$stickyHeaderCnt );
    this.$stickyButtonsCnt = $( '<div class="ark-sticky-header__button-box">' )
        .appendTo( this.$stickyHeaderCnt );

    var $toc = $( '#toc' );
	if ( $toc.length > 0 ) {
		this.$btnToC = this.constructButton( 'toc', null, Text.ToC, null )
			.append( $( '<div class="toc">' )
				.append( $toc.find( '> ul' ).clone( true ) ) );
	}

    this.$btnEdit = this.cloneButton( 'edit', 'Edit' );
    this.$btnTalk = this.cloneButton( 'talk', 'Talk' );
    this.$btnHistory = this.cloneButton( 'history', 'History' );
    
    this.$btnBackToTop = $( '<a id="ark-top-button" role="button" aria-hidden="true" href="#top">' )
        .attr( 'title', Text.BackToTop )
        .insertAfter( '.content-wrapper' );
}


StickyHeader.prototype.constructButton = function ( id, href, title, message ) {
    return $( '<a role="button" class="ark-sticky-header__button ark-sticky-header__button--with-icon" id="sticky-'+id+'">' )
        .attr( {
            href: href,
            title: title
        } )
        .text( message !== null ? Text[ message ] : '' )
        .appendTo( this.$stickyButtonsCnt );
}


StickyHeader.prototype.cloneButton = function ( id, constructButton ) {
    var $ca = $( '#ca-'+id+' > a' );
    if ( $ca.length > 0 ) {
        return this.constructButton( id, $ca.attr( 'href' ), $ca.attr( 'title' ), constructButton );
    }
    return null;
};


StickyHeader.prototype._buildNameBox = function () {
	var pageTitle = $( '#firstHeading' ).length > 0 ? $( '#firstHeading' ).text() : mw.config.get( 'wgTitle' );
    this.$stickyNameText = $( '<span class="ark-sticky-header__wiki-title"> ').text( mw.config.get( 'wgSiteName' ) ).appendTo( this.$stickyName );
    if ( !mw.config.get( 'wgIsMainPage' ) ) {
	    this.$stickyNameText.append( $( '<span class="ark-sticky-header__page-title">' ).text( pageTitle ) );
    }
};


StickyHeader.prototype.show = function () {
    this.isVisible = true;
    document.documentElement.classList.add( 'is-sticky-header-visible' );
    this.$search.appendTo( this.$stickySearchContainer );

    this._tickSearchSuggestUpdate();
};

StickyHeader.prototype.hide = function () {
    this.isVisible = false;
    document.documentElement.classList.remove( 'is-sticky-header-visible' );
    this.$search.appendTo( this.$searchParent );

    this._tickSearchSuggestUpdate();
};


StickyHeader.prototype._tickSearchSuggestUpdate = function () {
    var _this = this;
    requestAnimationFrame( function () {
        _this._tickSearchSuggestUpdateInternal();
    } );
};


StickyHeader.prototype._tickSearchSuggestUpdateInternal = function () {
    var $suggestions = $( 'body > .suggestions' );
    if ( this.$searchInput.val().length <= 0 || !$suggestions.is( ':visible' ) ) {
        return;
    }

    // This *is* a nice hack, but causes flicker at certain breakpoints if fired too frequently, and the `top` anchor
    // will be incorrect once the header slides out.
    this.$searchInput.trigger( 'blur' ).trigger( 'keydown' ).trigger( 'keypress' ).trigger( 'keyup' );

    // So let's correct the anchor every frame until we reach no change in the header's height
    var previousBottom = -1, lastCallCount = 2;
    var _this = this;
    function _syncAnchors() {
        if ( !_this.isVisible ) {
            return;
        }

        var bottom = _this.$stickySearchContainer[ 0 ].getBoundingClientRect().bottom;
        if ( bottom !== previousBottom && --lastCallCount > 0 ) {
            $suggestions.css( 'top', bottom );
            previousBottom = bottom;
            requestAnimationFrame( _syncAnchors );
        }
    }
    requestAnimationFrame( _syncAnchors );
};


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


var _handleScroll = throttle( function () {
    var anchor;
    if ( screen.width > 720 ) {
        anchor = intersectPoint.getBoundingClientRect().bottom;
    } else {
        anchor = screen.height * 0.8 - scrollY;
    }
    if ( anchor < 0 ) {
        if ( !instance.isVisible ) {
            instance.show();
        }
    } else {
        if ( instance.isVisible ) {
            instance.hide();
        }
    }
}, 100 );


mw.loader.using( 'site', function () {
    Text = arkCreateI18nInterfaceEx( 'StickyHeader', {
        en: {
            BackToTop: 'Back to top',
            Edit: 'Edit',
            History: 'History',
            Talk: 'Discuss',
            ToC: 'Table of contents'
        },
		fr: {
            BackToTop: 'Haut de page',
            Edit: 'Éditer',
            History: 'Historique',
            Talk: 'Discussion'
        }
    } );

    $( function () {
        // Initialise the sticky header
        instance = new StickyHeader();
        // Get #firstHeading or #mw-content-text as the intersection point
        intersectPoint = $( isBoundToTitle ? '#firstHeading' : '#top' ).get( 0 );
        // Set up the scroll observer
        _handleScroll();
        window.addEventListener( 'scroll', _handleScroll, {
            passive: true
        } );
    } );
} );
