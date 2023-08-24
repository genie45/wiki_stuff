var shouldBypassCache = window.location.search.substr( 1 ).split( '&' ).indexOf( 'arkdata=no-cache' ) >= 0;
var CACHE_DURATION = shouldBypassCache ? 1 : 60 * 60 * 36;

window.arkLoadDataPages = function( pages, forceRecacheId ) {
    var results = {},
        scriptPath = mw.config.get( 'wgScriptPath' );

    return Promise.all( pages.map( function ( pageName ) {
        var isRequestingMain = pageName.startsWith( 'en:' ),
            outName = pageName,
            query = {
                action: 'raw',
                ctype: 'application/json',
                maxage: CACHE_DURATION,
                smaxage: CACHE_DURATION,
            };
        if ( forceRecacheId ) {
            query.cb = forceRecacheId;
        }
        if ( isRequestingMain ) {
            pageName = pageName.slice( 3 );
        }

        var url = mw.util.getUrl( pageName, query );
        if ( isRequestingMain && mw.config.get( 'wgContentLanguage' ) !== 'en' && url.startsWith( scriptPath ) ) {
            url = url.slice( scriptPath.length );
        }

        return fetch( url ).then( function ( response ) {
            return response.json().then( function ( data ) {
                results[outName] = data;
            } );
        } );
    } ) ).then( function () {
        return Promise.resolve( results );
    } );
};

