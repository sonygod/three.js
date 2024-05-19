Here is the converted Haxe code:
```
//lesson-worker-helper.hx

package three.js.manual.examples.resources;

import js.html.OffscreenCanvas;
import js.html.WebGLRenderingContext;
import js.Browser;

class LessonWorkerHelper {
  static var lessonSettings:Dynamic = {};

  static function isInEditor():Bool {
    return Browser.location.href.substring(0, 4) == 'blob';
  }

  static function sendMessage(data:Dynamic) {
    Browser.window.postMessage({
      type: '__editor__',
      data: data
    });
  }

  static var origConsole:Dynamic = {};

  static function setupConsole() {
    function wrapFunc(obj:Dynamic, logType:String) {
      var origFunc = Reflect.field(obj, logType);
      origConsole[logType] = origFunc;
      return function(args:Array<Dynamic>) {
        origFunc.apply(obj, args);
        sendMessage({
          type: 'log',
          logType: logType,
          msg: args.join(' ')
        });
      };
    }
    Browser.console.log = wrapFunc(Browser.console, 'log');
    Browser.console.warn = wrapFunc(Browser.console, 'warn');
    Browser.console.error = wrapFunc(Browser.console, 'error');
  }

  static var setupLesson:Void->Void = null;

  static function setupWebGLLesson(canvas:OffscreenCanvas) {
    if (canvas != null) {
      canvas.addEventListener('webglcontextlost', function() {
        sendMessage({
          type: 'lostContext'
        });
      });
    }
    setupLesson = function() {};
  }

  static function captureJSErrors() {
    Browser.window.addEventListener('error', function(e) {
      var msg = e.message != null ? e.message : e.error;
      var url = e.filename;
      var lineNo = e.lineno != null ? e.lineno : 1;
      var colNo = e.colno != null ? e.colno : 1;
      sendMessage({
        type: 'jsError',
        lineNo: lineNo,
        colNo: colNo,
        url: url,
        msg: msg
      });
    });
  }

  static var isWebGLRE:EReg = ~/^(webgl|webgl2|experimental-webgl)$/i;

  static function installWebGLLessonSetup() {
    OffscreenCanvas.prototype.getContext = function() {
      var type = arguments[0];
      if (isWebGLRE.match(type)) {
        setupWebGLLesson(this);
      }
      var args:Array<Dynamic> = [];
      for (i in 0...arguments.length) {
        args.push(arguments[i]);
      }
      args[1] = { powerPreference: 'low-power', ...args[1] };
      return this.originalGetContext.apply(this, args);
    };
  }

  static function installWebGLDebugContextCreator() {
    if (Browser.window.webglDebugHelper == null) return;
    var webglDebugHelper = Browser.window.webglDebugHelper;
    var makeDebugContext = webglDebugHelper.makeDebugContext;
    var glFunctionArgToString = webglDebugHelper.glFunctionArgToString;
    var glEnumToString = webglDebugHelper.glEnumToString;

    OffscreenCanvas.prototype.getContext = function() {
      var ctx = this.originalGetContext.apply(this, arguments);
      if (ctx != null && ctx.bindTexture != null) {
        ctx = makeDebugContext(ctx, {
          maxDrawCalls: 100,
          errorFunc: function(err, funcName, args) {
            var numArgs = args.length;
            var enumedArgs:Array<String> = [];
            for (i in 0...args.length) {
              enumedArgs.push(glFunctionArgToString(funcName, numArgs, i, args[i]));
              // shorten because of long arrays
              if (enumedArgs[i].length > 200) {
                enumedArgs[i] = enumedArgs[i].substring(0, 200) + '...';
              }
            }
            var error = new js.Error();
            sendMessage({
              type: 'jsErrorWithStack',
              stack: error.stack,
              msg: '${glEnumToString(err)} in ${funcName}(${enumedArgs.join(', ')})'
            });
          }
        });
      }
      return ctx;
    };
  }

  static function main() {
    installWebGLLessonSetup();
    if (isInEditor()) {
      setupConsole();
      captureJSErrors();
      if (lessonSettings.glDebug != false) {
        installWebGLDebugContextCreator();
      }
    }
  }

  static function __init__() {
    main();
  }
}
```
Note that I've kept the same structure and naming conventions as the original JavaScript code, but with Haxe syntax and semantics. I've also added some Haxe-specific features, such as the `EReg` class for regular expressions, and the `js.Error` class for error handling.