import three.core.BufferAttribute.Uint16BufferAttribute;
import three.core.BufferAttribute.Uint32BufferAttribute;
import three.utils.arrayNeedsUint32;

class WebGLGeometries {
    private var geometries:Map<Bool>;
    private var wireframeAttributes:Map<BufferAttribute>;

    public function new(gl:WebGLRenderingContext, attributes:WebGLAttributes, info:Stats, bindingStates:WebGLBindingStates) {
        geometries = new Map<Bool>();
        wireframeAttributes = new Map<BufferAttribute>();

        var onGeometryDispose = function(event) {
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
            geometries.remove(geometry.id);

            var attribute = wireframeAttributes.get(geometry);
            if (attribute != null) {
                attributes.remove(attribute);
                wireframeAttributes.remove(geometry);
            }

            bindingStates.releaseStatesOfGeometry(geometry);

            if (geometry.isInstancedBufferGeometry == true) {
                delete geometry._maxInstanceCount;
            }

            info.memory.geometries--;
        };

        var get = function(object, geometry) {
            if (geometries.get(geometry.id) == true) return geometry;

            geometry.addEventListener('dispose', onGeometryDispose);
            geometries.set(geometry.id, true);

            info.memory.geometries++;

            return geometry;
        };

        var update = function(geometry) {
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
        };

        var updateWireframeAttribute = function(geometry) {
            var indices = [];
            var geometryIndex = geometry.index;
            var geometryPosition = geometry.attributes.position;
            var version = 0;

            if (geometryIndex != null) {
                var array = geometryIndex.array;
                version = geometryIndex.version;

                for (i in 0...array.length by 3) {
                    var a = array[i + 0];
                    var b = array[i + 1];
                    var c = array[i + 2];

                    indices.push(a, b, b, c, c, a);
                }
            } else if (geometryPosition != null) {
                var array = geometryPosition.array;
                version = geometryPosition.version;

                for (i in 0...(array.length / 3) - 1 by 3) {
                    var a = i + 0;
                    var b = i + 1;
                    var c = i + 2;

                    indices.push(a, b, b, c, c, a);
                }
            } else {
                return;
            }

            var attribute = new (arrayNeedsUint32(indices) ? Uint32BufferAttribute : Uint16BufferAttribute)(indices, 1);
            attribute.version = version;

            var previousAttribute = wireframeAttributes.get(geometry);
            if (previousAttribute != null) attributes.remove(previousAttribute);

            wireframeAttributes.set(geometry, attribute);
        };

        var getWireframeAttribute = function(geometry) {
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
        };

        return {
            get: get,
            update: update,
            getWireframeAttribute: getWireframeAttribute
        };
    }
}