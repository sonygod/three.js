package three.js.examples.jsw.nodes.core;

import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Vector2;
import three.Vector3;
import three.Vector4;

class NodeUtils {
    public static function getCacheKey(object:Dynamic, force:Bool = false):String {
        var cacheKey:String = "{";
        if (object.isNode) {
            cacheKey += object.id;
        }
        for (childNode in getNodeChildren(object)) {
            cacheKey += "," + childNode.property.slice(0, -4) + ":" + childNode.getCacheKey(force);
        }
        cacheKey += "}";
        return cacheKey;
    }

    public static function getNodeChildren(node:Dynamic, toJSON:Bool = false):Iterator<NodeChild> {
        for (property in Reflect.fields(node)) {
            if (property.charAt(0) == "_") continue;
            var object:Dynamic = Reflect.field(node, property);
            if (Std.isOfType(object, Array)) {
                for (i in 0...object.length) {
                    var child:Dynamic = object[i];
                    if (child != null && (child.isNode || toJSON && Reflect.hasField(child, "toJSON"))) {
                        yield { property: property, index: i, childNode: child };
                    }
                }
            } else if (object != null && object.isNode) {
                yield { property: property, childNode: object };
            } else if (Reflect.isObject(object)) {
                for (subProperty in Reflect.fields(object)) {
                    var child:Dynamic = Reflect.field(object, subProperty);
                    if (child != null && (child.isNode || toJSON && Reflect.hasField(child, "toJSON"))) {
                        yield { property: property, index: subProperty, childNode: child };
                    }
                }
            }
        }
    }

    public static function getValueType(value:Dynamic):String {
        if (value == null) return null;
        var type:ValueType = getType(value);
        if (value.isNode) return "node";
        else if (type == TInt || type == TFloat) return "float";
        else if (type == TBool) return "bool";
        else if (type == TString) return "string";
        else if (Reflect.hasField(value, "toJSON")) return "shader";
        else if (value.isVector2) return "vec2";
        else if (value.isVector3) return "vec3";
        else if (value.isVector4) return "vec4";
        else if (value.isMatrix3) return "mat3";
        else if (value.isMatrix4) return "mat4";
        else if (value.isColor) return "color";
        else if (Std.isOfType(value, ArrayBuffer)) return "ArrayBuffer";
        return null;
    }

    public static function getValueFromType(type:String, params:Array<Dynamic>):Dynamic {
        var last4:String = type.substr(-4);
        if (params.length == 1) {
            if (last4 == "vec2") params = [params[0], params[0]];
            else if (last4 == "vec3") params = [params[0], params[0], params[0]];
            else if (last4 == "vec4") params = [params[0], params[0], params[0], params[0]];
        }
        if (type == "color") return new Color(params);
        else if (last4 == "vec2") return new Vector2(params);
        else if (last4 == "vec3") return new Vector3(params);
        else if (last4 == "vec4") return new Vector4(params);
        else if (last4 == "mat3") return new Matrix3(params);
        else if (last4 == "mat4") return new Matrix4(params);
        else if (type == "bool") return params[0] != null && params[0] != false;
        else if (type == "float" || type == "int" || type == "uint") return params[0] != null ? params[0] : 0;
        else if (type == "string") return params[0] != null ? params[0] : "";
        else if (type == "ArrayBuffer") return base64ToArrayBuffer(params[0]);
        return null;
    }

    public static function arrayBufferToBase64(arrayBuffer:ArrayBuffer):String {
        var chars:String = "";
        var array:Uint8Array = new Uint8Array(arrayBuffer);
        for (i in 0...array.length) {
            chars += String.fromCharCode(array[i]);
        }
        return haxe.crypto.Base64.encode(chars);
    }

    public static function base64ToArrayBuffer(base64:String):ArrayBuffer {
        var array:Array<UInt> = [];
        var chars:String = haxe.crypto.Base64.decode(base64);
        for (i in 0...chars.length) {
            array.push(chars.charCodeAt(i));
        }
        return ArrayBuffer.fromArray(array);
    }
}