import js.Node;

class TypeToLengthLib {
    static var props = {
        get_string() { return 1; }
        get_float() { return 1; }
        get_bool() { return 1; }
        get_vec2() { return 2; }
        get_vec3() { return 3; }
        get_vec4() { return 4; }
        get_color() { return 3; }
        get_mat2() { return 1; }
        get_mat3() { return 1; }
        get_mat4() { return 1; }
        get_String() { return 1; }
        get_Number() { return 1; }
        get_Vector2() { return 2; }
        get_Vector3() { return 3; }
        get_Vector4() { return 4; }
        get_Color() { return 3; }
        get_Material() { return 1; }
        get_Object3D() { return 1; }
        get_CodeNode() { return 1; }
        get_Texture() { return 1; }
        get_URL() { return 1; }
        get_node() { return 1; }
    }
}

class DefaultLength {
    static var props = {
        get_default() { return 1; }
    }
}

function getLengthFromType(type:String) -> Int {
    return TypeToLengthLib.get(type) ?? DefaultLength.default;
}

function getLengthFromNode(value:Dynamic) -> Int {
    var type = getTypeFromNode(value);
    return getLengthFromType(type);
}

class TypeToColorLib {
    static var props = {
        get_string() { return "#ff0000"; }
        get_float() { return "#eeeeee"; }
        get_bool() { return "#0060ff"; }
        get_mat2() { return "#d0dc8b"; }
        get_mat3() { return "#d0dc8b"; }
        get_mat4() { return "#d0dc8b"; }
        get_String() { return "#ff0000"; }
        get_Number() { return "#eeeeee"; }
        get_Material() { return "#228b22"; }
        get_Object3D() { return "#00a1ff"; }
        get_CodeNode() { return "#ff00ff"; }
        get_Texture() { return "#ffa500"; }
        get_URL() { return "#ff0080"; }
    }
}

function getColorFromType(type:String) -> String ? null {
    return TypeToColorLib.get(type) ?? null;
}

function getColorFromNode(value:Dynamic) -> String ? null {
    var type = getTypeFromNode(value);
    return getColorFromType(type);
}

function getTypeFromNode(value:Dynamic) -> String {
    if (value == null) {
        return "";
    }

    if (value.isMaterial != null) {
        return "Material";
    }

    if (value.nodeType != null) {
        if (value.nodeType == "ArrayBuffer") {
            return "URL";
        } else {
            return value.nodeType;
        }
    }

    return getTypeFromValue(value.value);
}

function getTypeFromValue(value:Dynamic) -> String {
    if (value == null) {
        return "";
    }

    if (value.isScriptableValueNode != null) {
        value = value.value;
    }

    if (value.nodeType != null) {
        if (value.nodeType == "string") {
            return "string";
        } else if (value.nodeType == "ArrayBuffer") {
            return "URL";
        }
    }

    for (type in TypeToLengthLib.fields) {
        if (Reflect.hasField(value, "is" + type)) {
            var isType = Reflect.field(value, "is" + type);
            if (isType != null && isType == true) {
                return type;
            }
        }
    }

    return "";
}

function setInputAestheticsFromType(element:Dynamic, type:String) -> Dynamic {
    element.setInput(getLengthFromType(type));

    var color = getColorFromType(type);
    if (color != null) {
        element.setInputColor(color);
    }

    return element;
}

function setOutputAestheticsFromNode(element:Dynamic, node:Dynamic) -> Dynamic {
    if (node == null) {
        element.setOutput(0);
        return element;
    }

    return setOutputAestheticsFromType(element, getTypeFromNode(node));
}

function setOutputAestheticsFromType(element:Dynamic, type:String) -> Dynamic {
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