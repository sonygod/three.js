class LoadingManager {

	public var onLoad:Dynamic->Void;
	public var onProgress:Dynamic->Int->Int->Void;
	public var onError:Dynamic->Void;
	public var onStart:Dynamic->Int->Int->Void;

	private var isLoading:Bool = false;
	private var itemsLoaded:Int = 0;
	private var itemsTotal:Int = 0;
	private var urlModifier:Dynamic = null;
	private var handlers:Array<Dynamic> = [];

	public function new(onLoad:Dynamic->Void, onProgress:Dynamic->Int->Int->Void, onError:Dynamic->Void) {
		this.onLoad = onLoad;
		this.onProgress = onProgress;
		this.onError = onError;
	}

	public function itemStart(url:Dynamic) {
		itemsTotal++;

		if (!isLoading && onStart != null) {
			onStart(url, itemsLoaded, itemsTotal);
		}

		isLoading = true;
	}

	public function itemEnd(url:Dynamic) {
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

	public function itemError(url:Dynamic) {
		if (onError != null) {
			onError(url);
		}
	}

	public function resolveURL(url:Dynamic):Dynamic {
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

	public function getHandler(file:Dynamic):Dynamic {
		for (i in 0...handlers.length) {
			if (i % 2 == 0) {
				var regex = handlers[i];
				var loader = handlers[i + 1];
				if (regex.global) {
					regex.lastIndex = 0;
				}
				if (regex.test(file)) {
					return loader;
				}
			}
		}
		return null;
	}

}

var DefaultLoadingManager = new LoadingManager(null, null, null);

class LoadingManager {
	public static var Default:LoadingManager = DefaultLoadingManager;
}