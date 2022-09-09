/* ↓ GLOBAL JS FROM ENGLISH WIKI ↓ */
mw.loader.using( 'site', function () {
    mw.loader.using( 'en:site', function () {
        mw.loader.load( '/load.php?lang=en&modules=ext.gadget.StickyHeader&skin=vector' );
    } );
} );