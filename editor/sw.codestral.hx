var cacheName = 'threejs-editor';

var assets:Array<String> = [
	'./',
	'./manifest.json',
	'./images/icon.png',

	// ... rest of the assets ...

	'./examples/shaders.app.json'
];

// Haxe does not support service workers directly, so the following code is just a simple representation.
class Main {
	public function new() {
		// Install event
		ServiceWorkerGlobalScope.addEventListener('install', function(event:Event) {
			var request = event.request;
			if (request.url.startsWith("chrome-extension")) return;

			event.respondWith(networkFirst(request));
		});

		// Fetch event
		ServiceWorkerGlobalScope.addEventListener('fetch', function(event:Event) {
			var request = event.request;
			if (request.url.startsWith("chrome-extension")) return;

			event.respondWith(networkFirst(request));
		});
	}

	private async function networkFirst(request:Request):Promise<Response> {
		try {
			var response = await fetch(request);

			// ... rest of the code ...

			return response;
		} catch(_) {
			var cachedResponse = await caches.match(request);

			if (cachedResponse == null) {
				trace('[SW] Not cached: ' + request.url);
			}

			return cachedResponse;
		}
	}
}