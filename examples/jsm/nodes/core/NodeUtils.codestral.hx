import three.math.Color;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;

class NodeUtils {
    public static function getCacheKey(object:Dynamic, force:Bool = false):String {
        var cacheKey:String = '{';

        if (Std.is(object, Dynamic).isNode) {
            cacheKey += object.id;
        }

        for (item in getNodeChildren(object)) {
            var property = item.property;
            var childNode = item.childNode;
            cacheKey += ',' + property.substr(0, property.length - 4) + ':' + NodeUtils.getCacheKey(childNode, force);
        }

        cacheKey += '}';

        return cacheKey;
    }

    public static function getNodeChildren(node:Dynamic, toJSON:Bool = false):Array<Dynamic> {
        var children:Array<Dynamic> = [];

        for (property in Reflect.fields(node)) {
            if (property.startsWith('_')) continue;

            var object = Reflect.field(node, property);

            if (Std.is(object, Array)) {
                for (i in 0...object.length) {
                    var child = object[i];

                    if (child != null && (Std.is(child, Dynamic).isNode || toJSON && Reflect.hasField(child, 'toJSON'))) {
                        children.push({property: property, index: i, childNode: child});
                    }
                }
            } else if (object != null && Std.is(object, Dynamic).isNode) {
                children.push({property: property, childNode: object});
            } else if (Std.is(object, Dynamic)) {
                for (subProperty in Reflect.fields(object)) {
                    var child = Reflect.field(object, subProperty);

                    if (child != null && (Std.is(child, Dynamic).isNode || toJSON && Reflect.hasField(child, 'toJSON'))) {
                        children.push({property: property, index: subProperty, childNode: child});
                    }
                }
            }
        }

        return children;
    }

    public static function getValueType(value:Dynamic):Null<String> {
        if (value == null) return null;

        var typeOf = Type.getClass(value);

        if (Std.is(value, Dynamic).isNode) {
            return 'node';
        } else if (typeOf == Float) {
            return 'float';
        } else if (typeOf == Bool) {
            return 'bool';
        } else if (typeOf == String) {
            return 'string';
        } else if (typeOf == Class<Function>) {
            return 'shader';
        } else if (Std.is(value, Vector2)) {
            return 'vec2';
        } else if (Std.is(value, Vector3)) {
            return 'vec3';
        } else if (Std.is(value, Vector4)) {
            return 'vec4';
        } else if (Std.is(value, Matrix3)) {
            return 'mat3';
        } else if (Std.is(value, Matrix4)) {
            return 'mat4';
        } else if (Std.is(value, Color)) {
            return 'color';
        } else if (Std.is(value, ArrayBuffer)) {
            return 'ArrayBuffer';
        }

        return null;
    }

    public static function getValueFromType(type:Null<String>, params:Array<Dynamic>):Dynamic {
        var last4 = type != null ? type.substr(type.length - 4) : null;

        if (params.length == 1) {
            if (last4 == 'vec2') params = [params[0], params[0]];
            else if (last4 == 'vec3') params = [params[0], params[0], params[0]];
            else if (last4 == 'vec4') params = [params[0], params[0], params[0], params[0]];
        }

        if (type == 'color') {
            return new Color(params[0], params[1], params[2]);
        } else if (last4 == 'vec2') {
            return new Vector2(params[0], params[1]);
        } else if (last4 == 'vec3') {
            return new Vector3(params[0], params[1], params[2]);
        } else if (last4 == 'vec4') {
            return new Vector4(params[0], params[1], params[2], params[3]);
        } else if (last4 == 'mat3') {
            return new Matrix3().fromArray(params);
        } else if (last4 == 'mat4') {
            return new Matrix4().fromArray(params);
        } else if (type == 'bool') {
            return params[0] || false;
        } else if (type == 'float' || type == 'int' || type == 'uint') {
            return params[0] || 0;
        } else if (type == 'string') {
            return params[0] || '';
        } else if (type == 'ArrayBuffer') {
            return base64ToArrayBuffer(params[0]);
        }

        return null;
    }

    public static function arrayBufferToBase64(arrayBuffer:ArrayBuffer):String {
        var chars:String = '';
        var array = new Uint8Array(arrayBuffer);

        for (i in 0...array.length) {
            chars += String.fromCharCode(array[i]);
        }

        return haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(chars));
    }

    public static function base64ToArrayBuffer(base64:String):ArrayBuffer {
        var bytes = haxe.crypto.Base64.decode(base64);
        var uint8Array = new Uint8Array(bytes.length);

        for (i in 0...bytes.length) {
            uint8Array[i] = bytes.b[i];
        }

        return uint8Array.buffer;
    }
}