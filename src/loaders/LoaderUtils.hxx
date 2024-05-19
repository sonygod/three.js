class LoaderUtils {

    public static function decodeText(array:Array<Int>):String { // @deprecated, r165

        trace('THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.');

        if (typeof js.Browser.TextDecoder !== 'undefined') {

            return js.Browser.TextDecoder.decode(array);

        }

        // Avoid the String.fromCharCode.apply(null, array) shortcut, which
        // throws a "maximum call stack size exceeded" error for large arrays.

        var s = '';

        for (i in array) {

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

    public static function extractUrlBase(url:String):String {

        var index = url.lastIndexOf('/');

        if (index === - 1) return './';

        return url.substr(0, index + 1);

    }

    public static function resolveURL(url:String, path:String):String {

        // Invalid URL
        if (typeof url !== 'string' || url === '') return '';

        // Host Relative URL
        if (/^https?:\/\//i.match(path) && /^\//.match(url)) {

            path = path.replace(/(^https?:\/\/[^\/]+).*/i, '$1');

        }

        // Absolute URL http://,https://,//
        if (/^(https?:)?\/\//i.match(url)) return url;

        // Data URI
        if (/^data:.*,.*$/i.match(url)) return url;

        // Blob URL
        if (/^blob:.*$/i.match(url)) return url;

        // Relative URL
        return path + url;

    }

}