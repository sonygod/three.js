package;

import js.Browser.Blob;
import js.Browser.Fetch;
import js.Browser.ImageBitmap;
import js.Browser.Window;

import openfl.display.BitmapData;
import openfl.display.Loader;
import openfl.display.LoaderInfo;
import openfl.events.Event;
import openfl.events.HTTPStatusEvent;
import openfl.events.IOErrorEvent;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;

class ImageBitmapLoader extends Loader {

	public var isImageBitmapLoader:Bool;
	private var _createImageBitmap:Dynamic;
	private var _fetch:Dynamic;
	private var _options:Dynamic;

	public function new(manager:Dynamic) {
		super(manager);
		isImageBitmapLoader = true;
		_createImageBitmap = Window.prototype.createImageBitmap;
		_fetch = Window.prototype.fetch;
		if (_createImageBitmap == null) {
			trace('THREE.ImageBitmapLoader: createImageBitmap() not supported.');
		}
		if (_fetch == null) {
			trace('THREE.ImageBitmapLoader: fetch() not supported.');
		}
		_options = { premultiplyAlpha: 'none' };
	}

	public function setOptions(options:Dynamic):Dynamic {
		_options = options;
		return this;
	}

	override public function load(url:String, onLoad:Dynamic = null, onProgress:Dynamic = null, onError:Dynamic = null):Void {
		if (url == null) url = '';
		if (path != null) url = path.toString() + url;
		url = manager.resolveURL(url);
		var scope = this;
		var cached = Cache.get(url);
		if (cached != null) {
			manager.itemStart(url);
			if (Type.enumIndex(cached, Dynamic)) {
				cached.then(function (imageBitmap:ImageBitmap) {
					if (onLoad != null) onLoad(imageBitmap);
					manager.itemEnd(url);
				}).onError(function (e:Dynamic) {
					if (onError != null) onError(e);
				});
				return;
			}
			Dynamic.setTimeout(function () {
				if (onLoad != null) onLoad(cached);
				manager.itemEnd(url);
			}, 0);
			return cached;
		}
		var fetchOptions:Dynamic = {
			credentials: (crossOrigin == 'anonymous') ? 'same-origin' : 'include',
			headers: requestHeader
		};
		var promise:Dynamic = _fetch(url, fetchOptions).then(function (res:Dynamic) {
			return res.blob();
		}).then(function (blob:Blob) {
			return _createImageBitmap(blob, { colorSpaceConversion: 'none', premultiplyAlpha: _options.premultiplyAlpha });
		}).then(function (imageBitmap:ImageBitmap) {
			Cache.add(url, imageBitmap);
			if (onLoad != null) onLoad(imageBitmap);
			manager.itemEnd(url);
			return imageBitmap;
		}).onError(function (e:Dynamic) {
			if (onError != null) onError(e);
			Cache.remove(url);
			manager.itemError(url);
			manager.itemEnd(url);
		});
		Cache.add(url, promise);
		manager.itemStart(url);
	}

}

class Cache {

	public static function get(key:String):Dynamic {
		if (cache.exists(key)) {
			return cache.get(key);
		}
		return null;
	}

	public static function add(key:String, obj:Dynamic):Void {
		cache.set(key, obj);
	}

	public static function remove(key:String):Void {
		cache.remove(key);
	}

	private static var cache:Dynamic = new haxe.ds.StringMap();

}

class LoaderInfo {

	public static function getLoaderInfoByURL(url:String):Dynamic {
		var request:URLRequest = new URLRequest(url);
		return getLoaderInfoByRequest(request);
	}

	public static function getLoaderInfoByRequest(request:URLRequest):Dynamic {
		var l:Dynamic = null;
		var loaders:Array<URLLoader> = URLLoader.activeLoaders;
		var i:Int;
		for (i = 0; i < loaders.length; i++) {
			var loader:URLLoader = loaders[i];
			if (loader.request.url == request.url) {
				l = loader;
				break;
			}
		}
		return l;
	}

}

class Event {

	public static function dispatchEvent(target:Dynamic, type:String, bubbles:Bool = false, cancelable:Bool = false):Bool {
		var event:Dynamic = null;
		if (openfl_Events_Event_$eventType_$Impl_){
			event = openfl_Events_Event_$eventType_$Impl_.fromString(type);
		}
		if (event == null) {
			event = new openfl.events.Event(type, bubbles, cancelable);
		}
		if (bubbles) {
			var currentTarget:Dynamic = target;
			while (currentTarget != null) {
				event.target = currentTarget;
				currentTarget.dispatchEvent(event);
				if (event.isDefaultPrevented()) {
					break;
				}
				currentTarget = currentTarget.parent;
			}
		} else {
			event.target = target;
			target.dispatchEvent(event);
		}
		return !event.isDefaultPrevented();
	}

}

class HTTPStatusEvent {

	public static var HTTP_STATUS:String = 'httpStatus';

	public static function dispatchHTTPStatusEvent(target:Dynamic, url:String, status:Int):Bool {
		var event:HTTPStatusEvent = new HTTPStatusEvent(HTTP_STATUS, true, false);
		event.url = url;
		event.status = status;
		return Event.dispatchEvent(target, event);
	}

}

class IOErrorEvent {

	public static var IO_ERROR:String = 'ioError';

	public static function dispatchIOErrorEvent(target:Dynamic, url:String):Bool {
		var event:IOErrorEvent = new IOErrorEvent(IO_ERROR, true, false);
		event.text = url;
		return Event.dispatchEvent(target, event);
	}

}

class ProgressEvent {

	public static var PROGRESS:String = 'progress';

	public static function dispatchProgressEvent(target:Dynamic, bytesLoaded:Int, bytesTotal:Int):Bool {
		var event:ProgressEvent = new ProgressEvent(PROGRESS, false, false);
		event.bytesLoaded = bytesLoaded;
		event.bytesTotal = bytesTotal;
		return Event.dispatchEvent(target, event);
	}

}

class ByteArray {

	public static function fromFile(path:String):ByteArray {
		var bytes:ByteArray = new ByteArray();
		bytes.loadFromFile(path);
		return bytes;
	}

}

class BitmapData {

	public static function loadFromBytes(bytes:ByteArray, useCache:Bool = true):BitmapData {
		var bd:BitmapData = new BitmapData(bytes.length, bytes.length, false, 0x00FFFFFF);
		bd.loadBytes(bytes, useCache);
		return bd;
	}

}