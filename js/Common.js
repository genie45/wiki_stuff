/* Any JavaScript here will be loaded for all users on every page load. */

// #region I18n accessor factory
// This takes in a module name and a localised string table (map[language -> map[name -> string]]),
// and returns a function to look-up a string by its name.
// Translations should either be put into the script's string table, or provided locally via
// [[MediaWiki:Common.js]].
// To provide a string locally, provide window.arkLocalI18n (map[module -> map[name -> string]]).
window.arkCreateI18nInterface = function(module, strings) {
    var lang = mw.config.get('wgPageContentLanguage');
    var localStrings = window.arkLocalI18n && window.arkLocalI18n[module];
    return function (key) {
        return ( // try from local store
                 (localStrings && localStrings[key])
                 // try from script store
                 || (strings[lang] && strings[lang][key] || strings['en'][key])
                 // fallback
                 || '<'+key+'>' );
    };
};
window.arkCreateI18nInterfaceEx = function ( module, strings ) {
    var lang = mw.config.get( 'wgPageContentLanguage' );
    var localStrings = window.arkLocalI18n && window.arkLocalI18n[ module ];

    return Object.assign(
        {},
        strings[ 'en' ],
        strings[ lang ],
        localStrings
    );
};
// #endregion


// #region importArticles with transparent EN interwiki support
// Strip "en:" prefix on EN wiki, or prepend "u:" on translations
window.arkIsEnglishWiki = mw.config.get('wgContentLanguage') == 'en';
window.arkImportArticles = function ( articles ) {
    var mLocal = [], mGlobal = [];
    articles.forEach( function ( item ) {
        if ( item.startsWith( 'en:' ) ) {
            mGlobal.push( item.slice( 3 ) );
        } else {
            mLocal.push( item );
        }
    } );
    if ( arkIsEnglishWiki ) {
        mLocal = mLocal.concat( mGlobal );
        mGlobal.length = 0;
    }
    // Load global modules
    if ( mGlobal.length ) {
        mw.loader.load( '/load.php?lang=en&modules=' + encodeURIComponent( mGlobal.join( '|' ) )
        	+ '&skin=vector&version=ztntf' + ( mw.config.get( 'debug' ) ? '&debug=1' : '' ) );
    }
    // Load local modules
    if ( mLocal.length ) {
        // Race warning: the ImportArticles extension script might be loaded after our script. Require it before executing the call.
        mw.loader.using( 'ext.importarticles', function () {
            importArticles( { type: 'script', articles: mLocal } );
        } );
    }
};
window.arkUsingArticles = function( articles, callback ) {
    return mw.loader.using( articles.map( function ( item ) {
        return item.startsWith( 'en:' ) ? item.slice( 3 ) : item;
    } ), callback );
};
// #endregion


// #region Conditionally loaded modules
// Extracted into global scope, so translation wikis or gadgets can insert their own if needed in future.
window.arkConditionalModules = (window.arkConditionalModules||[]).concat( [
    // [[Template:LoadPage]]
    { sel: '.load-page',
      pages: [ 'en:MediaWiki:LoadPage.js' ] },
    // Countdown timers
    { sel: '.countdown',
      pages: [ 'en:MediaWiki:Countdown.js' ] },
    // Cooking calculator
    { sel: '#cookingCalc',
      pages: [ 'MediaWiki:Cooking calculator.js' ] },
    // ARK Code calculator
    { sel: '.ARKCode-container',
      pages: [ 'MediaWiki:ARKCode.js' ] },
    // Creature article scripts
    { sel: '.cloningcalc, .killxpcalc',
      pages: [
        // Kill XP calculator
        'en:MediaWiki:KillXP.js',
        // Experimental cloning calculator
        'en:MediaWiki:CloningCalculator.js' 
    ] },
    // Legacy element animator
    { sel: '.animated',
      pages: [ 'en:MediaWiki:LegacyElementAnimator.js' ] },
    // Legacy [[Template:Nav creatures]] grid filtering
    { sel: '#creature-grid',
      pages: [ 'MediaWiki:CreatureGridFiltering.js' ] },
    // [[Template:Nav creatures]] grid filtering
    { sel: '.creature-roster',
      pages: [ 'MediaWiki:NavboxGrid.js' ] },
    // [[Console commands]] filtering
    { sel: '#console-filters',
      pages: [ 'en:MediaWiki:CommandFilters.js' ] },
    // Common Data page fetch function if a wild stats calculator, spawn map or an interactive region map are present.
    // Separate request for cache efficiency (load once, not every time for a combination).
    { sel: [ '#wildStatCalc', '.data-map-container[data-spawn-data-page-name]', '.interactive-regionmap',
        '.ext-datamaps-container-content', '.live-server-rates' ],
      pages: [ 'en:MediaWiki:DataFetch.js' ] },
    // Official server rates module
    { sel: '.live-server-rates',
      pages: [ 'en:MediaWiki:ServerRates.js' ] },
    // Wild creature stats calculator
    { sel: '#wildStatCalc',
      pages: [ 'MediaWiki:WildCreatureStats.js' ] },
    // Interactive region map
    { sel: '.interactive-regionmap',
      pages: [ 'en:MediaWiki:RegionMaps.js' ] },
    // Legacy data map scripts
    { sel: '.data-map-container',
      pages: [ 'en:MediaWiki:TemplateResourceMap.css', 'en:MediaWiki:ResourceMaps.js', 'en:MediaWiki:SpawnMaps.js' ] },
    // Load ext.datamaps.site from EN wiki (this needs to be two separate requests or the backend hates it, *yuck*)
    { sel: '.ext-datamaps-container-content',
      pages: [ 'en:MediaWiki:DataMaps.js' ],
      cond: !arkIsEnglishWiki },
    { sel: '.ext-datamaps-container-content',
      pages: [ 'en:MediaWiki:DataMaps.css' ],
      cond: !arkIsEnglishWiki }
] );
// #endregion


