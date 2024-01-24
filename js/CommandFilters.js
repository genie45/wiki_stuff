/**
 * This script is loaded from the English wiki on all international wikis.
 * Translators do not need to copy it to their wiki.
 */



function buildCommandIndex( contentElement ) {
    var results = [];
    contentElement.querySelectorAll( 'div.console-command' ).forEach( function ( element ) {
        var tags = ( element.getAttribute( 'data-tags' ) || '' )
            .split( ';' )
            .filter( function ( element ) {
                return element.length > 0;
            } );

        if ( element.getAttribute( 'data-asa' ) === '1' ) {
            tags.push( 'asa' );
        }
        if ( element.getAttribute( 'data-ase' ) === '1' ) {
            tags.push( 'ase' );
        }

        results.push( {
            element: element,
            name: element.getAttribute( 'data-name' ),
            isCheat: element.getAttribute( 'data-cheat' ) === '1' ? true : false,
            tags: tags,
        } );
    } );
    return results;
}


function gatherTags( setupElement ) {
    var results = {};
    var namePrefix = 'data-tag-';
    Object.getOwnPropertyNames( setupElement.attributes )
        .filter( function ( name ) {
            return name.startsWith( namePrefix );
        } )
        .forEach( function ( name ) {
            results[ name.slice( namePrefix.length ) ] = setupElement.attributes[ name ].value;
        } );
    return results;
}


function constructSearchBar( commandIndex ) {
    var searchInput;

    function _reevaluate() {
        var query = searchInput.value.trim().toLowerCase();
        commandIndex.forEach( function ( command ) {
            var isVisible = query === '' || command.name.toLowerCase().includes( query );
            command.element.style.display = isVisible ? '' : 'none';
        } );
    }
    _reevaluate = mw.util.debounce( _reevaluate, 80 );

    var container = document.createElement( 'div' );
    container.className = 'console-filters__search-box';
    
    searchInput = document.createElement( 'input' );
    searchInput.type = 'text';
    searchInput.placeholder = 'Start typing to search through commands...';
    
    searchInput.addEventListener( 'change', _reevaluate );
    searchInput.addEventListener( 'keydown', _reevaluate );
    
    container.appendChild( searchInput );
    return container;
}


function main() {
	var container = document.querySelector( '#console-filters' ),
        tagRegistry = gatherTags( container )
    	commandIndex = buildCommandIndex( container.parentElement );
    
    container.appendChild( constructSearchBar( commandIndex ) );

	container.setAttribute( 'data-loaded', true );
}


main();
