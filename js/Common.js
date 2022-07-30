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
function getArticleAsModule(pageName) {
    if (!pageName.startsWith('en:')) {
        return pageName;
    }
    return arkIsEnglishWiki ? (pageName.slice(3)) : ('u:'+pageName);
}
window.arkImportArticles = function(articles) {
    // Race warning: the ImportArticles extension script might be loaded after our script. Require it before executing the call.
    mw.loader.using(['ext.importarticles'], function() {
        importArticles({ type: 'script', articles: articles.map(getArticleAsModule) });
    });
}
window.arkUsingArticles = function(articles, callback) {
    return mw.loader.using(articles.map(getArticleAsModule), callback);
}
// #endregion


// #region Conditionally loaded modules
// Extracted into global scope, so translation wikis or gadgets can insert their own if needed in future.
window.arkConditionalModules = (window.arkConditionalModules||[]).concat([
    // [[Template:LoadPage]]
    [ '.load-page', [ 'en:MediaWiki:LoadPage.js' ] ],
    // Countdown timers
    [ '.countdown', [ 'en:MediaWiki:Countdown.js' ] ],
    // Cooking calculator
    [ '#cookingCalc', [ 'MediaWiki:Cooking calculator.js' ] ],
    // ARK Code calculator
    [ '.ARKCode-container', [ 'MediaWiki:ARKCode.js' ] ],
    // Creature article scripts
    [ '.cloningcalc, .killxpcalc', [
        // Kill XP calculator
        'en:MediaWiki:KillXP.js',
        // Experimental cloning calculator
        'en:MediaWiki:CloningCalculator.js' 
    ] ],
    // [[Template:Nav creatures]] grid filtering
    [ '#creature-grid', [ 'MediaWiki:CreatureGridFiltering.js' ] ],
    // Common Data page fetch function if a wild stats calculator, spawn map or an interactive region map are present.
    // Separate request for cache efficiency (load once, not every time for a combination).
    [ '#wildStatCalc, .data-map-container[data-spawn-data-page-name], .interactive-regionmap, .datamap-container-content', [ 'en:MediaWiki:DataFetch.js' ] ],
    // Wild creature stats calculator
    [ '#wildStatCalc', [ 'MediaWiki:WildCreatureStats.js' ] ],
    // Interactive region map
    [ '.interactive-regionmap', [ 'en:MediaWiki:RegionMaps.js' ] ],
    // Data map scripts
    [ '.data-map-container', [ 'en:MediaWiki:ResourceMaps.js', 'en:MediaWiki:SpawnMaps.js' ] ],
    [ '.datamap-container-content', [ 'en:MediaWiki:CreatureSpawnDataMaps.js' ] ],
]);
// #endregion


// #region Theme toggle (with tweaks contributed from the UnderMine wiki at https://undermine.wiki.gg)
(function(window) {
	var currentTheme = null, defaultTheme = 'dark', altTheme = 'light', storageKey = 'skin-theme';
    var I18n = arkCreateI18nInterface('ThemeToggle', {
        en: { Label: 'Click to toggle the theme' }
    });
	
	// add/remove class from body element
	function setThemeClass(name) {
		if (currentTheme) {
			document.documentElement.classList.remove('theme-' + currentTheme);
		}
		currentTheme = name;
		document.documentElement.classList.add('theme-' + currentTheme);
	}
	setThemeClass(localStorage.getItem(storageKey) || (window.matchMedia && window.matchMedia('(prefers-color-scheme: light)').matches && altTheme || defaultTheme));
	
	// create button
	$(function () {
		var $toggle = $('<li id="p-themes" class="mw-list-item">');
		var $toggleChild = $('<input type="checkbox" id="theme-switcher">')
			.attr('title', I18n('Label'))
			.prop('checked', currentTheme != defaultTheme)
			.on('change', function () {
				var newTheme = this.checked ? altTheme : defaultTheme;
				setThemeClass(newTheme);
				localStorage.setItem(storageKey, newTheme);
			});
	
		// add button
		$toggle.append($toggleChild);
		$('#p-personal > .body > ul').prepend($toggle);
	});
	
	// Toggle theme after system theme change
	window
		.matchMedia('(prefers-color-scheme: dark)')
		.addEventListener('change', function (e) {
			var colorScheme = e.matches ? 'dark' : 'light';
			setThemeClass(colorScheme);
			localStorage.setItem(storageKey, colorScheme);
		});
})(window);
// #endregion


