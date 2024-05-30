// File path: three.js/test/treeshake/utils/FormatSize.hx
package three.test.treeshake.utils;

import haxe.io.Bytes;

class FormatSize {
  static function main() {
    var n = Std.parseInt(Sys.argv()[2]);
    var formatted = formatBytes(n);
    Sys.println(formatted);
  }

  static function formatBytes(n:Int):String {
    // You'll need to implement the formatBytes function here,
    // as it's not provided in the original JavaScript code.
    // You can use the Haxe standard library and its types to achieve the same result.
    // For example:
    if (n < 1024) return '${n} B';
    else if (n < 1048576) return '${(n / 1024).toFixed(2)} KB';
    else if (n < 1073741824) return '${(n / 1048576).toFixed(2)} MB';
    else return '${(n / 1073741824).toFixed(2)} GB';
  }
}