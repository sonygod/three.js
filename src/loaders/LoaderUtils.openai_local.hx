package three.loaders;

class LoaderUtils {

    public static function decodeText(array: Array<Int>): String {
        // @deprecated, r165
        trace('THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.');

        #if js
        if (untyped __js__("typeof TextDecoder !== 'undefined'")) {
            return untyped __js__("new TextDecoder().decode(array)");
        }
        #end

        // Avoid the String.fromCharCode.apply(null, array) shortcut, which
        // throws a "maximum call stack size exceeded" error for large arrays.

        var s: String = '';

        for (i in 0...array.length) {
            // Implicitly assumes little-endian.
            s += String.fromCharCode(array[i]);
        }

        try {
            // merges multi-byte utf-8 characters.
            return haxe.Utf8.decode(s);
        } catch (e: Dynamic) {
            return s;
        }
    }

    public static function extractUrlBase(url: String): String {
        var index: Int = url.lastIndexOf('/');
        if (index == -1) return './';
        return url.substring(0, index + 1);
    }

    public static function resolveURL(url: String, path: String): String {
        // Invalid URL
        if (url == null || url == '') return '';

        // Host Relative URL
        if (~/^https?:\/\//i.match(path) && ~/^\//.match(url)) {
            path = path.replace(~/"(^https?:\/\/[^\/]+).*/i"/g, '$1');
        }

        // Absolute URL http://,https://,//
        if (~/^(https?:)?\/\//i.match(url)) return url;

        // Data URI
        if (~/^data:.*,.*$/i.match(url)) return url;

        // Blob URL
        if (~/^blob:.*$/i.match(url)) return url;

        // Relative URL
        return path + url;
    }

}