class LoadingManager {
	var isLoading:Bool;
	var itemsLoaded:Int;
	var itemsTotal:Int;
	var urlModifier:Null<Function>;
	var handlers:Array<Dynamic>;

	public function new(onLoad:Null<Function>, onProgress:Null<Function>, onError:Null<Function>) {
		isLoading = false;
		itemsLoaded = 0;
		itemsTotal = 0;
		urlModifier = null;
		handlers = [];

		onStart = onLoad;
		onLoad = onLoad;
		onProgress = onProgress;
		onError = onError;

		function $itemStart(url:String) {
			itemsTotal++;

			if (!isLoading) {
				if (onStart != null) {
					onStart(url, itemsLoaded, itemsTotal);
				}
			}

			isLoading = true;
		}

		function $itemEnd(url:String) {
			itemsLoaded++;

			if (onProgress != null) {
				onProgress(url, itemsLoaded, itemsTotal);
			}

			if (itemsLoaded == itemsTotal) {
				isLoading = false;

				if (onLoad != null) {
					onLoad();
				}
			}
		}

		function $itemError(url:String) {
			if (onError != null) {
				onError(url);
			}
		}

		function $resolveURL(url:String):String {
			if (urlModifier != null) {
				return urlModifier(url);
			}
			return url;
		}

		function $setURLModifier(transform:Function) {
			urlModifier = transform;
			return this;
		}

		function $addHandler(regex:EReg, loader:Dynamic) {
			handlers.push(regex, loader);
			return this;
		}

		function $removeHandler(regex:EReg) {
			var index = handlers.indexOf(regex);
			if (index != -1) {
				handlers.splice(index, 2);
			}
			return this;
		}

		function $getHandler(file:String):Dynamic {
			for (i in 0...handlers.length) {
				var regex = handlers[i];
				var loader = handlers[i + 1];

				if (regex.global) {
					regex.index = 0;
				}

				if (regex.match(file)) {
					return loader;
				}
			}
			return null;
		}
	}
}

static var DefaultLoadingManager:LoadingManager = new LoadingManager(null, null, null);