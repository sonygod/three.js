import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Vector2;
import three.Vector3;
import three.Vector4;

class Node {
  public var isNode:Bool;

  public function new() {
    this.isNode = true;
  }

  public function getCacheKey(force:Bool = false):String {
    return "{${this.id}}";
  }
}

class Object {
  public var isNode:Bool;

  public function new() {
    this.isNode = false;
  }
}

function getCacheKey(object:Object, force:Bool = false):String {
  var cacheKey = "{";
  if (object.isNode) {
    cacheKey += object.id;
  }
  for (property, childNode in getNodeChildren(object)) {
    cacheKey += "," + property.substring(0, property.length - 4) + ":" + childNode.getCacheKey(force);
  }
  cacheKey += "}";
  return cacheKey;
}

function* getNodeChildren(node:Object, toJSON:Bool = false):Iterator<{property:String, index:Dynamic, childNode:Object}> {
  for (property in node) {
    if (property.startsWith("_")) continue;
    var object = node[property];
    if (object is Array) {
      for (i in 0...object.length) {
        var child = object[i];
        if (child != null && (child.isNode || toJSON && Reflect.isFunction(child.toJSON))) {
          yield {property:property, index:i, childNode:child};
        }
      }
    } else if (object != null && object.isNode) {
      yield {property:property, childNode:object};
    } else if (object is Object) {
      for (subProperty in object) {
        var child = object[subProperty];
        if (child != null && (child.isNode || toJSON && Reflect.isFunction(child.toJSON))) {
          yield {property:property, index:subProperty, childNode:child};
        }
      }
    }
  }
}

function getValueType(value:Dynamic):String {
  if (value == null) return null;
  var typeOf = typeof(value);
  if (value.isNode) {
    return "node";
  } else if (typeOf == "number") {
    return "float";
  } else if (typeOf == "bool") {
    return "bool";
  } else if (typeOf == "string") {
    return "string";
  } else if (typeOf == "function") {
    return "shader";
  } else if (value.isVector2) {
    return "vec2";
  } else if (value.isVector3) {
    return "vec3";
  } else if (value.isVector4) {
    return "vec4";
  } else if (value.isMatrix3) {
    return "mat3";
  } else if (value.isMatrix4) {
    return "mat4";
  } else if (value.isColor) {
    return "color";
  } else if (value is ArrayBuffer) {
    return "ArrayBuffer";
  }
  return null;
}

function getValueFromType(type:String, ...params:Array<Dynamic>):Dynamic {
  var last4 = type != null ? type.substring(type.length - 4) : null;
  if (params.length == 1) {
    if (last4 == "vec2") params = [params[0], params[0]];
    else if (last4 == "vec3") params = [params[0], params[0], params[0]];
    else if (last4 == "vec4") params = [params[0], params[0], params[0], params[0]];
  }
  if (type == "color") {
    return new Color(params[0], params[1], params[2]);
  } else if (last4 == "vec2") {
    return new Vector2(params[0], params[1]);
  } else if (last4 == "vec3") {
    return new Vector3(params[0], params[1], params[2]);
  } else if (last4 == "vec4") {
    return new Vector4(params[0], params[1], params[2], params[3]);
  } else if (last4 == "mat3") {
    return new Matrix3(params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8]);
  } else if (last4 == "mat4") {
    return new Matrix4(params[0], params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8], params[9], params[10], params[11], params[12], params[13], params[14], params[15]);
  } else if (type == "bool") {
    return params[0] != null;
  } else if (type == "float" || type == "int" || type == "uint") {
    return params[0] != null ? params[0] : 0;
  } else if (type == "string") {
    return params[0] != null ? params[0] : "";
  } else if (type == "ArrayBuffer") {
    return base64ToArrayBuffer(params[0]);
  }
  return null;
}

function arrayBufferToBase64(arrayBuffer:ArrayBuffer):String {
  var chars = "";
  var array = new Uint8Array(arrayBuffer);
  for (i in 0...array.length) {
    chars += String.fromCharCode(array[i]);
  }
  return haxe.crypto.Base64.encode(chars);
}

function base64ToArrayBuffer(base64:String):ArrayBuffer {
  return haxe.io.Bytes.ofString(haxe.crypto.Base64.decode(base64)).buffer;
}