// #region Disable animations for #mw-head collapsing
mw.loader.using('skins.vector.legacy.js', function() {
    var realFn = $.collapsibleTabs.handleResize;
    $.collapsibleTabs.handleResize = function () {
        realFn();
        $('#mw-head .mw-portlet .collapsible').finish();
    };
});
// #endregion


// #region Push is-steam-overlay class onto root node for Steam's overlay browsers due to a layout bug in Chrome 84
if ( navigator.userAgent.indexOf( 'Valve Steam' ) > -1 ) {
    document.documentElement.classList.add( 'is-steam-overlay' );
}
// #endregion


/* Fires when DOM is ready */
$(function(){
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

    // #region Interwiki dropdown
    {
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
            var $sidebarInterwikis = $('#p-lang > .body > ul > li.interlanguage-link');
            if ($sidebarInterwikis.length > 0) {
                var $menu = $('<ul class="vector-menu-content-list menu">');
                $('<div id="p-lang-btn" class="mw-portlet mw-portlet-lang vectorMenu vector-menu vector-menu-dropdown" aria-labelledby="p-lang-btn-label" role="navigation">')
                    .insertBefore($('#firstHeading'))
                    .append($('<input type="checkbox" id="p-lang-btn-checkbox" role="button" class="mw-interlanguage-selector vectorMenuCheckbox vector-menu-checkbox"/>'))
                    .append($('<label id="p-lang-btn-label" class="vector-menu-heading mw-ui-button mw-ui-quiet mw-ui-progressive" aria-hidden="true">')
                             .text(($sidebarInterwikis.length+1) + I18n('Label')))
                    .append($('<div class="vector-menu-content body">').append($menu));
                $sidebarInterwikis.each(function() {
                    $menu.append($(this).clone());
                });
            }
        }
    }
    // #endregion

    // #region Copy to clipboard
    {
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
            var $button = $('<button title="'+I18n('ButtonTitle')+'">&#xf0ea;</button>');
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
    }
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
    arkConditionalModules.forEach(function (req) {
        if (document.querySelectorAll(req[0]).length > 0) {
            arkImportArticles(req[1])
        }
    });
    // #endregion

    // #region Element animator - cycles through a set of elements on a timer (modified from minecraft.gamepedia.com)
    // Add the "animated" class to the frame containing the elements to animate.
    // Optionally, add the "animated-active" class to the frame to display first.
    // Optionally, add the "animated-subframe" class to a frame, and the
    // "animated-active" class to a subframe within, in order to designate a set of
    // subframes which will only be cycled every time the parent frame is displayed.
    // Animations with the "animated-paused" class will be skipped each interval.
    (function() {
        var $content = $( '#mw-content-text' );
        var advanceFrame = function(parentElem, parentSelector) {
          var curFrame = parentElem.querySelector(parentSelector + ' > .animated-active');
          $(curFrame).removeClass('animated-active');
          var $nextFrame = $(curFrame && curFrame.nextElementSibling || parentElem.firstElementChild);
          return $nextFrame.addClass('animated-active');
        };

        // Set the name of the hidden property
        var hidden; 
        if (typeof document.hidden !== 'undefined') {
          hidden = 'hidden';
        } else if (typeof document.msHidden !== 'undefined') {
          hidden = 'msHidden';
        } else if (typeof document.webkitHidden !== 'undefined') {
          hidden = 'webkitHidden';
        }

        setInterval(function() {
            if (hidden && document[hidden]) {
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
    }());
    /**
     * Pause animations on mouseover of a designated container (.animated-container)
     *
     * This is so people have a chance to look at the image and click on pages they want to view.
     */
    $('#mw-content-text').on('mouseenter mouseleave', '.animated-container', function (e) {
        $(this).find('.animated').toggleClass('animated-paused', e.type === 'mouseenter');
    });
    // #endregion

});
/* End DOM ready */
