package three.js.test.treeshake.utils;

class FormatBytes {
  public static function formatBytes(bytes:Int, decimals:Int = 1):String {
    if (bytes == 0) return '0 B';

    var k:Int = 1000;
    var dm:Int = decimals < 0 ? 0 : decimals;
    var sizes:Array<String> = ['B', 'kB', 'MB', 'GB'];

    var i:Int = Math.floor(Math.log(bytes) / Math.log(k));

    return Std.parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  }
}