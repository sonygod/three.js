import js.lib.Promise;
import js.lib.Uint8Array;
import js.lib.ArrayBuffer;
import js.Browser;

@JsRequire("ffmpeg")
extern class FFmpeg {
  static var defaultOptions: Dynamic;
  static function createFFmpeg(options: Dynamic): Dynamic;
  static function fetchFile(url: String): Promise<Uint8Array>;
}

class MyFFmpeg {
  static function main() {
    FFmpeg.createFFmpeg().then(ffmpeg => {
      // Your FFmpeg logic here
    });
  }
}