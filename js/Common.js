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
    // Legacy [[Template:Nav creatures]] grid filtering
    { sel: '#creature-grid',
      pages: [ 'MediaWiki:CreatureGridFiltering.js' ] },
    // [[Template:Nav creatures]] grid filtering
    { sel: '.creature-roster',
      pages: [ 'MediaWiki:NavboxGrid.js' ] },
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


// #region Push is-steam-overlay class onto root node for Steam's overlay browsers due to a layout bug in Chrome 84
if ( navigator.userAgent.indexOf( 'Valve Steam' ) > -1
    && window.location.search.substr( 1 ).split( '&' ).indexOf( 'steambrowserhack=0' ) < 0 ) {
    document.documentElement.classList.add( 'is-steam-overlay' );
}
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
            $el.addClass('collapsed').find('.body').slideUp(0);
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
            $el.find('.body').slideUp('fast');
            localStorage.setItem('sidebar_c_'+$id, "y");
        }
        else{
            $el.find('.body').slideDown('fast');
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
                Text_XboxPartnerEvent: '<a href="https://xbx.lv/3QbFHia" class="external" target="_blank">Tune into the Xbox Partner Preview on October 25th, at 17:00 UTC (10am Pacific / 1pm Eastern / Oct 26th, 4am AEDT) to witness the first gameplay preview of ARK: Survival Ascended.</a>',
                Text_ASAUpdateRelease: 'Articles will be brought up to date with ARK: Survival Ascended over the following weeks.',
            }
        } );

        // PROCEDURES:
        // - IF ASA LAUNCHES DURING EVENT: bump wgSiteNoticeId, swap text key to Text_ASAUpdateRelease
        // - IF ASA DOESN'T LAUNCH AND EVENT ENDS: comment out the notice, switch to Text_ASAUpdateRelease for future

	    mw.config.values.wgSiteNoticeId = 4;
    	mw.loader.using( [ 'ext.dismissableSiteNotice.styles' ] );
    	var snContent = I18n( 'Text_XboxPartnerEvent' );
    	$( '#siteNotice' ).html( '<div id="localNotice" dir="ltr" lang="en"><p style="font-size: 110%">'+snContent+'</p></div>' + $( '#siteNotice' ).html() );
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

    // #region Arkitecture - collapsible sections
    document.querySelectorAll( '[data-arkitecture-collapsible]' ).forEach( function ( sectionElement ) {
        var captionElement = sectionElement.children[ 0 ];
        sectionElement.classList.add( 'arkitect-is-collapsible' );
        captionElement.addEventListener( 'click', function () {
            sectionElement.classList.toggle( 'arkitect-is-collapsed' );
        } );
    } );
    // #endregion

    // #region Element animator - cycles through a set of elements on a timer (modified from minecraft.gamepedia.com)
    // Add the "animated" class to the frame containing the elements to animate.
    // Optionally, add the "animated-active" class to the frame to display first.
    // Optionally, add the "animated-subframe" class to a frame, and the
    // "animated-active" class to a subframe within, in order to designate a set of
    // subframes which will only be cycled every time the parent frame is displayed.
    // Animations with the "animated-paused" class will be skipped each interval.
    ( function() {
        var $content = $( '#mw-content-text' );
        var advanceFrame = function(parentElem, parentSelector) {
          var curFrame = parentElem.querySelector(parentSelector + ' > .animated-active');
          $(curFrame).removeClass('animated-active');
          var $nextFrame = $(curFrame && curFrame.nextElementSibling || parentElem.firstElementChild);
          return $nextFrame.addClass('animated-active');
        };

        setInterval(function() {
            if (document.hidden) {
                return;
            }
            $content.find('.animated').each(function() {
                if ($(this).hasClass('animated-paused')) {
                    return;
                }

                var $nextFrame = advanceFrame(this, '.animated');
                if ($nextFrame.hasClass('animated-subframe')) {
                    advanceFrame($nextFrame[0], '.animated-subframe');
                }
            });
        }, 5000);
    } )();
    /**
     * Pause animations on mouseover of a designated container (.animated-container)
     *
     * This is so people have a chance to look at the image and click on pages they want to view.
     */
    $('#mw-content-text').on('mouseenter mouseleave', '.animated-container', function (e) {
        $(this).find('.animated').toggleClass('animated-paused', e.type === 'mouseenter');
    });
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
    // #region add a link button to headings
    $( function () {
	    document.querySelectorAll( 'span.mw-headline[ id ]' ).forEach( function ( headingEl ) {
	        var anchorEl = document.createElement( 'a' );
	        anchorEl.href = '#' + mw.util.escapeIdForLink( headingEl.id );
	        anchorEl.title = 'Get a link to this section';
	        anchorEl.className = 'section-link';
	        headingEl.parentElement.appendChild( anchorEl );
	    } );
	} );
	// #endregion heading link button
});
/* End DOM ready */


// Signal to other modules that English site module has been loaded
mw.loader.state( { 'en:site': 'ready' } );
