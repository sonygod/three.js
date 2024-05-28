package three.js.src.loaders;

class LoaderUtils {
  static function decodeText(array:Array<Int>):String {
    // Warning: THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.
    trace('THREE.LoaderUtils: decodeText() has been deprecated with r165 and will be removed with r175. Use TextDecoder instead.');

    if (typeof js.html.TextDecoder != 'undefined') {
      return new js.html.TextDecoder().decode(array);
    }

    var s:String = '';

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
    var index:Int = url.lastIndexOf('/');
    if (index == -1) return './';
    return url.substring(0, index + 1);
  }

  static function resolveURL(url:String, path:String):String {
    // Invalid URL
    if (url == null || url == '') return '';

    // Host Relative URL
    if (~path.indexOf('https://') || ~path.indexOf('http://') && ~/^\/.test(url)) {
      path = ~/^(https?:\/\/[^\/]+).*/i.replace(path, '$1');
    }

    // Absolute URL http://,https://,//
    if (~url.indexOf('://') || ~/^https?:\/\/.test(url)) return url;

    // Data URI
    if (~url.indexOf('data:')) return url;

    // Blob URL
    if (~url.indexOf('blob:')) return url;

    // Relative URL
    return path + url;
  }
}