package three.js.examples.jsm.renderers.common;

import js.html.Float32Array;
import js.html.Uint16Array;
import js.html.Uint32Array;
import three.renderers.common.DataMap;
import three.renderers.common.Constants;

class Geometries extends DataMap<Data<Geometry>> {
    public var attributes:Map<String, BufferAttribute>;
    public var info:Info;
    public var wireframes:WeakMap<Geometry, BufferAttribute>;
    public var attributeCall:WeakMap<BufferAttribute, Int>;

    public function new(attributes:Map<String, BufferAttribute>, info:Info) {
        super();
        this.attributes = attributes;
        this.info = info;
        this.wireframes = new WeakMap();
        this.attributeCall = new WeakMap();
    }

    public function has(renderObject:RenderObject):Bool {
        var geometry:Geometry = renderObject.geometry;
        return super.has(geometry) && get(geometry).initialized;
    }

    public function updateForRender(renderObject:RenderObject) {
        if (!has(renderObject)) initGeometry(renderObject);
        updateAttributes(renderObject);
    }

    private function initGeometry(renderObject:RenderObject) {
        var geometry:Geometry = renderObject.geometry;
        var geometryData:Dynamic = get(geometry);
        geometryData.initialized = true;
        info.memory.geometries++;
        var onDispose = function() {
            info.memory.geometries--;
            var index:BufferAttribute = geometry.index;
            var geometryAttributes:Array<BufferAttribute> = renderObject.getAttributes();
            if (index != null) attributes.delete(index);
            for (attribute in geometryAttributes) attributes.delete(attribute);
            var wireframeAttribute:BufferAttribute = wireframes.get(geometry);
            if (wireframeAttribute != null) attributes.delete(wireframeAttribute);
            geometry.removeEventListener('dispose', onDispose);
        };
        geometry.addEventListener('dispose', onDispose);
    }

    private function updateAttributes(renderObject:RenderObject) {
        var attributes:Array<BufferAttribute> = renderObject.getAttributes();
        for (attribute in attributes) updateAttribute(attribute, AttributeType.VERTEX);
        var index:BufferAttribute = getIndex(renderObject);
        if (index != null) updateAttribute(index, AttributeType.INDEX);
    }

    private function updateAttribute(attribute:BufferAttribute, type:AttributeType) {
        var callId:Int = info.render.calls;
        if (!attributeCall.exists(attribute) || attributeCall.get(attribute) != callId) {
            attributes.update(attribute, type);
            attributeCall.set(attribute, callId);
        }
    }

    private function getIndex(renderObject:RenderObject):BufferAttribute {
        var geometry:Geometry = renderObject.geometry;
        var material:Material = renderObject.material;
        var index:BufferAttribute = geometry.index;
        if (material.wireframe) {
            var wireframes:WeakMap<Geometry, BufferAttribute> = this.wireframes;
            var wireframeAttribute:BufferAttribute = wireframes.get(geometry);
            if (wireframeAttribute == null) {
                wireframeAttribute = getWireframeIndex(geometry);
                wireframes.set(geometry, wireframeAttribute);
            } else if (wireframeAttribute.version != getWireframeVersion(geometry)) {
                attributes.delete(wireframeAttribute);
                wireframeAttribute = getWireframeIndex(geometry);
                wireframes.set(geometry, wireframeAttribute);
            }
            index = wireframeAttribute;
        }
        return index;
    }

    private function getWireframeVersion(geometry:Geometry):Int {
        return geometry.index != null ? geometry.index.version : geometry.attributes.position.version;
    }

    private function arrayNeedsUint32(array:Array<Float>):Bool {
        for (i in array.length - 1...0) {
            if (array[i] >= 65535) return true; // account for PRIMITIVE_RESTART_FIXED_INDEX, #24565
        }
        return false;
    }

    private function getWireframeIndex(geometry:Geometry):BufferAttribute {
        var indices:Array<Float> = [];
        var geometryIndex:BufferAttribute = geometry.index;
        var geometryPosition:BufferAttribute = geometry.attributes.position;
        if (geometryIndex != null) {
            var array:Array<Float> = geometryIndex.array;
            for (i in 0...array.length step 3) {
                var a:Int = array[i + 0];
                var b:Int = array[i + 1];
                var c:Int = array[i + 2];
                indices.push(a, b, b, c, c, a);
            }
        } else {
            var array:Array<Float> = geometryPosition.array;
            for (i in 0...array.length / 3 - 1) {
                var a:Int = i + 0;
                var b:Int = i + 1;
                var c:Int = i + 2;
                indices.push(a, b, b, c, c, a);
            }
        }
        var attributeClass:Class<BufferAttribute> = arrayNeedsUint32(indices) ? Uint32BufferAttribute : Uint16BufferAttribute;
        var attribute:BufferAttribute = Type.createInstance(attributeClass, [indices, 1]);
        attribute.version = getWireframeVersion(geometry);
        return attribute;
    }
}