// #region #mw-head collapsing hacks
mw.loader.using('skins.vector.legacy.js', function() {
    var _realHandleResize = $.collapsibleTabs.handleResize,
        _realCalculateTabDistance = $.collapsibleTabs.calculateTabDistance;
    // Disable animations
    $.collapsibleTabs.handleResize = function () {
        _realHandleResize();
        $('#mw-head .mw-portlet .collapsible').finish();
    };
    // Normalise tab distance and force collapsing on main page
    $.collapsibleTabs.calculateTabDistance = function () {
        if ( document.body.classList.contains( 'rootpage-ARK_Wiki' ) ) {
            return -1;
        }

        var ret = _realCalculateTabDistance();
        return ret <= 0 ? -1 : ret;
    };

    // Request a reevaluation on main page
    $( function () {
        if ( document.body.classList.contains( 'rootpage-ARK_Wiki' ) ) {
            $.collapsibleTabs.handleResize();
        }
    } );
});
// #endregion


// #region Restore sidebar state
var SIDEBAR_HIDDEN_CLASS = 'is-sidebar-hidden';
if ( localStorage.getItem( SIDEBAR_HIDDEN_CLASS ) == '1' ) {
    document.documentElement.classList.add( SIDEBAR_HIDDEN_CLASS );
}
// #endregion


