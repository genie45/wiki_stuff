/* ↓ GLOBAL JS FROM ENGLISH WIKI ↓ */
mw.loader.using( 'site', function () {
    mw.loader.using( 'en:site',
        mw.loader.load.bind( mw.loader, '/load.php?lang=en-gb&modules=ext.gadget.StickyHeader&skin=vector' ) );
} );