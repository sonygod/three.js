package;

import js.html.WebGLRenderingContext;
import js.html.Window;

/**
 *  WebGL debugging tools.
 */
class WebGLDebugHelper {

	static function makeDebugContext(ctx:WebGLRenderingContext, options:Dynamic = null):WebGLRenderingContext {
		var options = options != null ? options : {};
		var errCtx = options.errCtx != null ? options.errCtx : ctx;
		var onFunc = options.funcFunc;
		var sharedState = options.sharedState != null ? options.sharedState : {numDrawCallsRemaining: options.maxDrawCalls != null ? options.maxDrawCalls : -1, wrappers: {}};
		options.sharedState = sharedState;

		var errorFunc = options.errorFunc != null ? options.errorFunc : function(err:Int, functionName:String, args:Array<Dynamic>) {
			js.Lib.alert("WebGL error " + glEnumToString(err) + " in " + functionName + "(" + glFunctionArgsToString(functionName, args) + ")");
		};

		// Holds booleans for each GL error so after we get the error ourselves
		// we can still return it to the client app.
		var glErrorShadow = {};
		var wrapper = {};

		function removeChecks() {
			for (name in sharedState.wrappers) {
				var pair = sharedState.wrappers[name];
				var wrapper = pair.wrapper;
				var orig = pair.orig;
				for (propertyName in wrapper) {
					if (Type.isFunction(wrapper[propertyName])) {
						wrapper[propertyName] = orig[propertyName].bind(orig);
					}
				}
			}
		}

		function checkMaxDrawCalls() {
			if (sharedState.numDrawCallsRemaining == 0) {
				removeChecks();
			}
			sharedState.numDrawCallsRemaining--;
		}

		function noop() {
		}

		// Makes a function that calls a WebGL function and then calls getError.
		function makeErrorWrapper(ctx:WebGLRenderingContext, functionName:String):Dynamic {
			var check = functionName.substr(0, 4) == "draw" ? checkMaxDrawCalls : noop;
			return function() {
				if (onFunc != null) {
					onFunc(functionName, arguments);
				}
				var result = ctx[functionName].apply(ctx, arguments);
				var err = errCtx.getError();
				if (err != 0) {
					glErrorShadow[err] = true;
					errorFunc(err, functionName, arguments);
				}
				check();
				return result;
			};
		}

		function makeGetExtensionWrapper(ctx:WebGLRenderingContext, wrapped:Dynamic):Dynamic {
			return function() {
				var extensionName = arguments[0];
				var ext = sharedState.wrappers[extensionName];
				if (ext == null) {
					ext = wrapped.apply(ctx, arguments);
					if (ext != null) {
						var origExt = ext;
						ext = makeDebugContext(ext, {errCtx: ctx, sharedState: sharedState, funcFunc: onFunc, errorFunc: errorFunc, maxDrawCalls: options.maxDrawCalls});
						sharedState.wrappers[extensionName] = {wrapper: ext, orig: origExt};
						addEnumsForContext(origExt, extensionName);
					}
				}
				return ext;
			};
		}

		// Make a an object that has a copy of every property of the WebGL context
		// but wraps all functions.
		for (propertyName in ctx) {
			if (Type.isFunction(ctx[propertyName])) {
				if (propertyName != "getExtension") {
					wrapper[propertyName] = makeErrorWrapper(ctx, propertyName);
				} else {
					var wrapped = makeErrorWrapper(ctx, propertyName);
					wrapper[propertyName] = makeGetExtensionWrapper(ctx, wrapped);
				}
			} else {
				wrapper.__defineGetter__(propertyName, function() {
					return ctx[propertyName];
				});
				wrapper.__defineSetter__(propertyName, function(value) {
					ctx[propertyName] = value;
				});
			}
		}

		// Override the getError function with one that returns our saved results.
		if (wrapper.getError != null) {
			wrapper.getError = function() {
				for (err in glErrorShadow) {
					if (glErrorShadow[err]) {
						glErrorShadow[err] = false;
						return err;
					}
				}
				return ctx.NO_ERROR;
			};
		}

		if (wrapper.bindBuffer != null) {
			sharedState.wrappers["webgl"] = {wrapper: wrapper, orig: ctx};
			addEnumsForContext(ctx, ctx.bindBufferBase != null ? "WebGL2" : "WebGL");
		}

		return wrapper;
	}

