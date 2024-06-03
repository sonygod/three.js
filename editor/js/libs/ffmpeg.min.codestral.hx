import js.Browser;
import js.html.FileReader;
import js.html.Blob;
import js.html.URL;
import js.html.document;
import js.html.Window;
import js.html.Element;
import js.html.HTMLDocument;
import js.html.HTMLHeadElement;
import js.html.HTMLScriptElement;
import js.Promise;
import js.ArrayBuffer;
import js.TypedArray;
import js.lib.Function;
import js.lib.RegExp;
import js.lib.Error;

class FFmpeg {

    private var logging:Bool = false;
    private var customLogger:Dynamic = null;
    private var progressCallback:Dynamic = null;
    private var ffmpegCore:Dynamic = null;
    private var ffmpegCoreLoadPromise:Promise<Void> = null;
    private var isRunning:Bool = false;

    public function new(options:Dynamic = null) {
        if (options != null) {
            if (options.hasOwnProperty('log')) logging = options.log;
            if (options.hasOwnProperty('logger')) customLogger = options.logger;
            if (options.hasOwnProperty('progress')) progressCallback = options.progress;
        }
    }

    public function setLogging(enabled:Bool):Void {
        logging = enabled;
    }

    public function setCustomLogger(logger:Dynamic):Void {
        customLogger = logger;
    }

    public function log(type:String, message:String):Void {
        if (customLogger != null) customLogger({ type: type, message: message });
        if (logging) Browser.console.log('[' + type + '] ' + message);
    }

    public function load():Promise<Void> {
        if (ffmpegCoreLoadPromise == null) {
            ffmpegCoreLoadPromise = Promise.resolve().then(() => {
                log('info', 'load ffmpeg-core');
                if (ffmpegCore != null) {
                    log('info', 'ffmpeg-core loaded already');
                    return;
                }
                log('info', 'loading ffmpeg-core');
                return getCreateFFmpegCore().then(createFFmpegCore => {
                    var corePath = createFFmpegCore.corePath;
                    var workerPath = createFFmpegCore.workerPath;
                    var wasmPath = createFFmpegCore.wasmPath;
                    return createFFmpegCore.createFFmpegCore({
                        mainScriptUrlOrBlob: corePath,
                        printErr: error => log('fferr', error),
                        print: message => log('ffout', message),
                        locateFile: (fileName, prefix) => {
                            if (typeof(Window) !== 'undefined') {
                                if (wasmPath != null && fileName.endsWith('ffmpeg-core.wasm')) return wasmPath;
                                if (workerPath != null && fileName.endsWith('ffmpeg-core.worker.js')) return workerPath;
                            }
                            return prefix + fileName;
                        }
                    }).then(core => {
                        ffmpegCore = core;
                        log('info', 'ffmpeg-core loaded');
                    });
                });
            });
        }
        return ffmpegCoreLoadPromise;
    }

    public function isLoaded():Bool {
        return ffmpegCore != null;
    }

    public function run(args:Array<String>):Promise<Void> {
        if (ffmpegCore == null) throw new Error('ffmpeg.wasm is not ready, make sure you have completed load()');
        if (isRunning) throw new Error('ffmpeg.wasm can only run one command at a time');
        isRunning = true;
        log('info', 'run ffmpeg command: ' + args.join(' '));
        return new Promise<Void>(resolve => {
            var command = ['./ffmpeg', '-nostdin', '-y'].concat(args).filter(arg => arg.length > 0);
            var commandPointer = allocateUTF8(command);
            var commandLength = command.length;
            var result = ffmpegCore.ccall('proxy_main', 'number', ['number', 'number'], [commandLength, commandPointer]);
            freeUTF8(commandPointer);
            resolve();
        });
    }

    public function exit():Void {
        if (ffmpegCore == null) throw new Error('ffmpeg.wasm is not ready, make sure you have completed load()');
        isRunning = false;
        ffmpegCore.exit(1);
        ffmpegCore = null;
    }

    public function setProgress(callback:Dynamic):Void {
        progressCallback = callback;
    }

    private function getCreateFFmpegCore():Promise<Dynamic> {
        // Implementation of getCreateFFmpegCore function from the provided JavaScript code
        // ...
    }

    private function allocateUTF8(str:String):Int {
        // Implementation of allocateUTF8 function from the provided JavaScript code
        // ...
    }

    private function freeUTF8(ptr:Int):Void {
        // Implementation of freeUTF8 function from the provided JavaScript code
        // ...
    }

    private function fetchFile(file:Dynamic):Promise<Uint8Array> {
        // Implementation of fetchFile function from the provided JavaScript code
        // ...
    }
}