package;

import js.Browser.window;
import js.node.Fs;
import js.node.Path;
import js.node.buffer.Buffer;
import js.node.buffer.BufferView;
import js.node.buffer.SlowBuffer;

import js.npm.node_fetch;
import js.npm.node_fetch.Headers;
import js.npm.node_fetch.RequestInit;
import js.npm.node_fetch.Response;
import js.npm.node_fetch.Response as FetchResponse;

import js.npm.resolve_url;
import js.npm.resolve_url.ResolveUrl;

import js.npm.is_url;
import js.npm.is_url.IsUrl;

class FFmpeg {
    public var createFFmpegCore:Dynamic;
    public var corePath:String;
    public var wasmPath:String;
    public var workerPath:String;

    public function new(createFFmpegCore:Dynamic, corePath:String, wasmPath:String, workerPath:String) {
        this.createFFmpegCore = createFFmpegCore;
        this.corePath = corePath;
        this.wasmPath = wasmPath;
        this.workerPath = workerPath;
    }
}

class FFmpegWasm {
    private var _ffmpeg:FFmpeg;
    private var _progress:Function;
    private var _logger:Function;
    private var _log:Bool;

    public function new(?options:FFmpegOptions) {
        options = options != null ? options : { };
        _log = options.log != null ? options.log : false;
        _logger = options.logger != null ? options.logger : function(_) {};
        _progress = options.progress != null ? options.progress : function(_) {};
        _ffmpeg = null;
    }

    public function load():Void {
        if (_ffmpeg != null) {
            throw "ffmpeg.wasm was loaded, you should not load it again, use ffmpeg.isLoaded() to check next time.";
        }

        var corePath = options.corePath != null ? options.corePath : "";
        if (corePath == "") {
            throw "corePath should be a string!";
        }

        var fetchCore = function() {
            return fetch(corePath)
                .then(function(response:FetchResponse) {
                return response.arrayBuffer();
            })
                .then(function(buffer:ArrayBuffer) {
                return new Blob([buffer], { type: "application/javascript" });
            })
                .then(function(blob:Blob) {
                return URL.createObjectURL(blob);
            });
        };

        var fetchWasm = function() {
            return fetch(corePath.replace("ffmpeg-core.js", "ffmpeg-core.wasm"))
                .then(function(response:FetchResponse) {
                return response.arrayBuffer();
            })
                .then(function(buffer:ArrayBuffer) {
                return new Blob([buffer], { type: "application/wasm" });
            })
                .then(function(blob:Blob) {
                return URL.createObjectURL(blob);
            });
        };

        var fetchWorker = function() {
            return fetch(corePath.replace("ffmpeg-core.js", "ffmpeg-core.worker.js"))
                .then(function(response:FetchResponse) {
                return response.arrayBuffer();
            })
                .then(function(buffer:ArrayBuffer) {
                return new Blob([buffer], { type: "application/javascript" });
            })
                .then(function(blob:Blob) {
                return URL.createObjectURL(blob);
            });
        };

        var loadFFmpeg = function(corePath:String, wasmPath:String, workerPath:String) {
            return new Promise(function(resolve, reject) {
                var script = window.document.createElement("script");
                script.src = corePath;
                script.type = "text/javascript";
                script.addEventListener("load", function() {
                    window.document.getElementsByTagName("head")[0].appendChild(script);
                    resolve({
                        createFFmpegCore: window.createFFmpegCore,
                        corePath: corePath,
                        wasmPath: wasmPath,
                        workerPath: workerPath
                    });
                });
            });
        };

        var loadFFmpegCore = function() {
            return new Promise(function(resolve, reject) {
                if (window.createFFmpegCore != null) {
                    resolve({
                        createFFmpegCore: window.createFFmpegCore,
                        corePath: corePath,
                        wasmPath: wasmPath,
                        workerPath: workerPath
                    });
                } else {
                    loadFFmpeg(corePath, wasmPath, workerPath).then(resolve, reject);
                }
            });
        };

        var ffmpegCorePromise = loadFFmpegCore();
        ffmpegCorePromise.then(function(ffmpeg:FFmpeg) {
            _ffmpeg = ffmpeg;
            _logger("info", "ffmpeg-core.js script is loaded already");
        }, function(error) {
            _logger("error", "Failed to load ffmpeg-core: " + error);
        });
    }

