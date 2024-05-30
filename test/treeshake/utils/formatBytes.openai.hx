package three.test.treeshake.utils;

class FormatBytes {
    public static function formatBytes(bytes:Float, decimals:Int = 1):String {
        if (bytes == 0) return '0 B';

        const k:Float = 1000;
        const dm:Int = decimals < 0 ? 0 : decimals;
        const sizes:Array<String> = ['B', 'kB', 'MB', 'GB'];

        const i:Int = Math.floor(Math.log(bytes) / Math.log(k));

        return Std.parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
    }
}

Note the following changes:

* In Haxe, we need to specify the package and class names, which are `three.test.treeshake.utils` and `FormatBytes`, respectively.
* In Haxe, we use `Float` instead of `number` for floating-point numbers.
* In Haxe, we use `Int` instead of `integer` for integer values.
* In Haxe, we use `Std.parseFloat` instead of `parseFloat` to convert a string to a float.
* In Haxe, we use `Math.log` and `Math.pow` from the Haxe `Math` class, which are equivalent to the JavaScript `Math.log` and `Math.pow` functions.
* In Haxe, we use an `Array<String>` to define the `sizes` array, which is equivalent to the JavaScript array literal.

You can use this Haxe class like this:

trace(FormatBytes.formatBytes(1024)); // Output: "1 kB"
trace(FormatBytes.formatBytes(1024 * 1024)); // Output: "1 MB"