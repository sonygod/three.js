package three.loaders;

class LoaderUtils {

    static function decodeText(array:Array<Int>):String {
        // @deprecated, r165
        trace("THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.");

        if (untyped __js__('typeof TextDecoder') != 'undefined') {
            return untyped __js__('new TextDecoder()').decode(array);
        }

        var s:String = '';

        for (i in 0...array.length) {
            s += String.fromCharCode(array[i]);
        }

        try {
            // merges multi-byte utf-8 characters.
            return untyped __js__('decodeURIComponent')(untyped __js__('escape')(s));
        } catch (e:Dynamic) { // see #16358
            return s;
        }
    }

    static function extractUrlBase(url:String):String {
        var index:Int = url.lastIndexOf('/');
        if (index == -1) return './';
        return url.substr(0, index + 1);
    }

    static function resolveURL(url:String, path:String):String {
        // Invalid URL
        if (url == null || url == '') return '';

        // Host Relative URL
        if (~path.indexOf('http://') || ~path.indexOf('https://')) {
            if (url.charAt(0) == '/') {
                path = ~/^(https?:\/\/[^\ \/]+).*/i.replace(path, '$1');
            }
        }

        // Absolute URL http://,https://,//
        if (~url.indexOf('http://') || ~url.indexOf('https://') || url.indexOf('//') == 0) return url;

        // Data URI
        if (~url.indexOf('data:')) return url;

        // Blob URL
        if (~url.indexOf('blob:')) return url;

        // Relative URL
        return path + url;
    }
}