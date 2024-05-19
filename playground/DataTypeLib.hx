package three.js.playground;

class DataTypeLib {
  private static var typeToLengthLib:Map<String, Int> = [
    "string" => 1,
    "float" => 1,
    "bool" => 1,
    "vec2" => 2,
    "vec3" => 3,
    "vec4" => 4,
    "color" => 3,
    "mat2" => 1,
    "mat3" => 1,
    "mat4" => 1,
    "String" => 1,
    "Number" => 1,
    "Vector2" => 2,
    "Vector3" => 3,
    "Vector4" => 4,
    "Color" => 3,
    "Material" => 1,
    "Object3D" => 1,
    "CodeNode" => 1,
    "Texture" => 1,
    "URL" => 1,
    "node" => 1
  ];

  public static var defaultLength:Int = 1;

  public static function getLengthFromType(type:String):Int {
    return typeToLengthLib.exists(type) ? typeToLengthLib[type] : defaultLength;
  }

  public static function getLengthFromNode(value:Dynamic):Int {
    var type:String = getTypeFromNode(value);
    return getLengthFromType(type);
  }

  private static var typeToColorLib:Map<String, String> = [
    "string" => "#ff0000",
    "float" => "#eeeeee",
    "bool" => "#0060ff",
    "mat2" => "#d0dc8b",
    "mat3" => "#d0dc8b",
    "mat4" => "#d0dc8b",
    "String" => "#ff0000",
    "Number" => "#eeeeee",
    "Material" => "#228b22",
    "Object3D" => "#00a1ff",
    "CodeNode" => "#ff00ff",
    "Texture" => "#ffa500",
    "URL" => "#ff0080"
  ];

  public static function getColorFromType(type:String):Null<String> {
    return typeToColorLib.exists(type) ? typeToColorLib[type] : null;
  }

  public static function getColorFromNode(value:Dynamic):Null<String> {
    var type:String = getTypeFromNode(value);
    return getColorFromType(type);
  }

  private static function getTypeFromNode(value:Dynamic):String {
    if (value != null) {
      if (value.isMaterial) return "Material";
      return value.nodeType == "ArrayBuffer" ? "URL" : (value.nodeType != null ? value.nodeType : getTypeFromValue(value.value));
    }
    return null;
  }

  private static function getTypeFromValue(value:Dynamic):String {
    if (value != null) {
      if (value.isScriptableValueNode) value = value.value;
      if (value != null) {
        if (value.isNode && value.nodeType == "string") return "string";
        if (value.isNode && value.nodeType == "ArrayBuffer") return "URL";
        for (type in typeToLengthLib.keys()) {
          if (Reflect.hasField(value, "is" + type) && Reflect.field(value, "is" + type) == true) return type;
        }
      }
    }
    return null;
  }

  public static function setInputAestheticsFromType(element:Dynamic, type:String):Dynamic {
    element.setInput(getLengthFromType(type));
    var color:String = getColorFromType(type);
    if (color != null) element.setInputColor(color);
    return element;
  }

  public static function setOutputAestheticsFromNode(element:Dynamic, node:Dynamic):Dynamic {
    if (node == null) {
      element.setOutput(0);
      return element;
    }
    return setOutputAestheticsFromType(element, getTypeFromNode(node));
  }

  public static function setOutputAestheticsFromType(element:Dynamic, type:String):Dynamic {
    if (type == null) {
      element.setOutput(1);
      return element;
    }
    if (type == "void") {
      element.setOutput(0);
      return element;
    }
    element.setOutput(getLengthFromType(type));
    var color:String = getColorFromType(type);
    if (color != null) element.setOutputColor(color);
    return element;
  }
}