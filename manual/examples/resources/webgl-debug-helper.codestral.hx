// Haxe version of webgl-debug-helper.js

// ... (copyright notice)

class WebGLDebugHelper {

  static var mappedContextTypes:Map<String, Bool> = new Map<String, Bool>();
  static var glEnums:Map<Int, String> = new Map<Int, String>();
  static var enumStringToValue:Map<String, Int> = new Map<String, Int>();

  static function addEnumsForContext(ctx:WebGLRenderingContext, type:String):Void {
    if (!mappedContextTypes.exists(type)) {
      mappedContextTypes.set(type, true);
      for (field in Reflect.fields(ctx)) {
        var value = Reflect.field(ctx, field);
        if (Std.is(value, Int)) {
          glEnums.set(value, field);
          enumStringToValue.set(field, value);
        }
      }
    }
  }

  static function enumArrayToString(enums:Array<Int>):String {
    var enumStrings:Array<String> = [];
    if (enums.length > 0) {
      for (i in 0...enums.length) {
        enumStrings.push(WebGLDebugHelper.glEnumToString(enums[i]));
      }
      return '[' + enumStrings.join(', ') + ']';
    }
    return enumStrings.toString();
  }

  static function makeBitFieldToStringFunc(enums:Array<String>):Dynamic -> String {
    return function(value:Int):String {
      var orResult:Int = 0;
      var orEnums:Array<String> = [];
      for (i in 0...enums.length) {
        var enumValue:Int = enumStringToValue.get(enums[i]);
        if ((value & enumValue) != 0) {
          orResult |= enumValue;
          orEnums.push(WebGLDebugHelper.glEnumToString(enumValue));
        }
      }
      if (orResult == value) {
        return orEnums.join(' | ');
      } else {
        return WebGLDebugHelper.glEnumToString(value);
      }
    };
  }

  static var destBufferBitFieldToString:Dynamic -> String = makeBitFieldToStringFunc(['COLOR_BUFFER_BIT', 'DEPTH_BUFFER_BIT', 'STENCIL_BUFFER_BIT']);

  // ... (glValidEnumContexts object)

  static function glEnumToString(value:Int):String {
    var name:String = glEnums.get(value);
    if (name != null) {
      return "gl." + name;
    } else {
      return "/*UNKNOWN WebGL ENUM*/ 0x" + value.toString(16);
    }
  }

  static function glFunctionArgToString(functionName:String, numArgs:Int, argumentIndex:Int, value:Dynamic):String {
    var funcInfos:Map<Int, Map<Int, Dynamic>> = glValidEnumContexts.get(functionName);
    if (funcInfos != null) {
      var funcInfo:Map<Int, Dynamic> = funcInfos.get(numArgs);
      if (funcInfo != null) {
        var argType:Dynamic = funcInfo.get(argumentIndex);
        if (argType != null) {
          if (Std.is(argType, Function)) {
            return argType(value);
          } else {
            return WebGLDebugHelper.glEnumToString(value);
          }
        }
      }
    }
    if (value == null) {
      return 'null';
    } else if (value == undefined) {
      return 'undefined';
    } else {
      return value.toString();
    }
  }

  static function glFunctionArgsToString(functionName:String, args:Array<Dynamic>):String {
    var argStrs:Array<String> = [];
    var numArgs:Int = args.length;
    for (ii in 0...numArgs) {
      argStrs.push(WebGLDebugHelper.glFunctionArgToString(functionName, numArgs, ii, args[ii]));
    }
    return argStrs.join(', ');
  }

  // ... (makePropertyWrapper, makeDebugContext, makeErrorWrapper, makeGetExtensionWrapper functions)

}