	static function glFunctionArgsToString(functionName:String, args:Array<Dynamic>):String {
		var argStrs = [];
		var numArgs = args.length;
		for (ii in 0...numArgs) {
			argStrs.push(glFunctionArgToString(functionName, numArgs, ii, args[ii]));
		}
		return argStrs.join(", ");
	}

	static function glFunctionArgToString(functionName:String, numArgs:Int, argumentIndex:Int, value:Dynamic):String {
		var funcInfos = glValidEnumContexts[functionName];
		if (funcInfos != null) {
			var funcInfo = funcInfos[numArgs];
			if (funcInfo != null) {
				var argType = funcInfo[argumentIndex];
				if (argType != null) {
					if (Type.isFunction(argType)) {
						return argType(value);
					} else {
						return glEnumToString(value);
					}
				}
			}
		}
		if (value == null) {
			return "null";
		} else if (value == null) {
			return "undefined";
		} else {
			return value.toString();
		}
	}

	static function glEnumToString(value:Int):String {
		var name = glEnums[value];
		if (name != null) {
			return "gl." + name;
		} else {
			return "/*UNKNOWN WebGL ENUM*/ 0x" + value.toString(16);
		}
	}

	static var glEnums:Map<Int, String> = new Map();
	static var enumStringToValue:Map<String, Int> = new Map();
	static var mappedContextTypes:Map<String, Bool> = new Map();
	static var glValidEnumContexts:Map<String, Dynamic> = new Map();

	static function addEnumsForContext(ctx:WebGLRenderingContext, type:String) {
		if (!mappedContextTypes.exists(type)) {
			mappedContextTypes.set(type, true);
			for (propertyName in ctx) {
				if (Type.isInt(ctx[propertyName])) {
					glEnums.set(ctx[propertyName], propertyName);
					enumStringToValue.set(propertyName, ctx[propertyName]);
				}
			}
		}
	}

	static function enumArrayToString(enums:Array<Dynamic>):String {
		var enumStrings = [];
		if (enums.length > 0) {
			for (i in 0...enums.length) {
				enumStrings.push(glEnumToString(enums[i]));
			}
			return "[" + enumStrings.join(", ") + "]";
		}
		return enumStrings.toString();
	}

	static function makeBitFieldToStringFunc(enums:Array<String>):Dynamic {
		return function(value:Int):String {
			var orResult = 0;
			var orEnums = [];
			for (i in 0...enums.length) {
				var enumValue = enumStringToValue.get(enums[i]);
				if ((value & enumValue) != 0) {
					orResult |= enumValue;
					orEnums.push(glEnumToString(enumValue));
				}
			}
			if (orResult == value) {
				return orEnums.join(" | ");
			} else {
				return glEnumToString(value);
			}
		};
	}

	static var destBufferBitFieldToString = makeBitFieldToStringFunc(["COLOR_BUFFER_BIT", "DEPTH_BUFFER_BIT", "STENCIL_BUFFER_BIT"]);