/* Fires when DOM is ready */
$(function() {
    ( function () {
        if ( mw.config.get( 'wgIsArticle' )
            && !mw.config.get( 'wgIsMainPage' ) /* handled by Extension:StructuredData */
            && mw.config.get( 'wgContentNamespaces' ).indexOf( mw.config.get( 'wgNamespaceNumber' ) ) >= 0 ) {
            var ogImage = document.querySelector( 'meta[property="og:image"]' );
            var script = document.createElement('script');
            script.type = "application/ld+json";
            script.innerHTML = JSON.stringify( {
                "@context": "http://www.schema.org",
                "@type": "Article",
                name: mw.config.get( 'wgTitle' ),
                headline: mw.config.get( 'wgTitle' ),
                image: {
                    "@type": "ImageObject",
                    url: ogImage ? ogImage.getAttribute( 'content' ) : "https://ark.wiki.gg/images/e/e6/Site-logo.png?5b2cf"
                },
                author: {
                    "@type": "Organization",
                    name: 'Contributors to the ' + mw.config.get( 'wgSiteName' ),
                    url: mw.config.get( 'wgServer' )
                },
                publisher: {
                    "@type": "Organization",
                    name: mw.config.get( 'wgSiteName' ),
                    url: mw.config.get( 'wgServer' ),
                    logo: {
                        "@type": "ImageObject",
                        url: "https://ark.wiki.gg/images/e/e6/Site-logo.png?5b2cf"
                    }
                },
                potentialAction: {
                    "@type": "SearchAction",
                    target: mw.config.get( 'wgServer' ) + "/wiki/Special:Search?search={search_term}",
                    "query-input": "required name=search_term"
                },
                mainEntityOfPage: mw.config.get( 'wgPageName' )
            } );
            document.body.appendChild( script );
        }
    } )();

    // #region Sidebar ToC
    ( function () {
        var tocListElement = document.querySelector( '#toc > ul' );
        if ( tocListElement ) {
            var tocHeadingText = document.querySelector( '#mw-toc-heading' ).textContent;
            var sidebarToc = document.createElement( 'div' ),
                sidebarTocHeading = document.createElement( 'h3' )
                sidebarTocLabel = document.createElement( 'span' ),
                sidebarTocContent = document.createElement( 'div' );
            sidebarToc.id = 'p-stoc';
            sidebarToc.className = 'vector-menu mw-portlet mw-portlet-stoc vector-menu-portal';
            sidebarToc.setAttribute( 'aria-labelledby', 'p-stoc-label' );
            sidebarToc.setAttribute( 'role', 'navigation' );
            sidebarTocHeading.id = 'p-stoc-label';
            sidebarTocHeading.className = 'vector-menu-heading';
            sidebarTocLabel.className = 'vector-menu-heading-label';
            sidebarTocLabel.textContent = tocHeadingText;
            sidebarTocContent.className = 'vector-menu-content';

            sidebarTocHeading.appendChild( sidebarTocLabel );
            sidebarTocContent.append( tocListElement.cloneNode( true ) );
            sidebarToc.appendChild( sidebarTocHeading );
            sidebarToc.appendChild( sidebarTocContent );
            document.querySelector( '#mw-panel' ).appendChild( sidebarToc );
        }
    } )();
    // #endregion

    // #region Make sidebar sections collapsible
    $("#mw-panel .portal").each(function(index, el){
        var $el = $(el);
        var $id = $el.attr("id");
        if(!$id){
            return;
        }
        if(localStorage.getItem('sidebar_c_'+$id) === "y"){
            $el.addClass('collapsed');
        }
    });
    $("#mw-panel .portal").on("click", "h3", function(event){
        var $el = $(this).parent();
        var $id = $el.attr("id");
        if(!$id){
            return;
        }
        event.stopPropagation();
        $el.toggleClass('collapsed');
        if($el.hasClass('collapsed')){ // more consistent between class and slide status.
            localStorage.setItem('sidebar_c_'+$id, "y");
        }
        else{
            localStorage.setItem('sidebar_c_'+$id, "n");
        }
    });
    // #endregion
    
    // #region Sidebar toggle
    ( function () {
        $( '<div id="nav-sidebar-toggle">' )
	        .prependTo( '#left-navigation' )
	        .on( 'click', function () {
		        document.documentElement.classList.toggle( SIDEBAR_HIDDEN_CLASS );
                localStorage.setItem( SIDEBAR_HIDDEN_CLASS, $( 'body' ).hasClass( SIDEBAR_HIDDEN_CLASS ) ? '1' : '0' );
	        } );
    } )();
    // #endregion
    
    // #region Dynamic site notice
    ( function () {
        var I18n = arkCreateI18nInterface( 'DynamicSiteNotice', {
            en: {
                Text_ASAUpdateRelease: 'Articles will be brought up to date with ARK: Survival Ascended over the following weeks.',
            },
            fr: {
                Text_ASAUpdateRelease: 'Les articles sur ARK: Survival Ascended seront mis à jour dans les semaines à venir.',
            },
            ru: {
                Text_ASAUpdateRelease: 'В течение следующих недель мы будем обновлять статьи, посвященные ARK: Survival Ascended.',
            }
        } );

        // PROCEDURES:
        // - IF ASA LAUNCHES DURING EVENT: bump wgSiteNoticeId, swap text key to Text_ASAUpdateRelease
        // - IF ASA DOESN'T LAUNCH AND EVENT ENDS: comment out the notice, switch to Text_ASAUpdateRelease for future

    	var snContent = I18n( 'Text_ASAUpdateRelease' );
    	$( '#siteNotice' ).prepend( '<div id="localNotice" dir="ltr" lang="en"><p style="font-size: 110%">'+snContent+'</p></div>' );
    } )();
    // #endregion

    // #region Interwiki dropdown
    ( function () {
        var I18n = arkCreateI18nInterface('InterwikiDropdown', {
            de: { Label: ' Sprachen' },
            en: { Label: /*NUMBER*/' languages' },
            es: { Label: ' idiomas' },
            fr: { Label: ' langues' },
            it: { Label: ' lingue' },
            ja: { Label: 'の言語版' },
            pl: { Label: ' języki' },
            'pt-br': { Label: ' idiomas' },
            ru: { Label: ' язык' },
            th: { Label: ' ภาษา' }
        });
        
        if (!mw.config.get('wgIsMainPage') && mw.config.get('wgIsArticle')) {
            var $sidebarInterwikis = $('#p-lang > .vector-menu-content > ul > li.interlanguage-link');
            if ($sidebarInterwikis.length > 0) {
                var $menu = $('<ul class="vector-menu-content-list">');
                $('<div id="p-lang-btn" class="mw-portlet vector-menu vector-menu-dropdown" aria-labelledby="p-lang-btn-label" role="navigation">')
                    .insertBefore($('#firstHeading'))
                    .append($('<input type="checkbox" id="p-lang-btn-checkbox" role="button" class="mw-interlanguage-selector vector-menu-checkbox"/>'))
                    .append($('<label id="p-lang-btn-label" class="vector-menu-heading" aria-hidden="true">')
                            .append($('<span>')
                                    .text(($sidebarInterwikis.length+1) + I18n('Label'))))
                    .append($('<div class="vector-menu-content">').append($menu));
                $sidebarInterwikis.each(function() {
                    $menu.append($(this).clone());
                });
            }
        }
    } )();
    // #endregion

    // #region Copy to clipboard
    ( function () {
        var I18n = arkCreateI18nInterface('CopyToClipboard', {
            en: {
                ButtonTitle: 'Copy to clipboard',
                Success: 'Successfully copied to clipboard.',
                Failure: 'Copy to Clipboard failed. Please do it yourself.'
            },
            fr: {
                ButtonTitle: 'Copier vers le presse-papier',
                Success: 'Copié avec succès vers le presse-papier.',
                Failure: 'Échec de la copie vers le presse-papier. Copiez vous-même.'
            },
            it: {
                ButtonTitle: 'Copia negli appunti',
            },
            pl: {
                ButtonTitle: 'Skopiuj do schowka',
                Success: 'Pomyślnie skopiowano do schowka.',
                Failure: 'Nie udało się skopiować do schowka. Zrób to sam.'
            },
            'pt-br': {
                Success: 'Copiado para à Área de transferência com sucesso.',
                Failure: 'Falha ao copiar para à Área de transferência.'
            },
            ru: {
                ButtonTitle: 'Копировать в Буфер',
                Success: 'Успешно скопировано в буфер обмена.',
                Failure: 'Ошибка копирования в буфер обмена. Пожалуйста, сделайте это самостоятельно.'
            }
        });
        function selectElementText(element) {
            var range, selection;    
            if (document.body.createTextRange) {
                range = document.body.createTextRange();
                range.moveToElementText(element);
                range.select();
            } else if (window.getSelection) {
                selection = window.getSelection();        
                range = document.createRange();
                range.selectNodeContents(element);
                selection.removeAllRanges();
                selection.addRange(range);
            }
        }
        $('.copy-clipboard').each(function () {
            var $this = $(this);
            var $button = $('<button title="'+I18n('ButtonTitle')+'"></button>');
            $this.append($button);
            $button.click(function () {
                var $content = $this.find('.copy-content');
                $content.children().remove();
                selectElementText($content[0]);
            
                try {
                    if (!document.execCommand('copy'))
                        throw 42;
                    mw.notify(I18n('Success'));
                } catch (err) {
                    mw.notify(I18n('Failure'), {type:'error'});
                }
            });
        });
    } )();
    // #endregion

    // #region Redirect to language version if url contains querystring iwredirect (for Dododex)
    var match = location.search.match(/iwredirect=([^;&]*)/);
    if (match && match[1]) {
        var $langlink = $('.interlanguage-link-target[hreflang="' + encodeURIComponent(match[1]) + '"]');
        if ($langlink && $langlink[0] && $langlink[0].href) {
            window.location.replace($langlink[0].href);
        }
    }
    // #endregion

    // #region Load our other scripts conditionally
    arkConditionalModules.forEach( function ( req ) {
        if ( ( req.cond == null || req.cond )
            && document.querySelectorAll( typeof( req.sel ) === 'string' ? req.sel : req.sel.join( ', ' ) ).length > 0 ) {
            arkImportArticles( req.pages );
        }
    } );
    // #endregion

    // #region Sticky table headers
    ( function () {
        var STICKY_THEAD_CLASS = 'ark-sticky-thead',
            MIN_ROWS_FOR_STICKY = 6,
            bodyElement = document.getElementById( 'bodyContent' );
        var lastStickyThead = null,
            tables = null;


        var
            updateStickyTheads = mw.util.debounce(
                function () {
                    if ( lastStickyThead !== null ) {
                        lastStickyThead.classList.remove( STICKY_THEAD_CLASS );
                    }

                    tables.some( function ( info ) {
                        var table = info.table,
                            thead = info.thead;
                        var bounds = table.getBoundingClientRect(),
                            tableBottom = bounds.top + bounds.height;
                        if ( bounds.top <= 0 && tableBottom >= 0 ) {
                            var theadBounds = thead.getBoundingClientRect();
                            if ( tableBottom - theadBounds.height * 3 >= 0 ) {
                                thead.style.setProperty( '--table-header-offset', ''.concat( 0 - theadBounds.top - 1, 'px' ) );
                                thead.classList.add( STICKY_THEAD_CLASS );
                                lastStickyThead = thead;
                                return true;
                            }
                        }
                    } );
                },
                5
            ),
            setupStickyTheads = function ( tablesToCheck ) {
                if ( tablesToCheck == null ) {
                    return;
                }

                tables = [];
                tablesToCheck.forEach( function ( table ) {
                    if ( table.rows.length < MIN_ROWS_FOR_STICKY ) {
                        return;
                    }

                    if ( table.tHead ) {
                        tables.push( {
                            table: table,
                            thead: table.tHead
                        } );
                    } else {
                        var firstRow = table.rows[ 0 ];
                        if ( firstRow && firstRow.querySelectorAll( ':scope > th' ).length === firstRow.children.length ) {
                            tables.push( {
                                table: table,
                                thead: firstRow
                            } );
                        }
                    }
                } );

                if ( tables.length > 0 ) {
                    window.addEventListener( 'scroll', updateStickyTheads, {
                        passive: true
                    } );
                    window.addEventListener( 'resize', updateStickyTheads, {
                        passive: true
                    } );
                    updateStickyTheads();
                }
            };

        setupStickyTheads( bodyElement.querySelectorAll( 'table.wikitable' ) );
    } )();
    // #endregion

    // #region Arkitecture - collapsible sections
    document.querySelectorAll( '[data-arkitecture-collapsible]' ).forEach( function ( sectionElement ) {
        var captionElement = sectionElement.children[ 0 ];
        sectionElement.classList.add( 'arkitect-is-collapsible' );
        captionElement.addEventListener( 'click', function () {
            sectionElement.classList.toggle( 'arkitect-is-collapsed' );
        } );
    } );
    // #endregion

    // #region Translation advertising banners
    if ( arkIsEnglishWiki && !mw.config.get( 'wgIsMainPage' ) ) {
        var prefLanguage = ( navigator.languages ? navigator.languages[0] : ( navigator.language || navigator.userLanguage ) )
            .toLowerCase().substr( 0, 2 );
        var bannerText = ( {
                // Currently only French wiki is enroled due to size and to start the experiment small
                fr: 'Vous pouvez aussi lire cet article en <b>Français</b>'
            } )[prefLanguage],
            link = $( '#p-lang > .vector-menu-content > ul > li.interlanguage-link > a[hreflang='+prefLanguage+']' )
                .attr( 'href' ),
            dismissCount = localStorage.getItem( 'translationBannerDismissals' ) || 0,
            $banner;
        if ( bannerText && link && dismissCount < 2 ) {
            $banner = $( '<div class="translation-banner">' )
                .attr( 'lang', prefLanguage )
                .append( $( '<a>' )
                    .attr( 'href', link )
                    .html( bannerText ) )
                .append( $( '<a href="#" class="translation-banner-dismiss">[dismiss]</a>' )
                    .on( 'click', function ( event ) {
                        event.preventDefault();
                        localStorage.setItem( 'translationBannerDismissals', dismissCount + 1 );
                        $banner.remove();
                    } ) )
                .appendTo( 'body' );
        }
    }
    // #endregion
    // #region Section heading jump links
    ( function () {
	    document.querySelectorAll( 'span.mw-headline[ id ]' ).forEach( function ( headingEl ) {
	        var anchorEl = document.createElement( 'a' );
	        anchorEl.href = '#' + mw.util.escapeIdForLink( headingEl.id );
	        anchorEl.title = 'Get a link to this section';
	        anchorEl.className = 'section-link';
	        headingEl.after( anchorEl );
	    } );
	} )();
	// #endregion
});
/* End DOM ready */


// Signal to other modules that English site module has been loaded
mw.loader.state( { 'en:site': 'ready' } );
