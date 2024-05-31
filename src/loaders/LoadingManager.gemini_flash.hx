class LoadingManager {

	public var isLoading:Bool = false;
	public var itemsLoaded:Int = 0;
	public var itemsTotal:Int = 0;
	public var urlModifier:Dynamic = null;
	public var handlers:Array<Dynamic> = [];

	public var onStart:Dynamic;
	public var onLoad:Dynamic;
	public var onProgress:Dynamic;
	public var onError:Dynamic;

	public function new(onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		this.onLoad = onLoad;
		this.onProgress = onProgress;
		this.onError = onError;
	}

	public function itemStart(url:String) {
		itemsTotal++;
		if (!isLoading && onStart != null) {
			onStart(url, itemsLoaded, itemsTotal);
		}
		isLoading = true;
	}

	public function itemEnd(url:String) {
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

	public function itemError(url:String) {
		if (onError != null) {
			onError(url);
		}
	}

	public function resolveURL(url:String):String {
		if (urlModifier != null) {
			return urlModifier(url);
		}
		return url;
	}

	public function setURLModifier(transform:Dynamic):LoadingManager {
		urlModifier = transform;
		return this;
	}

	public function addHandler(regex:Dynamic, loader:Dynamic):LoadingManager {
		handlers.push(regex);
		handlers.push(loader);
		return this;
	}

	public function removeHandler(regex:Dynamic):LoadingManager {
		var index = handlers.indexOf(regex);
		if (index != -1) {
			handlers.splice(index, 2);
		}
		return this;
	}

	public function getHandler(file:String):Dynamic {
		for (i in 0...handlers.length) {
			if (i % 2 == 0) {
				var regex = handlers[i];
				var loader = handlers[i + 1];
				if (regex.global) regex.lastIndex = 0;
				if (regex.test(file)) {
					return loader;
				}
			}
		}
		return null;
	}
}

var DefaultLoadingManager = new LoadingManager();