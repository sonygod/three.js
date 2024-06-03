class LoaderUtils {

    public static function decodeText(array: Array<Int>): String {
        // Haxe does not have a direct equivalent for the TextDecoder class
        // You could use an external library or write your own implementation

        // Avoid the String.fromCharCode.apply(null, array) shortcut, which
        // throws a "maximum call stack size exceeded" error for large arrays.

        var s: String = '';

        for (i in 0...array.length) {
            // Implicitly assumes little-endian.
            s += String.fromCharCode(array[i]);
        }

        // Haxe does not have a direct equivalent for the decodeURIComponent and escape functions
        // You could use an external library or write your own implementation

        return s;
    }

    public static function extractUrlBase(url: String): String {

        var index: Int = url.lastIndexOf('/');

        if (index === -1) return './';

        return url.substring(0, index + 1);
    }

    public static function resolveURL(url: String, path: String): String {

        // Invalid URL
        if (Std.is(url, String) && url !== '') return '';

        // Host Relative URL
        if (new EReg("^https?:\\/\\/", "i").match(path) && new EReg("^\\/", "").match(url)) {

            path = path.replace(new EReg("(^https?:\\/\\/[^\\/]+).*", "i"), '$1');

        }

        // Absolute URL http://,https://,//
        if (new EReg("^(https?:)?\\/\\/", "i").match(url)) return url;

        // Data URI
        if (new EReg("^data:.*,.*$", "i").match(url)) return url;

        // Blob URL
        if (new EReg("^blob:.*$", "i").match(url)) return url;

        // Relative URL
        return path + url;
    }
}