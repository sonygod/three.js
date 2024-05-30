import haxe.Serializer;
import haxe.Unserializer;

function getCacheKey(object:Dynamic, force:Bool = false):String {
    var cacheKey = '{';

    if (Reflect.hasField(object, 'isNode') && $type(object.isNode) == Bool && object.isNode) {
        cacheKey += object.id;
    }

    for (prop in Reflect.fields(object)) {
        if (prop.startsWith('_')) continue;
        var childNode = Reflect.field(object, prop);
        if ($type(childNode) == Array) {
            for (child in childNode) {
                if (Reflect.hasField(child, 'getCacheKey') && $type(child.getCacheKey) == FFun) {
                    cacheKey += ',' + prop + ':' + child.getCacheKey(force);
                }
            }
        } else if (Reflect.hasField(childNode, 'isNode') && $type(childNode.isNode) == Bool && childNode.isNode) {
            cacheKey += ',' + prop + ':' + getCacheKey(childNode, force);
        } else if ($type(childNode) == Object) {
            for (subProp in Reflect.fields(childNode)) {
                var subChild = Reflect.field(childNode, subProp);
                if (Reflect.hasField(subChild, 'isNode') && $type(subChild.isNode) == Bool && subChild.isNode) {
                    cacheKey += ',' + prop + ':' + getCacheKey(subChild, force);
                } else if (Reflect.hasField(subChild, 'toJSON') && $type(subChild.toJSON) == FFun) {
                    cacheKey += ',' + prop + ':' + getCacheKey(subChild, true);
                }
            }
        }
    }

    cacheKey += '}';
    return cacheKey;
}

class ValueType {
    public static get(value:Dynamic):String {
        if (value == null) return null;
        var type = $type(value);
        if (Reflect.hasField(value, 'isNode') && $type(value.isNode) == Bool && value.isNode) {
            return 'node';
        } else if (type == Float) {
            return 'float';
        } else if (type == Bool) {
            return 'bool';
        } else if (type == String) {
            return 'string';
        } else if (type == FFun) {
            return 'shader';
        } else if (Reflect.hasField(value, 'isVector2') && $type(value.isVector2) == Bool && value.isVector2) {
            return 'vec2';
        } else if (Reflect.hasField(value, 'isVector3') && $type(value.isVector3) == Bool && value.isVector3) {
            return 'vec3';
        } else if (Reflect.hasField(value, 'isVector4') && $type(value.isVector4) == Bool && value.isVector4) {
            return 'vec4';
        } else if (Reflect.hasField(value, 'isMatrix3') && $type(value.isMatrix3) == Bool && value.isMatrix3) {
            return 'mat3';
        } else if (Reflect.hasField(value, 'isMatrix4') && $type(value.isMatrix4) == Bool && value.isMatrix4) {
            return 'mat4';
        } else if (Reflect.hasField(value, 'isColor') && $type(value.isColor) == Bool && value.isColor) {
            return 'color';
        } else if (type == ArrayBuffer) {
            return 'ArrayBuffer';
        }
        return null;
    }
}

class ValueFromType {
    public static get(type:String, ...params):Dynamic {
        var last4 = type.substr(-4);
        if (params.length == 1) {
            if (last4 == 'vec2') params = [params[0], params[0]];
            else if (last4 == 'vec3') params = [params[0], params[0], params[0]];
            else if (last4 == 'vec4') params = [params[0], params[0], params[0], params[0]];
        }

        if (type == 'color') {
            return new haxe.Color(params[0] as Float, params[1] as Float, params[2] as Float, params[3] as Float);
        } else if (last4 == 'vec2') {
            return new haxe.Vector2(params[0] as Float, params[1] as Float);
        } else if (last4 == 'vec3') {
            return new haxe.Vector3(params[0] as Float, params[1] as Float, params[2] as Float);
        } else if (last4 == 'vec4') {
            return new haxe.Vector4(params[0] as Float, params[1] as Float, params[2] as Float, params[3] as Float);
        } else if (last4 == 'mat3') {
            return new haxe.Matrix3(params[0] as Float, params[1] as Float, params[2] as Float, params[3] as Float, params[4] as Float, params[5] as Float, params[6] as Float, params[7] as Float, params[8] as Float);
        } else if (last4 == 'mat4') {
            return new haxe.Matrix4(params[0] as Float, params[1] as Float, params[2] as Float, params[3] as Float, params[4] as Float, params[5] as Float, params[6] as Float, params[7] as Float, params[8] as Float, params[9] as Float, params[10] as Float, params[11] as Float, params[12] as Float, params[13] as Float, params[14] as Float, params[15] as Float);
        } else if (type == 'bool') {
            return params[0] as Bool;
        } else if (type == 'float' || type == 'int' || type == 'uint') {
            return params[0] as Float;
        } else if (type == 'string') {
            return params[0] as String;
        } else if (type == 'ArrayBuffer') {
            return ValueFromType.base64ToArrayBuffer(params[0] as String);
        }
        return null;
    }

    public static arrayBufferToBase64(arrayBuffer:ArrayBuffer):String {
        var chars = '';
        var array = new haxe.io.Uint8Array(arrayBuffer);
        var length = array.length;
        for (i in 0...length) {
            chars += String.fromCharCode(array[i]);
        }
        return haxe.crypto.Base64.encode(chars);
    }

    public static base64ToArrayBuffer(base64:String):ArrayBuffer {
        var bytes = haxe.crypto.Base64.decode(base64);
        return bytes.buffer;
    }
}