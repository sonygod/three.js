package three.js.src.renderers.webgl;

import three.js.core.BufferAttribute;
import three.js.utils.Utils;

class WebGLGeometries {
    private var gl:WebGLRenderingContext;
    private var attributes:Array<BufferAttribute>;
    private var info:Dynamic;
    private var bindingStates:Dynamic;
    private var geometries:Map<String, Bool>;
    private var wireframeAttributes:Map<Dynamic, BufferAttribute>;

    public function new(gl:WebGLRenderingContext, attributes:Array<BufferAttribute>, info:Dynamic, bindingStates:Dynamic) {
        this.gl = gl;
        this.attributes = attributes;
        this.info = info;
        this.bindingStates = bindingStates;
        this.geometries = new Map<String, Bool>();
        this.wireframeAttributes = new Map<Dynamic, BufferAttribute>();
    }

    private function onGeometryDispose(event:Dynamic) {
        var geometry:Dynamic = event.target;
        if (geometry.index != null) {
            attributes.remove(geometry.index);
        }
        for (name in geometry.attributes) {
            attributes.remove(geometry.attributes[name]);
        }
        for (name in geometry.morphAttributes) {
            var array:Array<BufferAttribute> = geometry.morphAttributes[name];
            for (i in 0...array.length) {
                attributes.remove(array[i]);
            }
        }
        geometry.removeEventListener('dispose', onGeometryDispose);
        geometries.remove(geometry.id);
        var attribute:BufferAttribute = wireframeAttributes.get(geometry);
        if (attribute != null) {
            attributes.remove(attribute);
            wireframeAttributes.remove(geometry);
        }
        bindingStates.releaseStatesOfGeometry(geometry);
        if (geometry.isInstancedBufferGeometry) {
            delete geometry._maxInstanceCount;
        }
        info.memory.geometries--;
    }

    public function get(object:Dynamic, geometry:Dynamic):Dynamic {
        if (geometries.exists(geometry.id)) {
            return geometry;
        }
        geometry.addEventListener('dispose', onGeometryDispose);
        geometries.set(geometry.id, true);
        info.memory.geometries++;
        return geometry;
    }

    public function update(geometry:Dynamic) {
        var geometryAttributes:Dynamic = geometry.attributes;
        for (name in geometryAttributes) {
            attributes.update(geometryAttributes[name], gl.ARRAY_BUFFER);
        }
        var morphAttributes:Dynamic = geometry.morphAttributes;
        for (name in morphAttributes) {
            var array:Array<BufferAttribute> = morphAttributes[name];
            for (i in 0...array.length) {
                attributes.update(array[i], gl.ARRAY_BUFFER);
            }
        }
    }

    private function updateWireframeAttribute(geometry:Dynamic) {
        var indices:Array<Int> = [];
        var geometryIndex:Dynamic = geometry.index;
        var geometryPosition:Dynamic = geometry.attributes.position;
        var version:Int = 0;
        if (geometryIndex != null) {
            var array:Array<Int> = geometryIndex.array;
            version = geometryIndex.version;
            for (i in 0...array.length) {
                var a:Int = array[i + 0];
                var b:Int = array[i + 1];
                var c:Int = array[i + 2];
                indices.push(a, b, b, c, c, a);
            }
        } else if (geometryPosition != null) {
            var array:Array<Float> = geometryPosition.array;
            version = geometryPosition.version;
            for (i in 0...(array.length / 3) - 1) {
                var a:Int = i + 0;
                var b:Int = i + 1;
                var c:Int = i + 2;
                indices.push(a, b, b, c, c, a);
            }
        } else {
            return;
        }
        var attribute:BufferAttribute = Utils.arrayNeedsUint32(indices) ? new Uint32BufferAttribute(indices, 1) : new Uint16BufferAttribute(indices, 1);
        attribute.version = version;
        var previousAttribute:BufferAttribute = wireframeAttributes.get(geometry);
        if (previousAttribute != null) {
            attributes.remove(previousAttribute);
        }
        wireframeAttributes.set(geometry, attribute);
    }

    public function getWireframeAttribute(geometry:Dynamic):BufferAttribute {
        var currentAttribute:BufferAttribute = wireframeAttributes.get(geometry);
        if (currentAttribute != null) {
            var geometryIndex:Dynamic = geometry.index;
            if (geometryIndex != null) {
                if (currentAttribute.version < geometryIndex.version) {
                    updateWireframeAttribute(geometry);
                }
            }
        } else {
            updateWireframeAttribute(geometry);
        }
        return wireframeAttributes.get(geometry);
    }
}