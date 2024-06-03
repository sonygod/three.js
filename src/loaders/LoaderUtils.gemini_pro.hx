class LoaderUtils {

	static function decodeText(array:Array<Int>):String {
		// @deprecated, r165
		Sys.println("THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.");

		if (js.Lib.isClass(js.Lib.typeof(js.Lib.global.TextDecoder), "TextDecoder")) {
			return new js.Lib.get(js.Lib.global.TextDecoder).decode(array);
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
			return js.Lib.decodeURIComponent(js.Lib.escape(s));
		} catch (e:Dynamic) { // see #16358
			return s;
		}
	}

	static function extractUrlBase(url:String):String {
		var index = url.lastIndexOf('/');
		if (index == -1) return "./";
		return url.substring(0, index + 1);
	}

	static function resolveURL(url:String, path:String):String {
		// Invalid URL
		if (typeof url != "string" || url == "") return "";

		// Host Relative URL
		if (StringTools.startsWith(path, "https://") || StringTools.startsWith(path, "http://")) {
			if (StringTools.startsWith(url, "/")) {
				path = path.replace(/(^https?:\/\/[^\/]+).*/i, "$1");
			}
		}

		// Absolute URL http://,https://,//
		if (StringTools.startsWith(url, "https://") || StringTools.startsWith(url, "http://") || StringTools.startsWith(url, "//")) return url;

		// Data URI
		if (StringTools.startsWith(url, "data:.*,.*")) return url;

		// Blob URL
		if (StringTools.startsWith(url, "blob:.*")) return url;

		// Relative URL
		return path + url;
	}

}