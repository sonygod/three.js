class DataTypeLib {
    static var typeToLengthLib:Map<String, Int> = {
        // gpu
        'string': 1,
        'float': 1,
        'bool': 1,
        'vec2': 2,
        'vec3': 3,
        'vec4': 4,
        'color': 3,
        'mat2': 1,
        'mat3': 1,
        'mat4': 1,
        // cpu
        'String': 1,
        'Number': 1,
        'Vector2': 2,
        'Vector3': 3,
        'Vector4': 4,
        'Color': 3,
        // cpu: other stuff
        'Material': 1,
        'Object3D': 1,
        'CodeNode': 1,
        'Texture': 1,
        'URL': 1,
        'node': 1
    };

    static var defaultLength:Int = 1;

    static function getLengthFromType(type:String):Int {
        return typeToLengthLib[type] ?? defaultLength;
    }

    static function getLengthFromNode(value:Dynamic):Int {
        var type = getTypeFromNode(value);
        return getLengthFromType(type);
    }

    static var typeToColorLib:Map<String, String> = {
        // gpu
        'string': '#ff0000',
        'float': '#eeeeee',
        'bool': '#0060ff',
        'mat2': '#d0dc8b',
        'mat3': '#d0dc8b',
        'mat4': '#d0dc8b',
        // cpu
        'String': '#ff0000',
        'Number': '#eeeeee',
        // cpu: other stuff
        'Material': '#228b22',
        'Object3D': '#00a1ff',
        'CodeNode': '#ff00ff',
        'Texture': '#ffa500',
        'URL': '#ff0080'
    };

    static function getColorFromType(type:String):String {
        return typeToColorLib[type] ?? null;
    }

    static function getColorFromNode(value:Dynamic):String {
        var type = getTypeFromNode(value);
        return getColorFromType(type);
    }

    static function getTypeFromNode(value:Dynamic):String {
        if (value != null) {
            if (value.isMaterial) return 'Material';
            return value.nodeType == 'ArrayBuffer' ? 'URL' : (value.nodeType ?? getTypeFromValue(value.value));
        }
        return null;
    }

    static function getTypeFromValue(value:Dynamic):String {
        if (value != null) {
            if (value.isScriptableValueNode) value = value.value;
            if (value.isNode && value.nodeType == 'string') return 'string';
            if (value.isNode && value.nodeType == 'ArrayBuffer') return 'URL';
            for (type in Reflect.fields(typeToLengthLib).reverse()) {
                if (value['is' + type] == true) return type;
            }
        }
        return null;
    }

    static function setInputAestheticsFromType(element:Dynamic, type:String):Dynamic {
        element.setInput(getLengthFromType(type));
        var color = getColorFromType(type);
        if (color != null) {
            element.setInputColor(color);
        }
        return element;
    }

    static function setOutputAestheticsFromNode(element:Dynamic, node:Dynamic):Dynamic {
        if (node == null) {
            element.setOutput(0);
            return element;
        }
        return setOutputAestheticsFromType(element, getTypeFromNode(node));
    }

    static function setOutputAestheticsFromType(element:Dynamic, type:String):Dynamic {
        if (type == null) {
            element.setOutput(1);
            return element;
        }
        if (type == 'void') {
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