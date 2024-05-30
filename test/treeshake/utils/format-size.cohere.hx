import js.Node.Process;

class FormatBytes {
    static function format(n: Int): String {
        if (n < 1024) {
            return n + " B";
        } else if (n < Math.pow(1024, 2)) {
            return Std.string(n / 1024) + " KB";
        } else if (n < Math.pow(1024, 3)) {
            return Std.string(n / Math.pow(1024, 2)) + " MB";
        } else {
            return Std.string(n / Math.pow(1024, 3)) + " GB";
        }
    }
}

class ReportSize {
    static function main() {
        var n = Std.parseInt(Process.argv[2]);
        var formatted = FormatBytes.format(n);
        trace(formatted);
    }
}

ReportSize.main();