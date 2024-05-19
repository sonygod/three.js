package three.js.manual.examples;

import js.html.CanvasElement;
import js.html.Document;
import js.Browser;
import js.html.Window;
import js.html.StyleElement;
import js.html.DivElement;
import js.html.Event;

class LessonsHelper {
    private static var lessonSettings:Dynamic = {};
    private static var topWindow:Window = Browser.window;
    private static var origConsole:Dynamic = {};

    /**
     * Check if the page is embedded.
     * @param {Window?) w window to check
     * @return {boolean} True of we are in an iframe
     */
    static function isInIFrame( w:Window = null ):Bool {
        w = w != null ? w : topWindow;
        return w != w.top;
    }

    static function updateCSSIfInIFrame() {
        if (isInIFrame()) {
            try {
                Document.body.className = 'iframe';
            } catch (e:Dynamic) {
                // ignore
            }
            try {
                Document.body.parentElement.className = 'iframe';
            } catch (e:Dynamic) {
                // ignore
            }
        }
    }

    static function isInEditor():Bool {
        return Browser.window.location.href.substring(0, 4) == 'blob';
    }

    /**
     * Creates a webgl context. If creation fails it will
     * change the contents of the container of the <canvas>
     * tag to an error message with the correct links for WebGL.
     * @param {CanvasElement} canvas. The canvas element to
     *     create a context from.
     * @param {WebGLContextCreationAttributes} opt_attribs Any
     *     creation attributes you want to pass in.
     * @return {WebGLRenderingContext} The created context.
     * @memberOf module:webgl-utils
     */
    static function showNeedWebGL( canvas:CanvasElement ):Void {
        var doc:Document = canvas.ownerDocument;
        if (doc != null) {
            var temp:DivElement = doc.createElement('div');
            temp.innerHTML = '
                <div style="
                    position: absolute;
                    left: 0;
                    top: 0;
                    background-color: #DEF;
                    width: 100%;
                    height: 100%;
                    display: flex;
                    flex-flow: column;
                    justify-content: center;
                    align-content: center;
                    align-items: center;
                ">
                    <div style="text-align: center;">
                        It doesn\'t appear your browser supports WebGL.<br/>
                        <a href="http://get.webgl.org" target="_blank">Click here for more information.</a>
                    </div>
                </div>
            ';
            var div:DivElement = temp.querySelector('div');
            doc.body.appendChild(div);
        }
    }

    static function setupConsole():Void {
        var parent:DivElement = Document.createElement('div');
        parent.className = 'console';
        var toggle:DivElement = Document.createElement('div');
        toggle.style.position = 'absolute';
        toggle.style.right = '0px';
        toggle.style.bottom = '0px';
        toggle.style.background = '#EEE';
        toggle.style.fontSize = 'smaller';
        toggle.style.cursor = 'pointer';
        toggle.addEventListener(Event.CLICK, showHideConsole);
        function showHideConsole(event:Event):Void {
            show = !show;
            toggle.textContent = show ? '\u2716' : '\u2714';
            parent.style.display = show ? '' : 'none';
        }
        showHideConsole(null);
        var lines:Array<DivElement> = new Array();
        var added:Bool = false;
        function addLine(type:String, str:String, prefix:String):Void {
            var div:DivElement = Document.createElement('div');
            div.textContent = prefix + str;
            div.className = 'console-line ' + type;
            parent.appendChild(div);
            lines.push(div);
            if (!added) {
                added = true;
                Document.body.appendChild(parent);
                Document.body.appendChild(toggle);
            }
        }
        function addLines(type:String, str:String, prefix:String):Void {
            while (lines.length > 100) {
                var div:DivElement = lines.shift();
                parent.removeChild(div);
            }
            addLine(type, str, prefix);
        }
        window.console.log = wrapFunc(window.console, 'log', '');
        window.console.warn = wrapFunc(window.console, 'warn', '\u26A0');
        window.console.error = wrapFunc(window.console, 'error', '\u2716');
    }

    static function wrapFunc(obj:Dynamic, funcName:String, prefix:String):Void->Void {
        var oldFn:Void->Void = obj[funcName].bind(obj);
        return function(str:String):Void {
            addLines(funcName, str, prefix);
            oldFn(str);
        }
    }

