(function() {
    
    var CACHE_NAME = 'ARKData';
    
    var shouldBypassCache = window.location.search.substr(1).split('&').indexOf('arkdata=no-cache') >= 0;

    // Internal implementation
    function fetchDataPagesInternal(pages, cache, forceRecacheId, expiryTime, skipRecacheId) {
        function fetchDataPageInternal(pageName) {
            // Construct a URL of the page.
            // On translations if prefixed with "en:", this'll slice off the script path.
            var isRequestingMain = pageName.startsWith('en:');
            var scriptPath = mw.config.get('wgScriptPath');
            var urlNoCb = mw.util.getUrl((isRequestingMain ? pageName.slice(3) : pageName), {
                action: 'raw',
                ctype: 'application/json'
            });
            // If cache should be bypassed via ?arkdata=no-cache, set the version on request to current
            // timestamp, so server serves us the latest blob.
            var url = urlNoCb + '&version=' + ( shouldBypassCache ? Date.now() : forceRecacheId );
            if (isRequestingMain && mw.config.get('wgContentLanguage') != 'en' && url.startsWith(scriptPath)) {
                url = url.slice(scriptPath.length);
            }
            
            // If cache should be bypassed (as requested via ?arkdata), null the reference to the cache
            // manager. This will force taking the short fetch() path.
            if (shouldBypassCache) {
                cache = null;
            }

            var request = new Request(url),
                cacheRequest = skipRecacheId ? new Request(urlNoCb) : request;

            if (cache != null) {
                // Cache is available
                var timeNow = new Date().getTime();
                return cache.match(cacheRequest).then(function (response) {
                    // Check if cache entry is recent and valid
                    if (response && response.ok
                        && (Date.parse(response.headers.get('Expires')) > timeNow)) {
                        return response;
                    }

                    // Fetch the page from API
                    return fetch(request).then(function (response) {
                        response.clone().blob().then(function(body) {
                            cache.put(cacheRequest, new Response(body, { headers: {
                                'Expires': (new Date(timeNow + expiryTime)).toUTCString(),
                            }}));
                        });
                        return response;
                    });
                }).then(function (response) {
                    return response.json().then(function(data) {
                        results[pageName] = data;
                    });
                });
            } else {
                // Cache is unavailable
                return fetch(request).then(function (response) {
                    return response.json().then(function(data) {
                        results[pageName] = data;
                    });
                });
            }
        }

        // Create a fetch request for every page, and wait for each to be resolved (or one to fail), then return the results
        // object.
        var results = {};
        return Promise.all(pages.map(function (page) {
            return fetchDataPageInternal(page);
        })).then(function () {
            return Promise.resolve(results);
        });
    }

    // Public entrypoint
    window.arkLoadDataPages = function(pages, forceRecacheId, expiryTime, skipRecacheId) {
        return caches.open(CACHE_NAME).then(function (cache) {
            // Cache successfully opened
            return fetchDataPagesInternal(pages, cache, forceRecacheId, expiryTime, skipRecacheId);
        }, function() {
            // Cache not opened. Most likely rejected by browser's privacy settings (e.g. Firefox's incognito mode).
            return fetchDataPagesInternal(pages, null, forceRecacheId, null, null);
        });
    };

})();
