// File path: three.js/test/treeshake/utils/format-size.hx

import js.Node.process.argv;

class FormatSize {
    static function main() {
        var n = Std.parseFloat(argv[2]);
        var formatted = formatBytes(n);
        trace(formatted);
    }

    static function formatBytes(bytes:Float):String {
        // 这里应该是formatBytes的实现
        // 由于原始的JavaScript代码没有提供，所以我假设它是一个简单的函数
        return "Formatted: " + bytes.toString();
    }
}

class Main {
    static function main() {
        FormatSize.main();
    }
}