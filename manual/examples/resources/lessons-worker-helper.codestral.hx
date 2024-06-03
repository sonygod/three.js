class LessonWorkerHelper {

    private var lessonSettings:Dynamic;
    private var origConsole:Dynamic;

    public function new() {
        lessonSettings = js.Browser.global.lessonSettings || Dynamic.emptyObject;
        origConsole = Dynamic.emptyObject;
        if (js.Browser.global.location.href.substring(0, 4) === 'blob') {
            setupConsole();
            captureJSErrors();
            if (js.Browser.global.webglDebugHelper && (lessonSettings.glDebug !== false)) {
                installWebGLDebugContextCreator();
            }
        }
        installWebGLLessonSetup();
    }

    private function sendMessage(data:Dynamic) {
        js.Browser.global.postMessage({
            type: '__editor__',
            data: data
        });
    }

    private function setupConsole() {
        js.Browser.global.console.log = wrapFunc(js.Browser.global.console, 'log');
        js.Browser.global.console.warn = wrapFunc(js.Browser.global.console, 'warn');
        js.Browser.global.console.error = wrapFunc(js.Browser.global.console, 'error');
    }

    private function wrapFunc(obj:Dynamic, logType:String):Function {
        var origFunc = obj[logType].bind(obj);
        origConsole[logType] = origFunc;
        return function(...args) {
            origFunc(...args);
            sendMessage({
                type: 'log',
                logType: logType,
                msg: Array<Dynamic>(args).join(' ')
            });
        };
    }

    private function setupLesson(canvas:js.html.OffscreenCanvas) {
        canvas.addEventListener('webglcontextlost', function(e:js.html.Event) {
            sendMessage({
                type: 'lostContext'
            });
        });
    }

    private function captureJSErrors() {
        js.Browser.global.addEventListener('error', function(e:Dynamic) {
            var msg = e.message || e.error;
            var url = e.filename;
            var lineNo = e.lineno || 1;
            var colNo = e.colno || 1;
            sendMessage({
                type: 'jsError',
                lineNo: lineNo,
                colNo: colNo,
                url: url,
                msg: msg
            });
        });
    }

    private function installWebGLLessonSetup() {
        var oldFn = js.Browser.global.OffscreenCanvas.prototype.getContext;
        js.Browser.global.OffscreenCanvas.prototype.getContext = function(...args) {
            var type = args[0];
            var isWebGL = type.match(/^(webgl|webgl2|experimental-webgl)$/i) != null;
            if (isWebGL) {
                setupLesson(this);
            }
            args[1] = {
                powerPreference: 'low-power',
                ...args[1]
            };
            return oldFn.apply(this, args);
        };
    }

    private function installWebGLDebugContextCreator() {
        var webglDebugHelper = js.Browser.global.webglDebugHelper;
        if (webglDebugHelper == null) {
            return;
        }
        var oldFn = js.Browser.global.OffscreenCanvas.prototype.getContext;
        js.Browser.global.OffscreenCanvas.prototype.getContext = function(...args) {
            var ctx = oldFn.apply(this, args);
            if (ctx != null && ctx.bindTexture != null) {
                ctx = webglDebugHelper.makeDebugContext(ctx, {
                    maxDrawCalls: 100,
                    errorFunc: function(err:Int, funcName:String, args:Array<Dynamic>) {
                        var numArgs = args.length;
                        var enumedArgs = args.map(function(arg, ndx) {
                            var str = webglDebugHelper.glFunctionArgToString(funcName, numArgs, ndx, arg);
                            if (str.length > 200) {
                                str = str.substring(0, 200) + '...';
                            }
                            return str;
                        });
                        var error = js.Browser.global.Error();
                        sendMessage({
                            type: 'jsErrorWithStack',
                            stack: error.stack,
                            msg: webglDebugHelper.glEnumToString(err) + ' in ' + funcName + '(' + enumedArgs.join(', ') + ')'
                        });
                    }
                });
            }
            return ctx;
        };
    }
}