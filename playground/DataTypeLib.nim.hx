package three.js.playground;

import js.html.Element;

class DataTypeLib {
    static var typeToLengthLib = [
        // gpu
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
        // cpu
        "String" => 1,
        "Number" => 1,
        "Vector2" => 2,
        "Vector3" => 3,
        "Vector4" => 4,
        "Color" => 3,
        // cpu: other stuff
        "Material" => 1,
        "Object3D" => 1,
        "CodeNode" => 1,
        "Texture" => 1,
        "URL" => 1,
        "node" => 1
    ];

    static var defaultLength = 1;

    static function getLengthFromType(type:String):Int {
        return typeToLengthLib.get(type, defaultLength);
    }

    static function getLengthFromNode(value:Dynamic):Int {
        var type = getTypeFromNode(value);
        return getLengthFromType(type);
    }

    static var typeToColorLib = [
        // gpu
        "string" => '#ff0000',
        "float" => '#eeeeee',
        "bool" => '#0060ff',
        "mat2" => '#d0dc8b',
        "mat3" => '#d0dc8b',
        "mat4" => '#d0dc8b',
        // cpu
        "String" => '#ff0000',
        "Number" => '#eeeeee',
        // cpu: other stuff
        "Material" => '#228b22',
        "Object3D" => '#00a1ff',
        "CodeNode" => '#ff00ff',
        "Texture" => '#ffa500',
        "URL" => '#ff0080'
    ];

    static function getColorFromType(type:String):String {
        return typeToColorLib.get(type, null);
    }

    static function getColorFromNode(value:Dynamic):String {
        var type = getTypeFromNode(value);
        return getColorFromType(type);
    }

    static function getTypeFromNode(value:Dynamic):String {
        if (value) {
            if (value.isMaterial) return 'Material';
            return value.nodeType == 'ArrayBuffer' ? 'URL' : (value.nodeType || getTypeFromValue(value.value));
        }
    }

    static function getTypeFromValue(value:Dynamic):String {
        if (value && value.isScriptableValueNode) value = value.value;
        if (!value) return null;
        if (value.isNode && value.nodeType == 'string') return 'string';
        if (value.isNode && value.nodeType == 'ArrayBuffer') return 'URL';
        for (type in typeToLengthLib.keys().reverse()) {
            if (value['is' + type] == true) return type;
        }
    }

    static function setInputAestheticsFromType(element:Element, type:String):Element {
        element.setInput(getLengthFromType(type));
        var color = getColorFromType(type);
        if (color) {
            element.setInputColor(color);
        }
        return element;
    }

    static function setOutputAestheticsFromNode(element:Element, node:Dynamic):Element {
        if (!node) {
            element.setOutput(0);
            return element;
        }
        return setOutputAestheticsFromType(element, getTypeFromNode(node));
    }

    static function setOutputAestheticsFromType(element:Element, type:String):Element {
        if (!type) {
            element.setOutput(1);
            return element;
        }
        if (type == 'void') {
            element.setOutput(0);
            return element;
        }
        element.setOutput(getLengthFromType(type));
        var color = getColorFromType(type);
        if (color) {
            element.setOutputColor(color);
        }
        return element;
    }
}