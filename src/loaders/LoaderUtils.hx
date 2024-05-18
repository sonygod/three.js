package three.loaders;

class LoaderUtils {
  static function decodeText(array:Array<Int>) {
    // @deprecated, r165
    trace("THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.");

    if (untyped __js__('typeof TextDecoder') != 'undefined') {
      return new untyped __js__('TextDecoder')().decode(array);
    }

    var s = '';
    for (i in 0...array.length) {
      // Implicitly assumes little-endian.
      s += String.fromCharCode(array[i]);
    }

    try {
      // merges multi-byte utf-8 characters.
      return untyped __js__('decodeURIComponent')(untyped __js__('escape')(s));
    } catch (e) { // see #16358
      return s;
    }
  }

  static function extractUrlBase(url:String) {
    var index = url.lastIndexOf('/');
    if (index == -1) return './';
    return url.substring(0, index + 1);
  }

  static function resolveURL(url:String, path:String) {
    // Invalid URL
    if (url == null || url == '') return '';

    // Host Relative URL
    if (~path.indexOf('http://') || ~path.indexOf('https://') && ~/^\/.test(url)) {
      path = ~/(https?:\/\/[^\/]+).*$/i.replace(path, '$1');
    }

    // Absolute URL http://,https://,//
    if (~/(https?:\/\/)?\/\//i.test(url)) return url;

    // Data URI
    if (~/^data:.*,.*$/i.test(url)) return url;

    // Blob URL
    if (~/^blob:.*/i.test(url)) return url;

    // Relative URL
    return path + url;
  }
}