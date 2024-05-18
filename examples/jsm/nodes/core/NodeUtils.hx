package three.js.examples.jsm.nodes.core;

import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Vector2;
import three.Vector3;
import three.Vector4;

class NodeUtils {
    public static function getCacheKey(object:Dynamic, force:Bool = false):String {
        var cacheKey:String = '{';

        if (object.isNode) {
            cacheKey += object.id;
        }

        for (nodeChild in getNodeChildren(object)) {
            cacheKey += ',' + nodeChild.property.slice(0, -4) + ':' + nodeChild.childNode.getCacheKey(force);
        }

        cacheKey += '}';

        return cacheKey;
    }

    public static function getNodeChildren(node:Dynamic, toJSON:Bool = false):Iterator<{ property:String, childNode:Dynamic }> {
        for (property in Reflect.fields(node)) {
            if (property.startsWith('_')) continue;

            var object:Dynamic = Reflect.field(node, property);

            if (Std.isOfType(object, Array)) {
                for (i in 0...object.length) {
                    var child:Dynamic = object[i];

                    if (child != null && (child.isNode || toJSON && Reflect.hasField(child, 'toJSON'))) {
                        yield { property: property, index: i, childNode: child };
                    }
                }
            } else if (object != null && object.isNode) {
                yield { property: property, childNode: object };
            } else if (Std.isOfType(object, Object)) {
                for (subProperty in Reflect.fields(object)) {
                    var child:Dynamic = Reflect.field(object, subProperty);

                    if (child != null && (child.isNode || toJSON && Reflect.hasField(child, 'toJSON'))) {
                        yield { property: property, index: subProperty, childNode: child };
                    }
                }
            }
        }
    }

    public static function getValueType(value:Dynamic):String {
        if (value == null) return null;

        if (value.isNode) return 'node';

        var typeOf:String = Type.typeof(value);

        if (typeOf == ValueType.TNull || typeOf == ValueType.TUndefined) return null;

        switch (typeOf) {
            case ValueType.TFloat:
                return 'float';
            case ValueType.TBool:
                return 'bool';
            case ValueType.TString:
                return 'string';
            case ValueType.TFunction:
                return 'shader';
            case ValueType.TObject:
                if (value.isVector2) return 'vec2';
                if (value.isVector3) return 'vec3';
                if (value.isVector4) return 'vec4';
                if (value.isMatrix3) return 'mat3';
                if (value.isMatrix4) return 'mat4';
                if (value.isColor) return 'color';
                if (Std.isOfType(value, ArrayBuffer)) return 'ArrayBuffer';
        }

        return null;
    }

    public static function getValueFromType(type:String, params:Array<Dynamic>):Dynamic {
        var last4:String = type != null ? type.substr(-4) : null;

        if (params.length == 1) {
            switch (last4) {
                case 'vec2': params = [params[0], params[0]];
                case 'vec3': params = [params[0], params[0], params[0]];
                case 'vec4': params = [params[0], params[0], params[0], params[0]];
            }
        }

        switch (type) {
            case 'color':
                return new Color(params);
            case 'vec2':
                return new Vector2(params);
            case 'vec3':
                return new Vector3(params);
            case 'vec4':
                return new Vector4(params);
            case 'mat3':
                return new Matrix3(params);
            case 'mat4':
                return new Matrix4(params);
            case 'bool':
                return params[0] != null && params[0] != false;
            case 'float', 'int', 'uint':
                return params[0] != null ? params[0] : 0;
            case 'string':
                return params[0] != null ? params[0] : '';
            case 'ArrayBuffer':
                return base64ToArrayBuffer(params[0]);
        }

        return null;
    }

    public static function arrayBufferToBase64(arrayBuffer:ArrayBuffer):String {
        var chars:String = '';

        var array:Uint8Array = new Uint8Array(arrayBuffer);

        for (i in 0...array.length) {
            chars += String.fromCharCode(array[i]);
        }

        return haxe.crypto.Base64.encode(chars);
    }

    public static function base64ToArrayBuffer(base64:String):ArrayBuffer {
        return Uint8Array.from([for (c in haxe.crypto.Base64.decode(base64)) c.charCodeAt(0)]).buffer;
    }
}