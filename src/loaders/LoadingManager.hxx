class LoadingManager {

	var onLoad:Dynamic;
	var onProgress:Dynamic;
	var onError:Dynamic;
	var onStart:Dynamic;
	var itemsLoaded:Int;
	var itemsTotal:Int;
	var isLoading:Bool;
	var urlModifier:Dynamic;
	var handlers:Array<Dynamic>;

	public function new(onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
		this.onLoad = onLoad;
		this.onProgress = onProgress;
		this.onError = onError;
		this.isLoading = false;
		this.itemsLoaded = 0;
		this.itemsTotal = 0;
		this.urlModifier = null;
		this.handlers = [];
		this.onStart = null;
	}

	public function itemStart(url:String):Void {
		this.itemsTotal++;
		if (!this.isLoading) {
			if (this.onStart != null) {
				this.onStart.call(url, this.itemsLoaded, this.itemsTotal);
			}
		}
		this.isLoading = true;
	}

	public function itemEnd(url:String):Void {
		this.itemsLoaded++;
		if (this.onProgress != null) {
			this.onProgress.call(url, this.itemsLoaded, this.itemsTotal);
		}
		if (this.itemsLoaded == this.itemsTotal) {
			this.isLoading = false;
			if (this.onLoad != null) {
				this.onLoad.call();
			}
		}
	}

	public function itemError(url:String):Void {
		if (this.onError != null) {
			this.onError.call(url);
		}
	}

	public function resolveURL(url:String):String {
		if (this.urlModifier != null) {
			return this.urlModifier.call(url);
		}
		return url;
	}

	public function setURLModifier(transform:Dynamic):LoadingManager {
		this.urlModifier = transform;
		return this;
	}

	public function addHandler(regex:EReg, loader:Dynamic):LoadingManager {
		this.handlers.push(regex, loader);
		return this;
	}

	public function removeHandler(regex:EReg):LoadingManager {
		var index = this.handlers.indexOf(regex);
		if (index != -1) {
			this.handlers.splice(index, 2);
		}
		return this;
	}

	public function getHandler(file:String):Dynamic {
		for (i in 0...this.handlers.length) {
			var regex = this.handlers[i];
			var loader = this.handlers[i + 1];
			if (regex.test(file)) {
				return loader;
			}
		}
		return null;
	}
}

@:remove
class DefaultLoadingManager extends LoadingManager {}