var ATTR_FILTER_BY = 'data-filter-by-';


function filterItems( items, bit, matcher ) {
    items.forEach( function ( item ) {
        var isMatched = matcher( item );
        // Mark the item if not matched, otherwise clear the bit
        item._mask = isMatched ? ( item._mask & ~bit ) : ( item._mask | bit );
        item.$element.css( 'opacity', ( item._mask == 0 ) ? 1 : 0.1 );
    } );
}


function initialiseFilter( items, attributeName, filterType, placeholderText, bit ) {
    var $result;
    switch ( filterType ) {
        case 'string':
            items.forEach( function ( item ) {
                item[attributeName] = ( item.$element.data( attributeName ) || '' ).toLowerCase();
            } );

            $result = $( '<input type="text" />' )
                .attr( 'placeholder', placeholderText )
                .on( 'input', function () {
                    var value = this.value.toLowerCase();
                    filterItems( items, bit, function ( item ) {
                        return !value || ( item[attributeName].indexOf( value ) >= 0 );
                    } );
                } );
            break;
        case 'value':
        case 'unsortedValue':
            var dataStore = [];
            items.forEach( function ( item ) {
                item[attributeName] = [];
                ( item.$element.data( attributeName ) || '' ).split( ',' ).forEach( function ( value ) {
                    value = value.trim();
                    if ( value.length > 0 ) {
                        var index = dataStore.indexOf( value );
                        if ( index < 0 ) {
                            dataStore.push( value );
                            index = dataStore.length - 1;
                        }
                        item[attributeName].push( index );
                    }
                } );
            } );
            
            $result = $( '<select>' )
                .append( $( '<option value="-1">' ).text( '-- ' + placeholderText + ' --' ) )
                .on( 'change', function () {
                    var value = parseInt( this.value );
                    filterItems( items, bit, function ( item ) {
                        return value == -1 || ( item[attributeName].indexOf( value ) >= 0 );
                    } );
                } );
            ( filterType == 'unsortedValue' ? dataStore : dataStore.slice().sort() ).forEach( function ( value ) {
                $result.append( $( '<option value="' + ( dataStore.indexOf( value ) ) + '">' ).text( value ) );
            } );
            break;
    }
    return $result;
}


function initialise( gridElement ) {
    var $grid = $( gridElement ),
        $filters = $( '<div class="creature-roster-filters">' ).insertBefore( gridElement ),
        items = [];
    
    $grid.find( '> li' ).each( function () {
        items.push( { $element: $( this ), _mask: 0 } );
    } );
    
    var index = 0;
    $.each( gridElement.attributes, function () {
        index++;
        if ( this.specified ) {
            if ( this.name.startsWith( ATTR_FILTER_BY ) ) {
                var parts = this.value.split( ',', 2 );
                initialiseFilter( items, this.name.substr( ATTR_FILTER_BY.length ), parts[0].trim(), parts[1].trim(), 1<<index )
                    .appendTo( $filters );
            }
        }
    } );
}


mw.hook( 'wikipage.content' ).add( function ( $content ) {
    $content.find( '.creature-roster' ).each( function () {
        initialise( this );
    } );
} );

