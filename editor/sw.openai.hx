package three.js.editor;

import js.html.Cache;
import js.html.CacheStorage;
import js.html.FetchEvent;
import js.html.Request;
import js.html.Response;

class SW {
    static var cacheName:String = 'threejs-editor';

    static var assets:Array<String> = [
        './',
        './manifest.json',
        './images/icon.png',
        // ... (all the other assets)
        './examples/shaders.app.json'
    ];

    static function install(event:js.html.InstallEvent) {
        CacheStorage.open(cacheName).then(function(cache) {
            for (asset in assets) {
                try {
                    cache.add(asset);
                } catch (e:Dynamic) {
                    console.warn('[SW] Couldn\'t cache:', asset);
                }
            }
        });
    }

    static function fetch(event:js.html.FetchEvent) {
        var request:Request = event.request;
        if (request.url.startsWith('chrome-extension')) return;
        event.respondWith(networkFirst(request));
    }

    static async function networkFirst(request:Request):Promise<Response> {
        try {
            var response:Response = await fetch(request);
            if (request.url.endsWith('editor/') || request.url.endsWith('editor/index.html')) {
                var newHeaders:Headers = new Headers(response.headers);
                newHeaders.set('Cross-Origin-Embedder-Policy', 'require-corp');
                newHeaders.set('Cross-Origin-Opener-Policy', 'same-origin');
                response = new Response(response.body, { status: response.status, statusText: response.statusText, headers: newHeaders });
            }
            if (request.method == 'GET') {
                var cache:Cache = await CacheStorage.open(cacheName);
                cache.put(request, response.clone());
            }
            return response;
        } catch (e:Dynamic) {
            var cachedResponse:Response = await CacheStorage.open(cacheName).match(request);
            if (cachedResponse == null) {
                console.warn('[SW] Not cached:', request.url);
            }
            return cachedResponse;
        }
    }
}