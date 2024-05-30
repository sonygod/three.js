class FormatBytes {
    public static function formatBytes(bytes:Float, ?decimals:Int):String {
        if (bytes == 0) return '0 B';

        var k:Float = 1000.0;
        var dm:Int = if (decimals == null || decimals < 0) 0 else decimals;
        var sizes:Array<String> = [ 'B', 'kB', 'MB', 'GB' ];

        var i:Int = Math.floor(Math.log(bytes) / Math.log(k));

        return Std.string(Std.parseFloat(Std.format("%.${dm}f", bytes / Math.pow(k, i)))) + ' ' + sizes[i];
    }
}