// used in report-size.yml
import js.Lib;

class FormatDiff {
    static function main() {
        var filesize = js.Lib.parseFloat(Sys.args()[2]);
        var filesizeBase = js.Lib.parseFloat(Sys.args()[3]);

        var diff = filesize - filesizeBase;
        var formatted = (diff >= 0 ? '+' : '-') + formatBytes(Math.abs(diff), 2);

        trace(formatted);
    }

    static function formatBytes(bytes:Float, decimals:Int = 2):String {
        if (bytes == 0) return '0 Bytes';

        var k = 1024;
        var dm = decimals < 0 ? 0 : decimals;
        var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

        var i = Math.floor(Math.log(bytes) / Math.log(k));

        return js.Lib.parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }

    static function main() {
        js.Boot.getMainClass(function(mainClass) {
            if (mainClass != null) {
                js.Lib.call(mainClass, null);
            }
        });
    }
}