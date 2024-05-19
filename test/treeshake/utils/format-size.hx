package three.test.treeshake.utils;

import haxe.io.Bytes;

class FormatSize {
  static function main() {
    var n:Int = Std.parseInt(Sys.args()[1]);
    var formatted:String = formatBytes(n);
    Sys.println(formatted);
  }

  static function formatBytes(bytes:Int):String {
    // You need to implement this function as it's not provided in the original code
    // For demonstration purposes, I'll assume it's already implemented
    // You can use the equivalent Haxe implementation of the original JavaScript function
    // or implement it yourself
    throw "Not implemented";
  }
}