    static function reportJSError(url:String, lineNo:Int, colNo:Int, msg:String):Void {
        try {
            var { origUrl, actualLineNo } = topWindow.parent.getActualLineNumberAndMoveTo(url, lineNo, colNo);
            url = origUrl;
            lineNo = actualLineNo;
        } catch (ex:Dynamic) {
            origConsole.error(ex);
        }
        console.error(url, "line:", lineNo, ":", msg);
    }

    static function parseStack(stack:String):Dynamic {
        var lineNdx:Int;
        var matcher:Dynamic;
        if (/chrome|opera/i.test(Browser.navigator.userAgent)) {
            lineNdx = 3;
            matcher = function(line:String):Dynamic {
                var m:Array<String> = /at (.*?)\((.*?):(\d+):(\d+)/.exec(line);
                if (m != null) {
                    return {
                        url: m[2],
                        lineNo: parseInt(m[3]),
                        colNo: parseInt(m[4]),
                        funcName: m[1],
                    };
                }
                return undefined;
            };
        } else if (/firefox|safari/i.test(Browser.navigator.userAgent)) {
            lineNdx = 2;
            matcher = function(line:String):Dynamic {
                var m:Array<String> = /@(.*?):(\d+):(\d+)/.exec(line);
                if (m != null) {
                    return {
                        url: m[1],
                        lineNo: parseInt(m[2]),
                        colNo: parseInt(m[3]),
                    };
                }
                return undefined;
            };
        }
        return function(stack:String):Dynamic {
            if (matcher != null) {
                try {
                    var lines:Array<String> = stack.split('\n');
                    return matcher(lines[lineNdx]);
                } catch (e:Dynamic) {
                    // do nothing
                }
            }
            return undefined;
        };
    }();

    static function setupWorkerSupport():Void {
        function log(data:Dynamic):Void {
            console.log('[Worker]', data); /* eslint-disable-line no-console */
        }
        function lostContext(/* data */):Void {
            addContextLostHTML();
        }
        function jsError(data:Dynamic):Void {
            reportJSError(data.url, data.lineNo, data.colNo, data.msg);
        }
        function jsErrorWithStack(data:Dynamic):Void {
            var errorInfo:Dynamic = parseStack(data.stack);
            if (errorInfo != null) {
                reportJSError(errorInfo.url || data.url, errorInfo.lineNo, errorInfo.colNo, data.msg);
            } else {
                console.error(data.errorMsg); /* eslint-disable-line no-console */
            }
        }
        var handlers:Dynamic = {
            log: log,
            lostContext: lostContext,
            jsError: jsError,
            jsErrorWithStack: jsErrorWithStack,
        };
        var OrigWorker:Dynamic = Worker;
        class WrappedWorker extends OrigWorker {
            public function new(url:String, ...args:Array<Dynamic>) {
                super(url, ...args);
                var listener:Void->Void;
                this.onmessage = function(e:Dynamic):Void {
                    if (e.data.type != '___editor___') {
                        if (listener != null) {
                            listener(e);
                        }
                        return;
                    }
                    var data:Dynamic = e.data.data;
                    var fn:Void->Void = handlers[data.type];
                    if (typeof fn != 'function') {
                        origConsole.error('unknown editor msg:', data.type);
                    } else {
                        fn(data);
                    }
                };
                Object.defineProperty(this, 'onmessage', {
                    get: function():Void->Void {
                        return listener;
                    },
                    set: function(fn:Void->Void):Void {
                        listener = fn;
                    },
                });
            }
        }
        Worker = WrappedWorker;
    }

    static function addContextLostHTML():Void {
        var div:DivElement = Document.createElement('div');
        div.className = 'contextlost';
        div.innerHTML = '<div>Context Lost: Click To Reload</div>';
        div.addEventListener(Event.CLICK, function():Void {
            Browser.window.location.reload();
        });
        Document.body.appendChild(div);
    }

    static function setupLesson( canvas:CanvasElement ):Void {
        // only once
        setupLesson = function():Void {};
        if (canvas != null) {
            canvas.addEventListener(Event.WEBGLCONTEXTLOST, function():Void {
                addContextLostHTML();
            });
            //can't do this because firefox bug - https://bugzilla.mozilla.org/show_bug.cgi?id=1633280
            //canvas.addEventListener(Event.WEBGLCONTEXTRESTORED, function():Void {
            //    window.location.reload();
            //});
        }
        if (isInIFrame()) {
            updateCSSIfInIFrame();
        }
    }

    static function captureJSErrors():Void {
        Browser.window.addEventListener(Event.ERROR, function(e:Event):Void {
            var msg:String = e.message || e.error;
            var url:String = e.filename;
            var lineNo:Int = e.lineno || 1;
            var colNo:Int = e.colno || 1;
            reportJSError(url, lineNo, colNo, msg);
            origConsole.error(e.error);
        });
    }

    static function getBrowser():Dynamic {
        var userAgent:String = Browser.navigator.userAgent;
        var m:Array<String> = userAgent.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
        if (/trident/i.test(m[1])) {
            m = /\brv[ :]+(\d+)/g.exec(userAgent) || [];
            return {
                name: 'IE',
                version: m[1],
            };
        }
        if (m[1] == 'Chrome') {
            var temp:Array<String> = userAgent.match(/\b(OPR|Edge)\/(\d+)/);
            if (temp != null) {
                return {
                    name: temp[1].replace('OPR', 'Opera'),
                    version: temp[2],
                };
            }
        }
        m = m[2] ? [m[1], m[2]] : [Browser.navigator.appName, Browser.navigator.appVersion, '-?'];
        var version:Array<String> = userAgent.match(/version\/(\d+)/i);
        if (version != null) {
            m.splice(1, 1, version[1]);
        }
        return {
            name: m[0],
            version: m[1],
        };
    }

    static function installWebGLLessonSetup():Void {
        CanvasElement.prototype.getContext = (function(oldFn:Void->Void):Void->Void {
            return function():Void {
                var timeoutId:Int = canvasesToTimeoutMap.get(this);
                if (timeoutId != 0) {
                    clearTimeout(timeoutId);
                }
                var type:String = arguments[0];
                var isWebGL1or2:Bool = isWebGLRE.test(type);
                var isWebGL2:Bool = isWebGL2RE.test(type);
                if (isWebGL1or2) {
                    setupLesson(this);
                }
                var args:Array<Dynamic> = [].slice.apply(arguments);
                args[1] = {
                    powerPreference: 'low-power',
                    ...args[1],
                };
                var ctx:Dynamic = oldFn.apply(this, args);
                if (ctx == null) {
                    if (isWebGL2) {
                        // three tries webgl2 then webgl1
                        // so wait 1/2 a second before showing the failure
                        // message. If we get success on the same canvas
                        // we'll cancel this.
                        canvasesToTimeoutMap.set(this, setTimeout(function():Void {
                            canvasesToTimeoutMap.delete(this);
                            showNeedWebGL(this);
                        }, 500));
                    } else {
                        showNeedWebGL(this);
                    }
                }
                return ctx;
            };
        }(CanvasElement.prototype.getContext));
    }

    static function installWebGLDebugContextCreator():Void {
        if (!Browser.window.webglDebugHelper) {
            return;
        }
        var {
            makeDebugContext,
            glFunctionArgToString,
            glEnumToString,
        } = Browser.window.webglDebugHelper;
        // capture GL errors
        CanvasElement.prototype.getContext = (function(oldFn:Void->Void):Void->Void {
            return function():Void {
                var ctx:Dynamic = oldFn.apply(this, arguments);
                if (ctx && ctx.bindTexture) {
                    ctx = makeDebugContext(ctx, {
                        maxDrawCalls: 100,
                        errorFunc: function(err:Dynamic, funcName:String, args:Array<Dynamic>):Void {
                            var numArgs:Int = args.length;
                            var enumedArgs:Array<String> = [].map.call(args, function(arg:Dynamic, ndx:Int):String {
                                var str:String = glFunctionArgToString(funcName, numArgs, ndx, arg);
                                // shorten because of long arrays
                                if (str.length > 200) {
                                    str = str.substring(0, 200) + '...';
                                }
                                return str;
                            });
                            var errorMsg:String = 'WebGL error ' + glEnumToString(err) + ' in ' + funcName + '(' + enumedArgs.join(', ') + ')';
                            var errorInfo:Dynamic = parseStack((new Error()).stack);
                            if (errorInfo != null) {
                                reportJSError(errorInfo.url, errorInfo.lineNo, errorInfo.colNo, errorMsg);
                            } else {
                                console.error(errorMsg); /* eslint-disable-line no-console */
                            }
                        },
                    });
                }
                return ctx;
            };
        }(CanvasElement.prototype.getContext));
    }

    public static function main():Void {
        if (isInEditor()) {
            setupWorkerSupport();
            setupConsole();
            captureJSErrors();
            if (lessonSettings.glDebug !== false) {
                installWebGLDebugContextCreator();
            }
        }
    }
}