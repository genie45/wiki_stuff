var I18n, instance, intersectPoint, isMobile;
var isBoundToTitle = !mw.config.get( 'wgIsMainPage' );


function StickyHeader() {
    this.$search = $( '#p-search' );
    this.$searchParent = this.$search.parent();
    
    this.isVisible = false;
    this.$stickyHeaderCnt = $( '<header id="ark-sticky-header">' )
        .insertAfter( '#wikigg-header' );
    this.$stickyName = $( '<a>' )
        .attr( 'href', mw.config.get( 'wgScriptPath' ) || '/' )
        .prepend( $( '<img width=36 height=36 alt="" />' )
            .attr( 'src', $( 'link[rel="icon"]' ).attr( 'href' ) ) )
        .appendTo( $( '<div class="sticky-wiki-name">' ).appendTo( this.$stickyHeaderCnt ) );
    this._buildNameBox();
    this.$stickySearchContainer = $( '<div class="sticky-search-box">' )
        .appendTo( this.$stickyHeaderCnt );
    this.$stickyButtonsCnt = $( '<div class="sticky-buttons">' )
        .appendTo( this.$stickyHeaderCnt );

    var $toc = $( '#toc' );
	if ( $toc.length > 0 ) {
		this.$btnToC = $( '<a role="button" id="sticky-toc" class="with-icon">' )
			.attr( 'title', I18n( 'ToC' ) )
			.append( $( '<div class="toc">' )
				.append( $toc.find( '> ul' ).clone( true ) ) )
			.appendTo( this.$stickyButtonsCnt );
	}

    this.$btnEdit = this.cloneButton( 'edit', 'Edit' );
    this.$btnTalk = this.cloneButton( 'talk', 'Talk' );
    this.$btnHistory = this.cloneButton( 'history', 'History' );
    
    this.$btnBackToTop = $( '<a role="button" href="#">' )
        .text( I18n( 'BackToTop' ) )
        .appendTo( this.$stickyButtonsCnt );
}


StickyHeader.prototype.cloneButton = function ( id, messageName ) {
    var $ca = $( '#ca-'+id+' > a' );
    if ( $ca.length > 0 ) {
        return $( '<a role="button" class="with-icon" id="sticky-'+id+'">' )
            .attr( {
                href: $ca.attr( 'href' ),
                title: $ca.attr( 'title' )
            } )
            .text( I18n( messageName ) )
            .appendTo( this.$stickyButtonsCnt );
    }
    return null;
};


StickyHeader.prototype._buildNameBox = function () {
    var self = this;
	mw.loader.using( 'ext.themes.jsapi', function () {
		mw.loader.require( 'ext.themes.jsapi' ).whenCoreLoaded( function() {
			self.$stickyNameText = $( '<span> ').text( mw.config.get( 'wgSiteName' ) ).appendTo( self.$stickyName );
			if ( !mw.config.get( 'wgIsMainPage' ) && MwSkinTheme.getCurrent() === 'dark-test-fullwidth2023' ) {
				var pageTitle = $( '#firstHeading' ).length > 0 ? $( '#firstHeading' ).text() : mw.config.get( 'wgTitle' );
				self.$stickyNameText.append( $( '<span class="sticky-page-title">' ).text( pageTitle ) );
			}
		} );
	} );
};


StickyHeader.prototype.show = function () {
    isVisible = true;
    document.body.classList.add( 'is-sticky-header-visible' );
    this.$search.appendTo( this.$stickySearchContainer );
};
    

StickyHeader.prototype.hide = function () {
    isVisible = false;
    document.body.classList.remove( 'is-sticky-header-visible' );
    this.$search.appendTo( this.$searchParent );
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
        instance.hide();
    }
}, 100 );


mw.loader.using( 'site', function () {
    I18n = arkCreateI18nInterface( 'StickyHeader', {
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
