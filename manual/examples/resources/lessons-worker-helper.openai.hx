/*
 * Copyright 2019, Gregg Tavares.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Gregg Tavares. nor the names of his
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import js.html.OffscreenCanvas;
import js.html.Window;
import js.Browser.console;

class WorkerHelper {
	static var lessonSettings:Dynamic = js.Browser.window.lessonSettings || {};

	static function isInEditor():Bool {
		return js.Browser.window.location.href.substring(0, 4) == 'blob';
	}

	static function sendMessage(data:Dynamic) {
		js.Browser.window.postMessage({
			type: '__editor__',
			data: data,
		});
	}

	static function setupConsole() {
		var origConsole = {};
		function wrapFunc(obj:Dynamic, logType:String) {
			var origFunc = Reflect.field(obj, logType);
			origConsole[logType] = origFunc;
			return function(...args:Array<Dynamic>) {
				Reflect.callMethod(obj, logType, args);
				sendMessage({
					type: 'log',
					logType: logType,
					msg: args.join(' '),
				});
			};
		}
		js.Browser.console.log = wrapFunc(js.Browser.console, 'log');
		js.Browser.console.warn = wrapFunc(js.Browser.console, 'warn');
		js.Browser.console.error = wrapFunc(js.Browser.console, 'error');
	}

	static function setupLesson(canvas:OffscreenCanvas) {
		// only once
		setupLesson = function() {};
		if (canvas != null) {
			canvas.addEventListener('webglcontextlost', function() {
				sendMessage({
					type: 'lostContext',
				});
			});
		}
	}

	static function captureJSErrors() {
		js.Browser.window.addEventListener('error', function(e:ErrorEvent) {
			var msg = e.message || e.error;
			var url = e.filename;
			var lineNo = e.lineno || 1;
			var colNo = e.colno || 1;
			sendMessage({
				type: 'jsError',
				lineNo: lineNo,
				colNo: colNo,
				url: url,
				msg: msg,
			});
		});
	}

	static function installWebGLLessonSetup() {
		var isWebGLRE = ~/^(webgl|webgl2|experimental-webgl)$/i;
		OffscreenCanvas.prototype.getContext = (function(oldFn:Dynamic) {
			return function() {
				var type = arguments[0];
				var isWebGL = isWebGLRE.match(type);
				if (isWebGL) {
					setupLesson(this);
				}
				var args = [].slice.apply(arguments);
				args[1] = {
					powerPreference: 'low-power',
					...args[1],
				};
				return oldFn.apply(this, args);
			};
		}(OffscreenCanvas.prototype.getContext));
	}

	static function installWebGLDebugContextCreator() {
		if (!js.Browser.window.webglDebugHelper) {
			return;
		}
		var {
			makeDebugContext,
			glFunctionArgToString,
			glEnumToString,
		} = js.Browser.window.webglDebugHelper;

		OffscreenCanvas.prototype.getContext = (function(oldFn:Dynamic) {
			return function() {
				var ctx = oldFn.apply(this, arguments);
				if (ctx && ctx.bindTexture) {
					ctx = makeDebugContext(ctx, {
						maxDrawCalls: 100,
						errorFunc: function(err, funcName, args) {
							var numArgs = args.length;
							var enumedArgs = [].map.call(args, function(arg, ndx) {
								var str = glFunctionArgToString(funcName, numArgs, ndx, arg);
								if (str.length > 200) {
									str = str.substring(0, 200) + '...';
								}
								return str;
							});
							var error = new js.Error();
							sendMessage({
								type: 'jsErrorWithStack',
								stack: error.stack,
								msg: '${glEnumToString(err)} in ${funcName}(${enumedArgs.join(', ')})',
							});
						},
					});
				}
				return ctx;
			};
		}(OffscreenCanvas.prototype.getContext));
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

	static function init() {
		main();
	}

static function main() {
	WorkerHelper.init();
}