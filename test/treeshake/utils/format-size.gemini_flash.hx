import js.Browser.document;

class ReportSize {
  static function main() {
    // Haxe doesn't have direct access to command line arguments like process.argv.
    // We'll simulate it with a hardcoded value or by getting input from elsewhere.
    var n = 1234567; // Replace with desired value or input mechanism

    var formatted = formatBytes(n);
    trace(formatted); // Use 'trace' for output in Haxe
  }

  static function formatBytes(bytes:Float, decimals:Int = 2):String {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return (bytes / Math.pow(k, i)).toFixed(dm) + ' ' + sizes[i];
  }
}