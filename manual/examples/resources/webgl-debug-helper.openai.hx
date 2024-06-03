package webgl.debug;

import haxe.webgl.WebGLContext;

class WebGLDebugHelper {
  private static var mappedContextTypes:Map<String, Bool> = new Map();
  private static var glEnums:Map<Int, String> = new Map();
  private static var enumStringToValue:Map<String, Int> = new Map();

  public static function addEnumsForContext(ctx:WebGLContext, type:String) {
    if (!mappedContextTypes.exists(type)) {
      mappedContextTypes[type] = true;
      for (field in ctx.fields()) {
        if (Type.typeof(ctx.field(field)) == TInt) {
          glEnums.set(ctx.field(field), field);
          enumStringToValue.set(field, ctx.field(field));
        }
      }
    }
  }

  private static function enumArrayToString(enums:Array<Int>) {
    var enumStrings:Array<String> = [];
    for (i in 0...enums.length) {
      enumStrings.push(glEnumToString(enums[i]));
    }
    return enumStrings.join(', ');
  }

  private static function makeBitFieldToStringFunc(enums:Array<String>) {
    return function(value:Int) {
      var orResult:Int = 0;
      var orEnums:Array<String> = [];
      for (i in 0...enums.length) {
        var enumValue:Int = enumStringToValue.get(enums[i]);
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
    }
  }

  // ... other functions ...

  public static function makeDebugContext(ctx:WebGLContext, ?options:WebGLDebugOptions) {
    options = options != null ? options : {};
    var errCtx:WebGLContext = options.errCtx != null ? options.errCtx : ctx;
    var onFunc:Void->Void = options.funcFunc;
    var sharedState:WebGLDebugSharedState = options.sharedState != null ? options.sharedState : {
      numDrawCallsRemaining: options.maxDrawCalls != null ? options.maxDrawCalls : -1,
      wrappers: {}
    };
    options.sharedState = sharedState;

    var errorFunc:Void->Void = options.errorFunc != null ? options.errorFunc : function(err:Int, functionName:String, args:Array<Dynamic>) {
      trace('WebGL error ' + glEnumToString(err) + ' in ' + functionName + '(' + glFunctionArgsToString(functionName, args) + ')');
    };

    // ... rest of the implementation ...
  }

  public static function glEnumToString(value:Int) {
    var name:String = glEnums.get(value);
    return name != null ? 'gl.' + name : '/*UNKNOWN WebGL ENUM*/ 0x' + StringTools.hex(value, 6);
  }

  // ... other functions ...
}