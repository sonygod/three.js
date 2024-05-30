import js.html.WebGLRenderingContext;
import js.lib.WeakMap;
import three.core.BufferAttribute.Uint16BufferAttribute;
import three.core.BufferAttribute.Uint32BufferAttribute;
import three.utils.Utils.arrayNeedsUint32;

class WebGLGeometries {
    var gl:WebGLRenderingContext;
    var attributes:Dynamic;
    var info:Dynamic;
    var bindingStates:Dynamic;

    var geometries:Map<Int, Bool>;
    var wireframeAttributes:WeakMap<Dynamic, Dynamic>;

    public function new(gl:WebGLRenderingContext, attributes:Dynamic, info:Dynamic, bindingStates:Dynamic) {
        this.gl = gl;
        this.attributes = attributes;
        this.info = info;
        this.bindingStates = bindingStates;
        
        geometries = new Map();
        wireframeAttributes = new WeakMap();
    }

    function onGeometryDispose(event:Dynamic):Void {
        var geometry = event.target;

        if (geometry.index != null) {
            attributes.remove(geometry.index);
        }

        for (name in Reflect.fields(geometry.attributes)) {
            attributes.remove(Reflect.field(geometry.attributes, name));
        }

        for (name in Reflect.fields(geometry.morphAttributes)) {
            var array = Reflect.field(geometry.morphAttributes, name);
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
            Reflect.deleteField(geometry, '_maxInstanceCount');
        }

        info.memory.geometries--;
    }

    function get(object:Dynamic, geometry:Dynamic):Dynamic {
        if (geometries.exists(geometry.id)) return geometry;

        geometry.addEventListener('dispose', onGeometryDispose);
        geometries.set(geometry.id, true);

        info.memory.geometries++;

        return geometry;
    }

    function update(geometry:Dynamic):Void {
        var geometryAttributes = geometry.attributes;

        // Updating index buffer in VAO now. See WebGLBindingStates.
        for (name in Reflect.fields(geometryAttributes)) {
            attributes.update(Reflect.field(geometryAttributes, name), gl.ARRAY_BUFFER);
        }

        // morph targets
        var morphAttributes = geometry.morphAttributes;
        for (name in Reflect.fields(morphAttributes)) {
            var array = Reflect.field(morphAttributes, name);
            for (i in 0...array.length) {
                attributes.update(array[i], gl.ARRAY_BUFFER);
            }
        }
    }

    function updateWireframeAttribute(geometry:Dynamic):Void {
        var indices:Array<Int> = [];
        var geometryIndex = geometry.index;
        var geometryPosition = geometry.attributes.position;
        var version:Int = 0;

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
            for (i in 0...array.length / 3 - 1 by 3) {
                var a = i + 0;
                var b = i + 1;
                var c = i + 2;
                indices.push(a, b, b, c, c, a);
            }
        } else {
            return;
        }

        var attribute = arrayNeedsUint32(indices) ? new Uint32BufferAttribute(indices, 1) : new Uint16BufferAttribute(indices, 1);
        attribute.version = version;

        // Updating index buffer in VAO now. See WebGLBindingStates

        var previousAttribute = wireframeAttributes.get(geometry);
        if (previousAttribute != null) attributes.remove(previousAttribute);

        wireframeAttributes.set(geometry, attribute);
    }

    function getWireframeAttribute(geometry:Dynamic):Dynamic {
        var currentAttribute = wireframeAttributes.get(geometry);

        if (currentAttribute != null) {
            var geometryIndex = geometry.index;
            if (geometryIndex != null) {
                // if the attribute is obsolete, create a new one
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