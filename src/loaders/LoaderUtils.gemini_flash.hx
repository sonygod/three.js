class LoaderUtils {

	static function decodeText(array:Array<Int>):String {
		// @deprecated, r165
		Sys.warning("THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.");

		if (Type.typeof(TextDecoder) != Type.TNull) {
			return new TextDecoder().decode(array);
		}

		// Avoid the String.fromCharCode.apply(null, array) shortcut, which
		// throws a "maximum call stack size exceeded" error for large arrays.

		var s:String = "";

		for (i in 0...array.length) {
			// Implicitly assumes little-endian.
			s += String.fromCharCode(array[i]);
		}

		try {
			// merges multi-byte utf-8 characters.
			return decodeURIComponent(escape(s));
		} catch (e:Dynamic) { // see #16358
			return s;
		}
	}

	static function extractUrlBase(url:String):String {
		var index:Int = url.lastIndexOf("/");

		if (index == -1) return "./";

		return url.substring(0, index + 1);
	}

	static function resolveURL(url:String, path:String):String {
		// Invalid URL
		if (Type.typeof(url) != Type.TString || url == "") return "";

		// Host Relative URL
		if (path.match(/^https?:\/\//i) && url.match(/^\//i)) {
			path = path.replace(/(^https?:\/\/[^\/]+).*/i, "$1");
		}

		// Absolute URL http://,https://,//
		if (url.match(/^(https?:)?\/\//i)) return url;

		// Data URI
		if (url.match(/^data:.*,.*$/i)) return url;

		// Blob URL
		if (url.match(/^blob:.*$/i)) return url;

		// Relative URL
		return path + url;
	}
}