import js.Browser.document;
import js.Browser.window;
import FormatBytes;

class Main {
    static function main() {
        var n = Std.parseFloat(Sys.args()[2]);
        var formatted = FormatBytes.formatBytes(n);

        trace(formatted);
    }
}