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
        TAGS: 'Categories',
        TAGS_TEXT: 'Select the types of commands you want to see below.',
        COUNTER_TEXT: 'commands found',
        FILTER_ASA: 'Survival Ascended',
        FILTER_ASE: 'Survival Evolved',
        FILTER_CHEAT: 'Include cheats',
    }
} );

var FILTERS = [ 'cheat', 'asa', 'ase' ];


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
        if ( element.getAttribute( 'data-cheat' ) === '1' ) {
            tags.push( 'cheat' );
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


function buildSearchExecutor( commandIndex, tagRegistry ) {
    var result = {
        query: null,
        enabledTags: {},
        specialTags: {},

        update: function () {
            if ( this.query && this.query.length === 0 ) {
                this.query = null;
            }

            var
                query = this.query,
                enabledTags = Object.entries( this.enabledTags )
                    .filter( function ( pair ) {
                        return pair[ 1 ] === true;
                    } )
                    .map( function ( pair ) {
                        return pair[ 0 ];
                    } ),
                specials = this.specialTags;
            
            enabledTags = enabledTags.length > 0 ? new Set( enabledTags ) : null;

            var counter = 0;
            commandIndex.forEach( function ( command ) {
                var isVisible = true;
                if ( isVisible && specials.asa ) {
                    isVisible = command.tags.includes( 'asa' );
                }
                if ( isVisible && specials.ase ) {
                    isVisible = command.tags.includes( 'ase' );
                }
                if ( isVisible && !specials.cheat ) {
                    isVisible = !command.tags.includes( 'cheat' );
                }
                if ( isVisible && query ) {
                    isVisible = command.name.toLowerCase().includes( query );
                }
                if ( isVisible && enabledTags ) {
                    isVisible = command.tags.some( function ( value ) {
                        return enabledTags.has( value );
                    } );
                }

                command.element.style.display = isVisible ? '' : 'none';

                counter += isVisible ? 1 : 0;
            } );

            if ( this.counter ) {
                this.counter.innerText = counter + ' ' + Text.COUNTER_TEXT;
            }
        },
    };
    result.update = result.update.bind( result );

    Object.getOwnPropertyNames( tagRegistry ).forEach( function ( value ) {
        result.enabledTags[ value ] = true;
    } );

    return result;
}


function constructTagsBoard( tagRegistry, searchExecutor ) {
    function _constructTagToggle( id, displayName, className, defaultValue, isSpecial ) {
        var tagElement = document.createElement( 'div' );
        tagElement.className = className;

        var checkbox = document.createElement( 'input' );
        checkbox.type = 'checkbox';
        checkbox.checked = defaultValue;
        searchExecutor[ isSpecial ? 'specialTags' : 'enabledTags' ][ id ] = defaultValue;

        var label = document.createElement( 'label' );
        label.textContent = displayName;
        checkbox.id = label.htmlFor = className + '--' + id;

        checkbox.addEventListener( 'change', function () {
            searchExecutor[ isSpecial ? 'specialTags' : 'enabledTags' ][ id ] = checkbox.checked;
            searchExecutor.update();
        } );

        tagElement.appendChild( checkbox );
        tagElement.appendChild( label );

        return tagElement;
    }

    function _constructTags() {
        var container = document.createElement( 'div' );
        container.className = 'console-filters__box--tags console-filters__box';
    
        var heading = document.createElement( 'h4' );
        heading.textContent = Text.TAGS;
    
        var info = document.createElement( 'p' );
        info.textContent = Text.TAGS_TEXT;

        var tagContainer = document.createElement( 'div' );
        tagContainer.className = 'console-filters__tags-container';

        Object.getOwnPropertyNames( tagRegistry )
            .forEach( function ( name ) {
                tagContainer.appendChild( _constructTagToggle(
                    name,
                    tagRegistry[ name ],
                    'console-filters__tag',
                    false,
                    false
                ) );
            } );

        container.appendChild( heading );
        container.appendChild( info );
        container.appendChild( tagContainer );
        return container;
    }

    function _constructFilters() {
        var container = document.createElement( 'div' );
        container.className = 'console-filters__box--filters console-filters__box';

        FILTERS
            .forEach( function ( name ) {
                container.appendChild( _constructTagToggle(
                    name,
                    Text[ 'FILTER_' + name.toUpperCase() ],
                    'console-filters__filter-toggle',
                    true,
                    true
                ) );
            } );

        return container;
    }

    var container = document.createElement( 'div' );
    container.className = 'console-filters__tags-section';
    container.appendChild( _constructTags() );
    container.appendChild( _constructFilters() );
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

    searchExecutor.counter = document.createElement( 'div' );
    searchExecutor.counter.className = 'console-filters__counter';
    container.appendChild( searchExecutor.counter );
    
    container.appendChild( searchInput );
    return container;
}


function main() {
	var container = document.querySelector( '#console-filters' ),
        tagRegistry = gatherTags( container ),
    	commandIndex = buildCommandIndex( container.parentElement ),
        searchExecutor = buildSearchExecutor( commandIndex, tagRegistry );
    
    container.insertAdjacentElement( 'beforebegin', constructTagsBoard( tagRegistry, searchExecutor ) );
    container.appendChild( constructSearchBar( searchExecutor ) );

	container.setAttribute( 'data-loaded', true );

    searchExecutor.update();
}


main();
