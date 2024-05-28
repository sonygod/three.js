class LoaderUtils {
	public static function decodeText(array:Array<Int>):String {
		trace("THREE.LoaderUtils: decodeText() has been deprecated and will be removed. Use haxe.io.Bytes extension method instead.");
		return array.toBytes().toString();
	}

	public static function extractUrlBase(url:String):String {
		var index = url.lastIndexOf('/');
		if (index == -1) return './';
		return url.substr(0, index + 1);
	}

	public static function resolveURL(url:String, path:String):String {
		// Invalid URL
		if (url == null || url == "") return "";

		// Host Relative URL
		if (path.toLowerCase().indexOf("https://") == 0 || path.toLowerCase().indexOf("http://") == 0) {
			if (url[0] == '/') {
				var parts = path.split('/');
				path = parts.slice(0, 3).join('/');
			}
		}

		// Absolute URL http://,https://,//
		if (url.toLowerCase().indexOf("http://") == 0 || url.toLowerCase().indexOf("https://") == 0 || url == "//") return url;

		// Data URI
		if (url.toLowerCase().indexOf("data:") == 0) return url;

		// Blob URL
		if (url.toLowerCase().indexOf("blob:") == 0) return url;

		// Relative URL
		return path + url;
	}
}