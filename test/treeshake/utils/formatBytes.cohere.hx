function formatBytes(bytes: Float, decimals: Int = 1) -> String {
    if (bytes == 0) {
        return "0 B";
    }

    const k = 1000;
    var dm = decimals < 0 ? 0 : decimals;
    var sizes = ["B", "kB", "MB", "GB"];

    var i = Std.int(Math.log(bytes) / Math.log(k));

    var size = (bytes / Math.pow(k, i)).toFixed(dm);
    return size ~ " " ~ sizes[i];
}

class BytesFormatter {
    static public function format(bytes: Float, decimals: Int = 1) -> String {
        return formatBytes(bytes, decimals);
    }
}