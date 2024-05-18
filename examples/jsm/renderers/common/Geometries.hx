Here is the converted Haxe code:
```
package three.js.examples.jvm.renderers.common;

import DataMap;
import Constants.AttributeType;

class Geometries extends DataMap {

    public var attributes:Map<Data, Dynamic>;
    public var info:Dynamic;
    public var wireframes:WeakMap<Data, Dynamic>;
    public var attributeCall:WeakMap<Data, Int>;

    public function new(attributes:Map<Data, Dynamic>, info:Dynamic) {
        super();
        this.attributes = attributes;
        this.info = info;
        this.wireframes = new WeakMap<Data, Dynamic>();
        this.attributeCall = new WeakMap<Data, Int>();
    }

    public function has(renderObject:Dynamic):Bool {
        var geometry:Dynamic = renderObject.geometry;
        return super.has(geometry) && this.get(geometry).initialized;
    }

    public function updateForRender(renderObject:Dynamic):Void {
        if (!this.has(renderObject)) this.initGeometry(renderObject);
        this.updateAttributes(renderObject);
    }

    public function initGeometry(renderObject:Dynamic):Void {
        var geometry:Dynamic = renderObject.geometry;
        var geometryData:Dynamic = this.get(geometry);
        geometryData.initialized = true;
        this.info.memory.geometries++;
        var onDispose:Void->Void = function():Void {
            this.info.memory.geometries--;
            var index:Dynamic = geometry.index;
            var geometryAttributes:Array<Dynamic> = renderObject.getAttributes();
            if (index != null) {
                this.attributes.delete(index);
            }
            for (attribute in geometryAttributes) {
                this.attributes.delete(attribute);
            }
            var wireframeAttribute:Dynamic = this.wireframes.get(geometry);
            if (wireframeAttribute != null) {
                this.attributes.delete(wireframeAttribute);
            }
            geometry.removeEventListener('dispose', onDispose);
        };
        geometry.addEventListener('dispose', onDispose);
    }

    public function updateAttributes(renderObject:Dynamic):Void {
        var attributes:Array<Dynamic> = renderObject.getAttributes();
        for (attribute in attributes) {
            this.updateAttribute(attribute, AttributeType.VERTEX);
        }
        var index:Dynamic = this.getIndex(renderObject);
        if (index != null) {
            this.updateAttribute(index, AttributeType.INDEX);
        }
    }

    public function updateAttribute(attribute:Dynamic, type:AttributeType):Void {
        var callId:Int = this.info.render.calls;
        if (this.attributeCall.get(attribute) != callId) {
            this.attributes.update(attribute, type);
            this.attributeCall.set(attribute, callId);
        }
    }

    public function getIndex(renderObject:Dynamic):Dynamic {
        var geometry:Dynamic = renderObject.geometry;
        var material:Dynamic = renderObject.material;
        var index:Dynamic = geometry.index;
        if (material.wireframe) {
            var wireframes:WeakMap<Data, Dynamic> = this.wireframes;
            var wireframeAttribute:Dynamic = wireframes.get(geometry);
            if (wireframeAttribute == null) {
                wireframeAttribute = getWireframeIndex(geometry);
                wireframes.set(geometry, wireframeAttribute);
            } else if (wireframeAttribute.version != getWireframeVersion(geometry)) {
                this.attributes.delete(wireframeAttribute);
                wireframeAttribute = getWireframeIndex(geometry);
                wireframes.set(geometry, wireframeAttribute);
            }
            index = wireframeAttribute;
        }
        return index;
    }

    static function arrayNeedsUint32(array:Array<Int>):Bool {
        for (i in array.length - 1...0) {
            if (array[i] >= 65535) return true; // account for PRIMITIVE_RESTART_FIXED_INDEX, #24565
        }
        return false;
    }

    static function getWireframeVersion(geometry:Dynamic):Int {
        return (geometry.index != null) ? geometry.index.version : geometry.attributes.position.version;
    }

    static function getWireframeIndex(geometry:Dynamic):Dynamic {
        var indices:Array<Int> = [];
        var geometryIndex:Dynamic = geometry.index;
        var geometryPosition:Dynamic = geometry.attributes.position;
        if (geometryIndex != null) {
            var array:Array<Int> = geometryIndex.array;
            for (i in 0...array.length step 3) {
                var a:Int = array[i + 0];
                var b:Int = array[i + 1];
                var c:Int = array[i + 2];
                indices.push(a, b, b, c, c, a);
            }
        } else {
            var array:Array<Float> = geometryPosition.array;
            for (i in 0...(array.length / 3) - 1) {
                var a:Int = i + 0;
                var b:Int = i + 1;
                var c:Int = i + 2;
                indices.push(a, b, b, c, c, a);
            }
        }
        var attribute:Dynamic = (arrayNeedsUint32(indices) ? Uint32BufferAttribute : Uint16BufferAttribute)(indices, 1);
        attribute.version = getWireframeVersion(geometry);
        return attribute;
    }
}
```
Note that I've kept the same file structure and naming conventions as the original JavaScript code. I've also used the Haxe `WeakMap` and `Map` classes to replace the JavaScript `WeakMap` and `Map` respectively. Additionally, I've used Haxe's type system to add type annotations to the code, which can help catch errors at compile-time.