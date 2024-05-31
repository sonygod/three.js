class LoaderUtils {

	public static function decodeText(array:Array<Int>):String {
		// @deprecated, r165
		haxe.Log.trace('THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.');

		#if js
		if (untyped __js__('typeof TextDecoder !== "undefined"')) {
			return untyped __js__('new TextDecoder().decode({0})', array);
		}
		#end

		var s:String = '';
		for (i in 0...array.length) {
			s += String.fromCharCode(array[i]);
		}

		try {
			return StringTools.urlDecode(s);
		} catch (e:Dynamic) {
			return s;
		}
	}

	public static function extractUrlBase(url:String):String {
		var index:Int = url.lastIndexOf('/');
		if (index == -1) return './';
		return url.substr(0, index + 1);
	}

	public static function resolveURL(url:String, path:String):String {
		// Invalid URL
		if (url == null || url == '') return '';

		// Host Relative URL
		var httpsRegExp:EReg = ~/^https?:\/\//i;
		var pathRegExp:EReg = ~/^\//;
		if (httpsRegExp.match(path) && pathRegExp.match(url)) {
			path = path.replace(~/(^https?:\/\/[^\/]+).*/i, '$1');
		}

		// Absolute URL http://, https://, //
		if (httpsRegExp.match(url)) return url;

		// Data URI
		if (~/^data:.*,.*$/i.match(url)) return url;

		// Blob URL
		if (~/^blob:.*$/i.match(url)) return url;

		// Relative URL
		return path + url;
	}

}