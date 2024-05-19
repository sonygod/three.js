package three.js.test.treeshake.utils;

import haxe.io.Args;
import haxe.io.Path;
import formatBytes.FormatBytes;

class FormatDiff {
    static function main() {
        var filesize = Std.parseFloat(Args.get(2));
        var filesizeBase = Std.parseFloat(Args.get(3));

        var diff = filesize - filesizeBase;
        var formatted = (diff >= 0 ? '+' : '-') + FormatBytes.formatBytes(Math.abs(diff), 2);

        Sys.println(formatted);
    }
}