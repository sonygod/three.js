package webgl;

import haxe.ds.StringMap;

class WebGLDebugHelper {
    static var mappedContextTypes = new StringMap<Bool>();
    static var glEnums = new StringMap<Int>();
    static var enumStringToValue = new StringMap<Int>();

    static function addEnumsForContext(ctx: WebGLRenderingContext, type: String) {
        if (!mappedContextTypes.exists(type)) {
            mappedContextTypes.set(type, true);
            for (fieldName in Reflect.fields(ctx)) {
                if (Reflect.field(ctx, fieldName) is Int) {
                    glEnums.set(Reflect.field(ctx, fieldName), fieldName);
                    enumStringToValue.set(fieldName, Reflect.field(ctx, fieldName));
                }
            }
        }
    }

    static function enumArrayToString(enums: Array<Int>): String {
        var enumStrings = [];
        if (enums.length > 0) {
            for (i in 0...enums.length) {
                enums[i] = glEnumToString(enums[i]);
            }
            return '[' + enumStrings.join(', ') + ']';
        }
        return enumStrings.toString();
    }

    static function makeBitFieldToStringFunc(enums: Array<String>): String -> String {
        return function(value: Int): String {
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
                return orEnums.join(' | ');
            } else {
                return glEnumToString(value);
            }
        };
    }

    static var destBufferBitFieldToString = makeBitFieldToStringFunc(['COLOR_BUFFER_BIT', 'DEPTH_BUFFER_BIT', 'STENCIL_BUFFER_BIT']);

    static var glValidEnumContexts = {
        'enable': {1: {0: true}},
        'disable': {1: {0: true}},
        'getParameter': {1: {0: true}},
        // ... (rest of the enum contexts)
    };

    static function glEnumToString(value: Int): String {
        var name = glEnums.get(value);
        return if (name != null) 'gl.$name' else '/*UNKNOWN WebGL ENUM*/ 0x${StringTools.hex(value, 8)}';
    }

    static function glFunctionArgToString(functionName: String, numArgs: Int, argumentIndex: Int, value: Dynamic): String {
        var funcInfos = glValidEnumContexts[functionName];
        if (funcInfos != null) {
            var funcInfo = funcInfos[numArgs];
            if (funcInfo != null) {
                var argType = funcInfo[argumentIndex];
                if (argType) {
                    if (Reflect.isFunction(argType)) {
                        return argType(value);
                    } else {
                        return glEnumToString(value);
                    }
                }
            }
        }
        if (value == null) {
            return 'null';
        } else if (value == undefined) {
            return 'undefined';
        } else {
            return Std.string(value);
        }
    }

    static function glFunctionArgsToString(functionName: String, args: Array<Dynamic>): String {
        var argStrs = [];
        for (ii in 0...args.length) {
            argStrs.push(glFunctionArgToString(functionName, args.length, ii, args[ii]));
        }
        return argStrs.join(', ');
    }

    static function makePropertyWrapper(wrapper: Dynamic, original: Dynamic, propertyName: String) {
        Reflect.setField(wrapper, propertyName, function() {
            return Reflect.field(original, propertyName);
        });
        Reflect.setField(wrapper, propertyName, function(value: Dynamic) {
            Reflect.setField(original, propertyName, value);
        });
    }

    static function makeDebugContext(ctx: WebGLRenderingContext, ?options: { onErrorFunc: String -> Void, onFunc: String -> Void, sharedState: { numDrawCallsRemaining: Int, wrappers: StringMap<{ wrapper: Dynamic, orig: Dynamic }> } }): Dynamic {
        options = options != null ? options : {};
        var errCtx = options.errCtx != null ? options.errCtx : ctx;
        var onFunc = options.onFunc;
        var sharedState = options.sharedState != null ? options.sharedState : { numDrawCallsRemaining: -1, wrappers: new StringMap<{ wrapper: Dynamic, orig: Dynamic }>() };
        options.sharedState = sharedState;

        var errorFunc = options.onErrorFunc != null ? options.onErrorFunc : function(err: Int, functionName: String, args: Array<Dynamic>) {
            trace('WebGL error ${glEnumToString(err)} in ${functionName}(${glFunctionArgsToString(functionName, args)})');
        };

        var glErrorShadow = {};
        var wrapper = {};

        function removeChecks() {
            for (name in sharedState.wrappers.keys()) {
                var pair = sharedState.wrappers.get(name);
                var wrapper = pair.wrapper;
                var orig = pair.orig;
                for (propertyName in Reflect.fields(wrapper)) {
                    if (Reflect.isFunction(wrapper[propertyName])) {
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

        function makeErrorWrapper(ctx: WebGLRenderingContext, functionName: String) {
            var check = functionName.substring(0, 4) == 'draw' ? checkMaxDrawCalls : function() {};
            return function() {
                if (onFunc != null) {
                    onFunc(functionName, args);
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

        function makeGetExtensionWrapper(ctx: WebGLRenderingContext, wrapped: WebGLRenderingContext) {
            return function() {
                var extensionName = arguments[0];
                var ext = sharedState.wrappers.get(extensionName);
                if (ext == null) {
                    ext = wrapped.apply(ctx, arguments);
                    if (ext != null) {
                        var origExt = ext;
                        ext = makeDebugContext(ext, { errCtx: ctx });
                        sharedState.wrappers.set(extensionName, { wrapper: ext, orig: origExt });
                        addEnumsForContext(origExt, extensionName);
                    }
                }
                return ext;
            };
        }

        for (propertyName in Reflect.fields(ctx)) {
            if (Reflect.isFunction(ctx[propertyName])) {
                if (propertyName != 'getExtension') {
                    wrapper[propertyName] = makeErrorWrapper(ctx, propertyName);
                } else {
                    var wrapped = makeErrorWrapper(ctx, propertyName);
                    wrapper[propertyName] = makeGetExtensionWrapper(ctx, wrapped);
                }
            } else {
                makePropertyWrapper(wrapper, ctx, propertyName);
            }
        }

        wrapper.getError = function() {
            for (err in glErrorShadow.keys()) {
                if (glErrorShadow[err]) {
                    glErrorShadow[err] = false;
                    return err;
                }
            }
            return ctx.NO_ERROR;
        };

        if (wrapper.bindBuffer != null) {
            sharedState.wrappers.set('webgl', { wrapper: wrapper, orig: ctx });
            addEnumsForContext(ctx, ctx.bindBufferBase != null ? 'WebGL2' : 'WebGL');
        }

        return wrapper;
    }
}