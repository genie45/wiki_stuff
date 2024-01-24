/**
 * This script is loaded from the English wiki on all international wikis.
 * Translators do not need to copy it to their wiki.
 */


/**
 * If you're a translator wanting to have your translations added here, leave a message on the talk page with all
 * string translations.
 */
var Text = arkCreateI18nInterfaceEx( 'CommandFilters', {
    en: {
        SEARCH_TIP: 'Start typing to search through commands...',
        TAGS: 'Tags (currently non-interactive)',
    }
} );



function buildCommandIndex( contentElement ) {
    var results = [];
    contentElement.querySelectorAll( 'div.console-command' ).forEach( function ( element ) {
        var tags = ( element.getAttribute( 'data-tags' ) || '' )
            .split( ';' )
            .filter( function ( element ) {
                return element.length > 0;
            } );

        if ( tags.length === 0 ) {
            tags.push( 'fallback' );
        }
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


function constructTagsBoard( commandIndex, tagRegistry ) {
    var container = document.createElement( 'div' );
    container.className = 'console-filters__tags-box console-filters__box';
    
    var heading = document.createElement( 'h4' );
    heading.textContent = Text.TAGS;

    var tagContainer = document.createElement( 'div' );
    tagContainer.className = 'console-filters__tags-container';

    Object.getOwnPropertyNames( tagRegistry )
        .forEach( function ( name ) {
            var displayName = tagRegistry[ name ];

            var tagElement = document.createElement( 'div' );
            tagElement.className = 'console-filters__tag';

            var checkbox = document.createElement( 'input' );
            checkbox.type = 'checkbox';
            checkbox.checked = true;

            var label = document.createElement( 'label' );
            label.textContent = displayName;
            checkbox.name = label.for = 'console-filter__tag--' + name;

            tagElement.appendChild( checkbox );
            tagElement.appendChild( label );
            tagContainer.appendChild( tagElement );
        } );

    container.appendChild( heading );
    container.appendChild( tagContainer );
    return container;
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
    searchInput.placeholder = Text.SEARCH_TIP;
    
    searchInput.addEventListener( 'change', _reevaluate );
    searchInput.addEventListener( 'keydown', _reevaluate );
    
    container.appendChild( searchInput );
    return container;
}


function main() {
	var container = document.querySelector( '#console-filters' ),
        tagRegistry = gatherTags( container )
    	commandIndex = buildCommandIndex( container.parentElement );
    
    container.appendChild( constructTagsBoard( commandIndex, tagRegistry ) );
    container.appendChild( constructSearchBar( commandIndex ) );

	container.setAttribute( 'data-loaded', true );
}


main();