    public function isLoaded():Bool {
        return _ffmpeg != null;
    }

    public function run(?args:Array<String>) {
        if (_ffmpeg == null) {
            throw "ffmpeg.wasm was not loaded, you should call ffmpeg.load() first!";
        }

        if (_running) {
            throw "ffmpeg.wasm can only run one command at a time";
        }

        _running = true;

        var args = args != null ? args : [];
        _logger("info", "run ffmpeg command: " + args.join(" "));

        var defaultArgs = ["-nostdin", "-y"];
        var command = defaultArgs.concat(args);

        var ccall = _ffmpeg.createFFmpegCore({
            mainScriptUrlOrBlob: _ffmpeg.corePath,
            printErr: function(message) {
                _logger("fferr", message);
            },
            print: function(message) {
                _logger("ffout", message);
                _progress(message);
            },
            locateFile: function(path, prefix) {
                if (prefix == "wasm") {
                    return _ffmpeg.wasmPath;
                } else if (prefix == "worker") {
                    return _ffmpeg.workerPath;
                } else {
                    return path;
                }
            }
        });

        var promise = new Promise<Void>(function(resolve, reject) {
            var exitCode = ccall(command);
            if (exitCode != 0) {
                reject("FFmpeg exited with code " + exitCode);
            } else {
                resolve();
            }
        });

        promise.then(function() {
            _running = false;
        }, function(error) {
            _running = false;
            throw error;
        });

        return promise;
    }

    public function exit():Void {
        if (_ffmpeg == null) {
            throw "ffmpeg.wasm was not loaded, you should call ffmpeg.load() first!";
        }

        _ffmpeg.exit(1);
        _ffmpeg = null;
    }

    public function FS(method:String, ?args:Array<Dynamic>) {
        if (_ffmpeg == null) {
            throw "ffmpeg.wasm was not loaded, you should call ffmpeg.load() first!";
        }

        if (method == "readdir") {
            if (args == null || args.length == 0) {
                throw "ffmpeg.FS('readdir', 'path/to/dir') error. Check if the path exists, ex: ffmpeg.FS('readdir', '/path/to/dir')";
            }
        } else if (method == "readFile") {
            if (args == null || args.length == 0) {
                throw "ffmpeg.FS('readFile', 'path/to/file') error. Check if the path exists";
            }
        }

        var f = _ffmpeg.createFFmpegCore.FS[method];
        if (f == null) {
            throw "Oops, something went wrong in FS operation.";
        }

        return f.apply(_ffmpeg.createFFmpegCore.FS, args);
    }

    private var _running:Bool = false;

    private static function _logger(type:String, message:String) {
        if (_log) {
            trace("[${type}] ${message}");
        }
    }
}

class FFmpegOptions {
    public var corePath:String;
    public var log:Bool;
    public var logger:Function;
    public var progress:Function;
}

class FFmpegStatic {
    public static function createFFmpeg(?options:FFmpegOptions):FFmpegWasm {
        return new FFmpegWasm(options);
    }

    public static function fetchFile(url:String):Promise<Bytes> {
        if (isUrl(url)) {
            return fetch(url)
                .then(function(response:FetchResponse) {
                return response.arrayBuffer();
            })
                .then(function(buffer:ArrayBuffer) {
                return new Bytes(buffer);
            });
        } else {
            var path = Path.resolve(url);
            var buffer = new SlowBuffer(Fs.readFileSync(path));
            return Promise.resolve(new Bytes(buffer));
        }
    }
}

class Bytes {
    private var _buffer:BufferView;

    public function new(buffer:ArrayBuffer) {
        _buffer = new BufferView(buffer);
    }

    public function getBytes():Array<Int> {
        var length = _buffer.length;
        var bytes = [];
        for (i in 0...length) {
            bytes.push(_buffer.get(i));
        }
        return bytes;
    }
}

class IsUrl {
    public static function isUrl(url:String):Bool {
        return ResolveUrl.isUrl(url);
    }
}

class Fetch {
    public static function fetch(url:String, ?init:RequestInit):Promise<Response> {
        return node_fetch.fetch(url, init);
    }
}

class Headers {
    public static function headers(headers:Map<String, String>):Headers {
        return new node_fetch.Headers(headers);
    }
}