	static function init() {
		glValidEnumContexts.set("enable", {1: {0: true}});
		glValidEnumContexts.set("disable", {1: {0: true}});
		glValidEnumContexts.set("getParameter", {1: {0: true}});
		glValidEnumContexts.set("drawArrays", {3: {0: true}});
		glValidEnumContexts.set("drawElements", {4: {0: true, 2: true}});
		glValidEnumContexts.set("drawArraysInstanced", {4: {0: true}});
		glValidEnumContexts.set("drawElementsInstanced", {5: {0: true, 2: true}});
		glValidEnumContexts.set("drawRangeElements", {6: {0: true, 4: true}});
		glValidEnumContexts.set("createShader", {1: {0: true}});
		glValidEnumContexts.set("getShaderParameter", {2: {1: true}});
		glValidEnumContexts.set("getProgramParameter", {2: {1: true}});
		glValidEnumContexts.set("getShaderPrecisionFormat", {2: {0: true, 1: true}});
		glValidEnumContexts.set("getVertexAttrib", {2: {1: true}});
		glValidEnumContexts.set("vertexAttribPointer", {6: {2: true}});
		glValidEnumContexts.set("vertexAttribIPointer", {5: {2: true}});
		glValidEnumContexts.set("bindTexture", {2: {0: true}});
		glValidEnumContexts.set("activeTexture", {1: {0: true}});
		glValidEnumContexts.set("getTexParameter", {2: {0: true, 1: true}});
		glValidEnumContexts.set("texParameterf", {3: {0: true, 1: true}});
		glValidEnumContexts.set("texParameteri", {3: {0: true, 1: true, 2: true}});
		glValidEnumContexts.set("texImage2D", {9: {0: true, 2: true, 6: true, 7: true}, 6: {0: true, 2: true, 3: true, 4: true}, 10: {0: true, 2: true, 6: true, 7: true}});
		glValidEnumContexts.set("texImage3D", {10: {0: true, 2: true, 7: true, 8: true}, 11: {0: true, 2: true, 7: true, 8: true}});
		glValidEnumContexts.set("texSubImage2D", {9: {0: true, 6: true, 7: true}, 7: {0: true, 4: true, 5: true}, 10: {0: true, 6: true, 7: true}});
		glValidEnumContexts.set("texSubImage3D", {11: {0: true, 8: true, 9: true}, 12: {0: true, 8: true, 9: true}});
		glValidEnumContexts.set("texStorage2D", {5: {0: true, 2: true}});
		glValidEnumContexts.set("texStorage3D", {6: {0: true, 2: true}});
		glValidEnumContexts.set("copyTexImage2D", {8: {0: true, 2: true}});
		glValidEnumContexts.set("copyTexSubImage2D", {8: {0: true}});
		glValidEnumContexts.set("copyTexSubImage3D", {9: {0: true}});
		glValidEnumContexts.set("generateMipmap", {1: {0: true}});
		glValidEnumContexts.set("compressedTexImage2D", {7: {0: true, 2: true}, 8: {0: true, 2: true}});
		glValidEnumContexts.set("compressedTexSubImage2D", {8: {0: true, 6: true}, 9: {0: true, 6: true}});
		glValidEnumContexts.set("compressedTexImage3D", {8: {0: true, 2: true}, 9: {0: true, 2: true}});
		glValidEnumContexts.set("compressedTexSubImage3D", {9: {0: true, 8: true}, 10: {0: true, 8: true}});
		glValidEnumContexts.set("bindBuffer", {2: {0: true}});
		glValidEnumContexts.set("bufferData", {3: {0: true, 2: true}, 4: {0: true, 2: true}, 5: {0: true, 2: true}});
		glValidEnumContexts.set("bufferSubData", {3: {0: true}, 4: {0: true}, 5: {0: true}});
		glValidEnumContexts.set("copyBufferSubData", {5: {0: true}});
		glValidEnumContexts.set("getBufferParameter", {2: {0: true, 1: true}});
		glValidEnumContexts.set("getBufferSubData", {3: {0: true}, 4: {0: true}, 5: {0: true}});
		glValidEnumContexts.set("pixelStorei", {2: {0: true, 1: true}});
		glValidEnumContexts.set("readPixels", {7: {4: true, 5: true}, 8: {4: true, 5: true}});
		glValidEnumContexts.set("bindRenderbuffer", {2: {0: true}});
		glValidEnumContexts.set("bindFramebuffer", {2: {0: true}});
		glValidEnumContexts.set("blitFramebuffer", {10: {8: destBufferBitFieldToString, 9: true}});
		glValidEnumContexts.set("checkFramebufferStatus", {1: {0: true}});
		glValidEnumContexts.set("framebufferRenderbuffer", {4: {0: true, 1: true, 2: true}});
		glValidEnumContexts.set("framebufferTexture2D", {5: {0: true, 1: true, 2: true}});
		glValidEnumContexts.set("framebufferTextureLayer", {5: {0: true, 1: true}});
		glValidEnumContexts.set("getFramebufferAttachmentParameter", {3: {0: true, 1: true, 2: true}});
		glValidEnumContexts.set("getInternalformatParameter", {3: {0: true, 1: true, 2: true}});
		glValidEnumContexts.set("getRenderbufferParameter", {2: {0: true, 1: true}});
		glValidEnumContexts.set("invalidateFramebuffer", {2: {0: true, 1: enumArrayToString}});
		glValidEnumContexts.set("invalidateSubFramebuffer", {6: {0: true, 1: enumArrayToString}});
		glValidEnumContexts.set("readBuffer", {1: {0: true}});
		glValidEnumContexts.set("renderbufferStorage", {4: {0: true, 1: true}});
		glValidEnumContexts.set("renderbufferStorageMultisample", {5: {0: true, 2: true}});
		glValidEnumContexts.set("clear", {1: {0: destBufferBitFieldToString}});
		glValidEnumContexts.set("depthFunc", {1: {0: true}});
		glValidEnumContexts.set("blendFunc", {2: {0: true, 1: true}});
		glValidEnumContexts.set("blendFuncSeparate", {4: {0: true, 1: true, 2: true, 3: true}});
		glValidEnumContexts.set("blendEquation", {1: {0: true}});
		glValidEnumContexts.set("blendEquationSeparate", {2: {0: true, 1: true}});
		glValidEnumContexts.set("stencilFunc", {3: {0: true}});
		glValidEnumContexts.set("stencilFuncSeparate", {4: {0: true, 1: true}});
		glValidEnumContexts.set("stencilMaskSeparate", {2: {0: true}});
		glValidEnumContexts.set("stencilOp", {3: {0: true, 1: true, 2: true}});
		glValidEnumContexts.set("stencilOpSeparate", {4: {0: true, 1: true, 2: true, 3: true}});
		glValidEnumContexts.set("cullFace", {1: {0: true}});
		glValidEnumContexts.set("frontFace", {1: {0: true}});
		glValidEnumContexts.set("drawArraysInstancedANGLE", {4: {0: true}});
		glValidEnumContexts.set("drawElementsInstancedANGLE", {5: {0: true, 2: true}});
		glValidEnumContexts.set("blendEquationEXT", {1: {0: true}});
		glValidEnumContexts.set("drawBuffersWebGL", {1: {0: enumArrayToString}});
		glValidEnumContexts.set("drawBuffers", {1: {0: enumArrayToString}});
		glValidEnumContexts.set("clearBufferfv", {4: {0: true}, 5: {0: true}});
		glValidEnumContexts.set("clearBufferiv", {4: {0: true}, 5: {0: true}});
		glValidEnumContexts.set("clearBufferuiv", {4: {0: true}, 5: {0: true}});
		glValidEnumContexts.set("clearBufferfi", {4: {0: true}});
		glValidEnumContexts.set("beginQuery", {2: {0: true}});
		glValidEnumContexts.set("endQuery", {1: {0: true}});
		glValidEnumContexts.set("getQuery", {2: {0: true, 1: true}});
		glValidEnumContexts.set("getQueryParameter", {2: {1: true}});
		glValidEnumContexts.set("samplerParameteri", {3: {1: true}});
		glValidEnumContexts.set("samplerParameterf", {3: {1: true}});
		glValidEnumContexts.set("getSamplerParameter", {2: {1: true}});
		glValidEnumContexts.set("clientWaitSync", {3: {1: makeBitFieldToStringFunc(["SYNC_FLUSH_COMMANDS_BIT"])}});
		glValidEnumContexts.set("fenceSync", {2: {0: true}});
		glValidEnumContexts.set("getSyncParameter", {2: {1: true}});
		glValidEnumContexts.set("bindTransformFeedback", {2: {0: true}});
		glValidEnumContexts.set("beginTransformFeedback", {1: {0: true}});
		glValidEnumContexts.set("bindBufferBase", {3: {0: true}});
		glValidEnumContexts.set("bindBufferRange", {5: {0: true}});
		glValidEnumContexts.set("getIndexedParameter", {2: {0: true}});
		glValidEnumContexts.set("getActiveUniforms", {3: {2: true}});
		glValidEnumContexts.set("getActiveUniformBlockParameter", {3: {2: true}});
	}

}

class WebGLDebugUtils {

	static function makeDebugContext(ctx:WebGLRenderingContext, options:Dynamic = null):WebGLRenderingContext {
		return WebGLDebugHelper.makeDebugContext(ctx, options);
	}

	static function glFunctionArgsToString(functionName:String, args:Array<Dynamic>):String {
		return WebGLDebugHelper.glFunctionArgsToString(functionName, args);
	}

	static function glFunctionArgToString(functionName:String, numArgs:Int, argumentIndex:Int, value:Dynamic):String {
		return WebGLDebugHelper.glFunctionArgToString(functionName, numArgs, argumentIndex, value);
	}

	static function glEnumToString(value:Int):String {
		return WebGLDebugHelper.glEnumToString(value);
	}

	static function init() {
		WebGLDebugHelper.init();
	}

}