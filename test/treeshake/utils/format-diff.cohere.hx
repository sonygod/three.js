import js.Node.Process;
import js.Node.Globals;

class Format {
    static function bytes(bytes: Float, decimals: Int = 2): String {
        if (bytes == 0) {
            return '0 Bytes';
        }

        const k = 1024;
        const dm = decimals < 0 ? 0 : decimals;
        const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));

        return (bytes / Math.pow(k, i)).toFixed(dm) + ' ' + sizes[i];
    }
}

class Main {
    static function main() {
        var filesize = Std.parseFloat(Process.argv[2]);
        var filesizeBase = Std.parseFloat(Process.argv[3]);

        var diff = filesize - filesizeBase;
        var formatted = (diff >= 0 ? '+' : '-') + Format.bytes(Math.abs(diff));

        Globals.console.log(formatted);
    }
}