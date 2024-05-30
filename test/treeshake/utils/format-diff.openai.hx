package three.test.treeshake.utils;

import haxe.io.Bytes;

class FormatDiff {
  static function main() {
    var filesize = Sys.args()[2];
    var filesizeBase = Sys.args()[3];

    var diff = Std.parseInt(filesize) - Std.parseInt(filesizeBase);
    var formatted = '${diff >= 0 ? "+" : "-"}${formatBytes(Math.abs(diff), 2)}';

    Sys.println(formatted);
  }

  static function formatBytes(bytes:Float, precision:Int):String {
    // You'll need to implement the formatBytes function yourself, 
    // as it's not provided in the original code snippet.
    // This is just a placeholder.
    return "Implement me!";
  }
}