import three.math.Color;
import three.math.Matrix3;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Vector4;

class NodeUtils {
    public static function getCacheKey(object:Dynamic, force:Bool = false):String {
        var cacheKey:String = '{';
        if (Std.is(object, Node)) {
            cacheKey += object.id;
        }
        for (child in getNodeChildren(object)) {
            cacheKey += ',' + child.property.slice(0, -4) + ':' + child.childNode.getCacheKey(force);
        }
        cacheKey += '}';
        return cacheKey;
    }

    public static function* getNodeChildren(node:Dynamic, toJSON:Bool = false):Iterator<{property:String, index:Dynamic, childNode:Dynamic}> {
        for (property in Reflect.fields(node)) {
            if (property.startsWith('_')) continue;
            var object = Reflect.field(node, property);
            if (Type.getClassName(object) == Array) {
                for (i in 0...object.length) {
                    var child = object[i];
                    if (child && (Std.is(child, Node) || toJSON && Type.getClassName(child) == 'Function')) {
                        yield {property: property, index: i, childNode: child};
                    }
                }
            } else if (object && Std.is(object, Node)) {
                yield {property: property, childNode: object};
            } else if (Type.getClassName(object) == 'Object') {
                for (subProperty in Reflect.fields(object)) {
                    var child = Reflect.field(object, subProperty);
                    if (child && (Std.is(child, Node) || toJSON && Type.getClassName(child) == 'Function')) {
                        yield {property: property, index: subProperty, childNode: child};
                    }
                }
            }
        }
    }

    public static function getValueType(value:Dynamic):String {
        if (value == null) return null;
        var typeOf = Type.typeof(value);
        if (Std.is(value, Node)) {
            return 'node';
        } else if (typeOf == 'Float') {
            return 'float';
        } else if (typeOf == 'Bool') {
            return 'bool';
        } else if (typeOf == 'String') {
            return 'string';
        } else if (typeOf == 'Function') {
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
        } else if (Type.getClassName(value) == 'ArrayBuffer') {
            return 'ArrayBuffer';
        }
        return null;
    }

    public static function getValueFromType(type:String, ...params:Array<Dynamic>):Dynamic {
        var last4 = type.slice(-4);
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
            return new Matrix3(params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8]);
        } else if (last4 == 'mat4') {
            return new Matrix4(params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8], params[9], params[10], params[11], params[12], params[13], params[14], params[15]);
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
        return Base64.encode(chars);
    }

    public static function base64ToArrayBuffer(base64:String):ArrayBuffer {
        return new Uint8Array(Base64.decode(base64)).buffer;
    }
}