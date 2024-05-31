import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Eof;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.Path;
import haxe.xml.Xml;

import js.html.Image;
import js.html.Window;

import three.loaders.Cache;
import three.loaders.Loader;

class ImageLoader extends Loader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Image->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Image {
		if (this.path != null) url = this.path + url;
		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);
			Window.setTimeout(function() {
				if (onLoad != null) onLoad(cached);
				this.manager.itemEnd(url);
			}, 0);
			return cached;
		}

		var image = new Image();

		var onImageLoad = function() {
			removeEventListeners();
			Cache.add(url, image);
			if (onLoad != null) onLoad(image);
			this.manager.itemEnd(url);
		};

		var onImageError = function(event:Dynamic) {
			removeEventListeners();
			if (onError != null) onError(event);
			this.manager.itemError(url);
			this.manager.itemEnd(url);
		};

		var removeEventListeners = function() {
			image.removeEventListener('load', onImageLoad);
			image.removeEventListener('error', onImageError);
		};

		image.addEventListener('load', onImageLoad);
		image.addEventListener('error', onImageError);

		if (url.substring(0, 5) != "data:") {
			if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
		}

		this.manager.itemStart(url);
		image.src = url;

		return image;
	}

}

class ImageLoaderBytes extends ImageLoader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Bytes->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Bytes {
		if (this.path != null) url = this.path + url;
		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);
			Window.setTimeout(function() {
				if (onLoad != null) onLoad(cached);
				this.manager.itemEnd(url);
			}, 0);
			return cached;
		}

		var image = new Image();

		var onImageLoad = function() {
			removeEventListeners();
			var canvas = Window.document.createElement('canvas');
			var ctx = canvas.getContext('2d');
			ctx.drawImage(image, 0, 0);
			var data = ctx.getImageData(0, 0, canvas.width, canvas.height);
			var bytes = new Bytes(data.data.length);
			for (i in 0...data.data.length) {
				bytes.b[i] = data.data[i];
			}
			Cache.add(url, bytes);
			if (onLoad != null) onLoad(bytes);
			this.manager.itemEnd(url);
		};

		var onImageError = function(event:Dynamic) {
			removeEventListeners();
			if (onError != null) onError(event);
			this.manager.itemError(url);
			this.manager.itemEnd(url);
		};

		var removeEventListeners = function() {
			image.removeEventListener('load', onImageLoad);
			image.removeEventListener('error', onImageError);
		};

		image.addEventListener('load', onImageLoad);
		image.addEventListener('error', onImageError);

		if (url.substring(0, 5) != "data:") {
			if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
		}

		this.manager.itemStart(url);
		image.src = url;

		return null;
	}

}

class ImageLoaderXml extends ImageLoader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:Xml->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):Xml {
		if (this.path != null) url = this.path + url;
		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);
			Window.setTimeout(function() {
				if (onLoad != null) onLoad(cached);
				this.manager.itemEnd(url);
			}, 0);
			return cached;
		}

		var image = new Image();

		var onImageLoad = function() {
			removeEventListeners();
			var canvas = Window.document.createElement('canvas');
			var ctx = canvas.getContext('2d');
			ctx.drawImage(image, 0, 0);
			var data = ctx.getImageData(0, 0, canvas.width, canvas.height);
			var xml = Xml.parse(new BytesInput(new Bytes(data.data)));
			Cache.add(url, xml);
			if (onLoad != null) onLoad(xml);
			this.manager.itemEnd(url);
		};

		var onImageError = function(event:Dynamic) {
			removeEventListeners();
			if (onError != null) onError(event);
			this.manager.itemError(url);
			this.manager.itemEnd(url);
		};

		var removeEventListeners = function() {
			image.removeEventListener('load', onImageLoad);
			image.removeEventListener('error', onImageError);
		};

		image.addEventListener('load', onImageLoad);
		image.addEventListener('error', onImageError);

		if (url.substring(0, 5) != "data:") {
			if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
		}

		this.manager.itemStart(url);
		image.src = url;

		return null;
	}

}

class ImageLoaderString extends ImageLoader {

	public function new(manager:Loader) {
		super(manager);
	}

	public function load(url:String, onLoad:String->Void, onProgress:Dynamic->Void, onError:Dynamic->Void):String {
		if (this.path != null) url = this.path + url;
		url = this.manager.resolveURL(url);

		var cached = Cache.get(url);
		if (cached != null) {
			this.manager.itemStart(url);
			Window.setTimeout(function() {
				if (onLoad != null) onLoad(cached);
				this.manager.itemEnd(url);
			}, 0);
			return cached;
		}

		var image = new Image();

		var onImageLoad = function() {
			removeEventListeners();
			var canvas = Window.document.createElement('canvas');
			var ctx = canvas.getContext('2d');
			ctx.drawImage(image, 0, 0);
			var data = ctx.getImageData(0, 0, canvas.width, canvas.height);
			var bytes = new Bytes(data.data.length);
			for (i in 0...data.data.length) {
				bytes.b[i] = data.data[i];
			}
			var str = String.fromCharCode(bytes.b);
			Cache.add(url, str);
			if (onLoad != null) onLoad(str);
			this.manager.itemEnd(url);
		};

		var onImageError = function(event:Dynamic) {
			removeEventListeners();
			if (onError != null) onError(event);
			this.manager.itemError(url);
			this.manager.itemEnd(url);
		};

		var removeEventListeners = function() {
			image.removeEventListener('load', onImageLoad);
			image.removeEventListener('error', onImageError);
		};

		image.addEventListener('load', onImageLoad);
		image.addEventListener('error', onImageError);

		if (url.substring(0, 5) != "data:") {
			if (this.crossOrigin != null) image.crossOrigin = this.crossOrigin;
		}

		this.manager.itemStart(url);
		image.src = url;

		return null;
	}

}