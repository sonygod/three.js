import js.Math;

class FormatBytes {
    public static function format(bytes: Int, decimals: Int = 1): String {
        if (bytes === 0) return '0 B';

        var k = 1000;
        var dm = decimals < 0 ? 0 : decimals;
        var sizes = [ 'B', 'kB', 'MB', 'GB' ];

        var i = Math.floor(Math.log(bytes) / Math.log(k));

        return parseFloat(String((bytes / Math.pow(k, i)).toFixed(dm))) + ' ' + sizes[i];
    }
}