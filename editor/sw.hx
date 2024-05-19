package three.js.editor;

import js.html.ServiceWorkerGlobalScope;
import js.html.Cache;
import js.html.Request;
import js.html.Response;
import js.html.Headers;
import js.Promise;
import js.lib.Error;

class SW {
    static var cacheName:String = 'threejs-editor';
    static var assets:Array<String> = [
        './',
        './manifest.json',
        './images/icon.png',
        '../files/favicon.ico',
        '../build/three.module.js',
        '../examples/jsm/controls/TransformControls.js',
        // ... (rest of the assets)
        './examples/shaders.app.json'
    ];

    static function main() {
        var scope:ServiceWorkerGlobalScope = untyped __js__("self");
        scope.addEventListener('install', function(event) {
            event.waitUntil(cacheAssets());
        });

        scope.addEventListener('fetch', function(event) {
            event.respondWith(networkFirst(event.request));
        });
    }

    static function cacheAssets() {
        var cache:Cache = untyped __js__("caches").open(cacheName);
        var promises:Array<Promise<Void>> = [];
        for (asset in assets) {
            promises.push(cache.add(asset).catch(function(error:Error) {
                console.warn('[SW] Could\'t cache:', asset);
            }));
        }
        return Promise.all(promises);
    }

    static function networkFirst(request:Request) {
        return fetch(request).then(function(response:Response) {
            if (request.url.endsWith('editor/') || request.url.endsWith('editor/index.html')) {
                var newHeaders:Headers = new Headers(response.headers);
                newHeaders.set('Cross-Origin-Embedder-Policy', 'require-corp');
                newHeaders.set('Cross-Origin-Opener-Policy', 'same-origin');
                response = new Response(response.body, {status: response.status, statusText: response.statusText, headers: newHeaders});
            }
            if (request.method == 'GET') {
                var cache:Cache = untyped __js__("caches").open(cacheName);
                cache.put(request, response.clone());
            }
            return response;
        }).catch(function(error:Error) {
            var cachedResponse:Response = caches.match(request);
            if (cachedResponse == null) {
                console.warn('[SW] Not cached:', request.url);
            }
            return cachedResponse;
        });
    }
}