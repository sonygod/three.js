package three.js.src.renderers.webgl;

import haxe.ds.WeakMap;
import js.html.webgl.GL;
import js.html.webgl.BufferAttribute;

class WebGLGeometries {
    private var geometries:Dynamic<String>;
    private var wireframeAttributes:WeakMap<Dynamic, BufferAttribute>;
    private var attributes:Dynamic;
    private var bindingStates:Dynamic;
    private var info:Dynamic;
    private var gl:GL;

    public function new(gl:GL, attributes:Dynamic, info:Dynamic, bindingStates:Dynamic) {
        this.geometries = {};
        this.wireframeAttributes = new WeakMap();
        this.attributes = attributes;
        this.bindingStates = bindingStates;
        this.info = info;
        this.gl = gl;
    }

    private function onGeometryDispose(event:Dynamic) {
        var geometry = event.target;

        if (geometry.index != null) {
            attributes.remove(geometry.index);
        }

        for (name in geometry.attributes) {
            attributes.remove(geometry.attributes[name]);
        }

        for (name in geometry.morphAttributes) {
            var array = geometry.morphAttributes[name];
            for (i in 0...array.length) {
                attributes.remove(array[i]);
            }
        }

        geometry.removeEventListener('dispose', onGeometryDispose);
        delete geometries[geometry.id];

        var attribute = wireframeAttributes.get(geometry);
        if (attribute != null) {
            attributes.remove(attribute);
            wireframeAttributes.delete(geometry);
        }

        bindingStates.releaseStatesOfGeometry(geometry);

        if (geometry.isInstancedBufferGeometry) {
            delete geometry._maxInstanceCount;
        }

        info.memory.geometries--;
    }

    public function get(object:Dynamic, geometry:Dynamic):Dynamic {
        if (geometries[geometry.id] == true) {
            return geometry;
        }

        geometry.addEventListener('dispose', onGeometryDispose);
        geometries[geometry.id] = true;
        info.memory.geometries++;
        return geometry;
    }

    public function update(geometry:Dynamic) {
        var geometryAttributes = geometry.attributes;

        for (name in geometryAttributes) {
            attributes.update(geometryAttributes[name], gl.ARRAY_BUFFER);
        }

        var morphAttributes = geometry.morphAttributes;
        for (name in morphAttributes) {
            var array = morphAttributes[name];
            for (i in 0...array.length) {
                attributes.update(array[i], gl.ARRAY_BUFFER);
            }
        }
    }

    private function updateWireframeAttribute(geometry:Dynamic) {
        var indices:Array<Int> = [];
        var geometryIndex = geometry.index;
        var geometryPosition = geometry.attributes.position;
        var version = 0;

        if (geometryIndex != null) {
            var array = geometryIndex.array;
            version = geometryIndex.version;

            for (i in 0...array.length) {
                var a = array[i + 0];
                var b = array[i + 1];
                var c = array[i + 2];

                indices.push(a, b, b, c, c, a);
            }
        } else if (geometryPosition != null) {
            var array = geometryPosition.array;
            version = geometryPosition.version;

            for (i in 0...(array.length / 3) - 1) {
                var a = i + 0;
                var b = i + 1;
                var c = i + 2;

                indices.push(a, b, b, c, c, a);
            }
        } else {
            return;
        }

        var attribute:BufferAttribute = arrayNeedsUint32(indices) ? new Uint32BufferAttribute(indices, 1) : new Uint16BufferAttribute(indices, 1);
        attribute.version = version;

        var previousAttribute = wireframeAttributes.get(geometry);

        if (previousAttribute != null) {
            attributes.remove(previousAttribute);
        }

        wireframeAttributes.set(geometry, attribute);
    }

    public function getWireframeAttribute(geometry:Dynamic):BufferAttribute {
        var currentAttribute = wireframeAttributes.get(geometry);

        if (currentAttribute != null) {
            var geometryIndex = geometry.index;

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

    public function newWebGLGeometries():Dynamic {
        return {
            get: get,
            update: update,
            getWireframeAttribute: getWireframeAttribute
        };
    }
}