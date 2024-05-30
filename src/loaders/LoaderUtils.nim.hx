import js.html.TextDecoder;
import js.html.URI;

class LoaderUtils {

    public static function decodeText(array:Uint8Array):String {
        #if js
        trace.warn("THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.");
        if (Type.typeof(TextDecoder) != "undefined") {
            return new TextDecoder().decode(array);
        }
        #end

        var s:String = "";
        for (i in 0...array.length) {
            s += StringTools.fromCharCode(array[i]);
        }

        try {
            return URI.decode(URI.encode(s));
        } catch (e:Dynamic) {
            return s;
        }
    }

    public static function extractUrlBase(url:String):String {
        var index:Int = url.lastIndexOf("/");
        if (index == -1) return "./";
        return url.slice(0, index + 1);
    }

    public static function resolveURL(url:String, path:String):String {
        if (Type.typeof(url) != "String" || url == "") return "";
        if (RegExp.matches(path, /^https?:\/\//i) && RegExp.matches(url, /^\//)) {
            path = RegExp.replace(path, /(^https?:\/\/[^\/]+).*/i, "$1");
        }
        if (RegExp.matches(url, /^(https?:)?\/\//i)) return url;
        if (RegExp.matches(url, /^data:.*,.*$/i)) return url;
        if (RegExp.matches(url, /^blob:.*$/i)) return url;
        return path + url;
    }
}