class DataTypeLib {
    public static var typeToLengthLib:haxe.ds.StringMap<Int> = new haxe.ds.StringMap<Int>();
    public static var defaultLength:Int = 1;
    public static var typeToColorLib:haxe.ds.StringMap<String> = new haxe.ds.StringMap<String>();

    static function init() {
        // gpu
        typeToLengthLib.set("string", 1);
        typeToLengthLib.set("float", 1);
        typeToLengthLib.set("bool", 1);
        typeToLengthLib.set("vec2", 2);
        typeToLengthLib.set("vec3", 3);
        typeToLengthLib.set("vec4", 4);
        typeToLengthLib.set("color", 3);
        typeToLengthLib.set("mat2", 1);
        typeToLengthLib.set("mat3", 1);
        typeToLengthLib.set("mat4", 1);
        // cpu
        typeToLengthLib.set("String", 1);
        typeToLengthLib.set("Number", 1);
        typeToLengthLib.set("Vector2", 2);
        typeToLengthLib.set("Vector3", 3);
        typeToLengthLib.set("Vector4", 4);
        typeToLengthLib.set("Color", 3);
        // cpu: other stuff
        typeToLengthLib.set("Material", 1);
        typeToLengthLib.set("Object3D", 1);
        typeToLengthLib.set("CodeNode", 1);
        typeToLengthLib.set("Texture", 1);
        typeToLengthLib.set("URL", 1);
        typeToLengthLib.set("node", 1);

        // gpu
        typeToColorLib.set("string", "#ff0000");
        typeToColorLib.set("float", "#eeeeee");
        typeToColorLib.set("bool", "#0060ff");
        typeToColorLib.set("mat2", "#d0dc8b");
        typeToColorLib.set("mat3", "#d0dc8b");
        typeToColorLib.set("mat4", "#d0dc8b");
        // cpu
        typeToColorLib.set("String", "#ff0000");
        typeToColorLib.set("Number", "#eeeeee");
        // cpu: other stuff
        typeToColorLib.set("Material", "#228b22");
        typeToColorLib.set("Object3D", "#00a1ff");
        typeToColorLib.set("CodeNode", "#ff00ff");
        typeToColorLib.set("Texture", "#ffa500");
        typeToColorLib.set("URL", "#ff0080");
    }

    public static function getLengthFromType(type:String):Int {
        return typeToLengthLib.exists(type) ? typeToLengthLib.get(type) : defaultLength;
    }

    public static function getColorFromType(type:String):String {
        return typeToColorLib.exists(type) ? typeToColorLib.get(type) : null;
    }

    public static function getTypeFromNode(value:Dynamic):String {
        if (value != null) {
            if (Std.is(value, "isMaterial")) return "Material";
            return Std.is(value, "nodeType") && value.nodeType == "ArrayBuffer" ? "URL" : (value.nodeType != null ? value.nodeType : getTypeFromValue(Std.is(value, "value") ? value.value : null));
        }
        return null;
    }

    public static function getTypeFromValue(value:Dynamic):String {
        if (value != null) {
            if (Std.is(value, "isScriptableValueNode")) value = value.value;
            if (Std.is(value, "isNode") && value.nodeType == "string") return "string";
            if (Std.is(value, "isNode") && value.nodeType == "ArrayBuffer") return "URL";
            for (type in typeToLengthLib.keys()) {
                if (Std.is(value, "is" + type)) return type;
            }
        }
        return null;
    }

    public static function setInputAestheticsFromType(element:Dynamic, type:String):Dynamic {
        element.setInput(getLengthFromType(type));
        var color = getColorFromType(type);
        if (color != null) {
            element.setInputColor(color);
        }
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
        var color = getColorFromType(type);
        if (color != null) {
            element.setOutputColor(color);
        }
        return element;
    }
}