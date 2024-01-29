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
        TAGS: 'Tags',
        TAGS_TEXT: 'Select the types of commands you want to see below.',
    }
} );



function buildCommandIndex( contentElement ) {
    var results = [];
    contentElement.querySelectorAll( 'div.console-command' ).forEach( function ( element ) {
        var tags = ( element.getAttribute( 'data-tags' ) || '' )
            .split( ' ' )
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


function buildSearchExecutor( commandIndex ) {
    var result = {
        query: null,
        enabledTags: {},
        update: function () {
            if ( this.query.length === 0 ) {
                this.query = null;
            }

            var tags = Object.entries( this.enabledTags )
                .filter( function ( pair ) {
                    return pair[ 1 ] === true;
                } )
                .map( function ( pair ) {
                    return pair[ 0 ];
                } );
            tags = tags.length > 0 ? tags : null;

            commandIndex.forEach( function ( command ) {
                var isVisible = true;
                if ( this.query ) {
                    isVisible = isVisible && command.name.toLowerCase().includes( query );
                }
                if ( tags ) {
                    isVisible = isVisible && command.tags.some( function ( value ) {
                        return tags.includes( value );
                    } );
                }
                command.element.style.display = isVisible ? '' : 'none';
            } );
        },
    };
    result.update = result.update.bind( result );
    return result;
}


function constructTagsBoard( tagRegistry, searchExecutor ) {
    var container = document.createElement( 'div' );
    container.className = 'console-filters__tags-box console-filters__box';
    
    var heading = document.createElement( 'h4' );
    heading.textContent = Text.TAGS;
    
    var info = document.createElement( 'p' );
    info.textContent = Text.TAGS_TEXT;

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
            checkbox.name = label.htmlFor = 'console-filter__tag--' + name;

            checkbox.addEventListener( 'change', function () {
                tagRegistry[ name ] = checkbox.checked;
                searchExecutor.update();
            } );

            tagElement.appendChild( checkbox );
            tagElement.appendChild( label );
            tagContainer.appendChild( tagElement );
        } );

    container.appendChild( heading );
    container.appendChild( info );
    container.appendChild( tagContainer );
    return container;
}


function constructSearchBar( searchExecutor ) {
    var searchInput;

    _reevaluate = mw.util.debounce( function () {
        searchExecutor.query = searchInput.value.trim().toLowerCase();
        searchExecutor.update();
    }, 80 );

    var container = document.createElement( 'div' );
    container.className = 'console-filters__search-box';
    
    searchInput = document.createElement( 'input' );
    searchInput.type = 'text';
    searchInput.placeholder = Text.SEARCH_TIP;
    
    searchInput.addEventListener( 'input', _reevaluate );
    
    container.appendChild( searchInput );
    return container;
}


function main() {
	var container = document.querySelector( '#console-filters' ),
        tagRegistry = gatherTags( container ),
    	commandIndex = buildCommandIndex( container.parentElement ),
        searchExecutor = buildSearchExecutor( commandIndex );
    
    container.appendChild( constructTagsBoard( tagRegistry, searchExecutor ) );
    container.appendChild( constructSearchBar( searchExecutor ) );

	container.setAttribute( 'data-loaded', true );
}


main();
