var I18n, instance, observer, intersectPoint;
var isBoundToTitle = !mw.config.get( 'wgIsMainPage' );


function StickyHeader() {
    this.$search = $( '#p-search' );
    this.$searchParent = this.$search.parent();
    
    this.isVisible = false;
    this.$stickyHeaderCnt = $( '<header id="ark-sticky-header">' )
        .insertAfter( '#wikigg-header' );
    this.$stickyName = $( '<a>' )
        .attr( 'href', mw.config.get( 'wgScriptPath' ) || '/' )
        .prepend( $( '<img width=32 height=32 alt="" />' )
            .attr( 'src', $( 'link[rel="shortcut icon"]' ).attr( 'href' ) ) )
        .append( $( '<span> ')
            .text( mw.config.get( 'wgSiteName' ) ) )
        .appendTo( $( '<div class="sticky-wiki-name">' )
            .appendTo( this.$stickyHeaderCnt ) );
    this.$stickySearchContainer = $( '<div class="sticky-search-box">' )
        .appendTo( this.$stickyHeaderCnt );
    this.$stickyButtonsCnt = $( '<div class="sticky-buttons">' )
        .appendTo( this.$stickyHeaderCnt );
    
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
}


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


var _handleIntersection = function ( entries ) {
    if ( entries[0].boundingClientRect.y < 0 ) {
        if ( !instance.isVisible ) {
            instance.show();
        }
    } else {
        instance.hide();
    }
};


mw.loader.using( 'site', function () {
    I18n = arkCreateI18nInterface( 'StickyHeader', {
        en: {
            BackToTop: 'Back to top',
            Edit: 'Edit',
            History: 'History',
            Talk: 'Discuss'
        }
    } );

    $( function () {
        // Initialise the sticky header
        instance = new StickyHeader();
        // Get #firstHeading or #mw-content-text as the intersection point
        intersectPoint = $( isBoundToTitle ? '#firstHeading' : '#top' ).get( 0 );
        // Set up the intersection observer
        observer = new IntersectionObserver( _handleIntersection, {
            threshold: isBoundToTitle ? 1 : 0
        } );
        observer.observe( intersectPoint );
    } );
} );

