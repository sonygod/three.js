// three.js/editor/js/libs/ffmpeg.min.js

package ffmpeg;

import js.lib.Promise;
import js.lib.Error;

// 497
class FFmpeg {
  public static var corePath:String;
  public function new() {}
  public function getCreateFFmpegCore():Void {}
}

// 663
class FileLoader {
  public function new() {}
  public function load(file:Dynamic):Promise<Uint8Array> {
    // implementation
  }
}

// 452
class CreateFFmpegCore {
  public function new() {}
  public function createFFmpegCore():Void {}
}

// 698
class Options {
  public var log:Bool;
  public var logger:Dynamic;
  public var progress:Dynamic;
}

// 500
class DefaultOptions {
  public var defaultArgs:Array<String> = ["./ffmpeg", "-nostdin", "-y"];
  public var baseOptions:Options;
}

// 906
class FFmpeg {
  public function new() {}
  public function load():Void {}
  public function run(command:Array<String>):Void {}
  public function exit():Void {}
}

// 352
class CreateFFmpeg {
  public function new() {}
  public function createFFmpeg():FFmpeg {}
}

// 185
class Logger {
  public function new() {}
  public function setLogging(enabled:Bool):Void {}
  public function setCustomLogger(logger:Dynamic):Void {}
  public function log(type:String, message:String):Void {}
}

// 319
class Malloc {
  public function new() {}
  public function malloc(size:Int):Dynamic {}
}

// 583
class FFmpegProcess {
  public function new() {}
  public function onMessage(message:String):Void {}
}