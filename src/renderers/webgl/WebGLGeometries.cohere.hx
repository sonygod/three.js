import js.Browser.Window;
import js.WebGLRenderingContext.*;
import openfl.display.DisplayObject;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.events.EventDispatcher;

class WebGLGeometries {
    private var geometries:HashMap<Int,Geometry> = new HashMap();
    private var wireframeAttributes:WeakMap<Geometry,VertexBuffer3D> = new WeakMap();

    private function onGeometryDispose(event:Event) {
        var geometry = cast(event.target, Geometry);

        if (geometry.index != null) {
            Window.attributes.remove(geometry.index);
        }

        for (name in geometry.attributes) {
            Window.attributes.remove(geometry.attributes[name]);
        }

        for (name in geometry.morphAttributes) {
            var array = geometry.morphAttributes[name];
            for (i in 0...array.length) {
                Window.attributes.remove(array[i]);
            }
        }

        geometry.removeEventListener(Event.DISPOSE, onGeometryDispose);

        geometries.remove(geometry.id);

        var attribute = wireframeAttributes.get(geometry);
        if (attribute != null) {
            Window.attributes.remove(attribute);
            wireframeAttributes.remove(geometry);
        }

        Window.bindingStates.releaseStatesOfGeometry(geometry);

        if (geometry is InstancedBufferGeometry) {
            geometry._maxInstanceCount = null;
        }

        Window.info.memory.geometries--;
    }

    public function get(object:DisplayObject, geometry:Geometry):Geometry {
        if (geometries.exists(geometry.id)) {
            return geometry;
        }

        geometry.addEventListener(Event.DISPOSE, onGeometryDispose);
        geometries[geometry.id] = geometry;
        Window.info.memory.geometries++;

        return geometry;
    }

    public function update(geometry:Geometry):Void {
        var geometryAttributes = geometry.attributes;

        // Updating index buffer in VAO now. See WebGLBindingStates.

        for (name in geometryAttributes) {
            Window.attributes.update(geometryAttributes[name], ARRAY_BUFFER);
        }

        // morph targets

        var morphAttributes = geometry.morphAttributes;

        for (name in morphAttributes) {
            var array = morphAttributes[name];
            for (i in 0...array.length) {
                Window.attributes.update(array[i], ARRAY_BUFFER);
            }
        }
    }

    public function updateWireframeAttribute(geometry:Geometry):Void {
        var indices:Array<Int> = [];
        var geometryIndex = geometry.index;
        var geometryPosition = geometry.attributes.get("position");
        var version:Int;

        if (geometryIndex != null) {
            var array = geometryIndex.array;
            version = geometryIndex.version;

            for (i in 0...array.length) {
                var a = array[i];
                var b = array[i + 1];
                var c = array[i + 2];

                indices.push(a, b, b, c, c, a);
            }
        } else if (geometryPosition != null) {
            var array = geometryPosition.array;
            version = geometryPosition.version;

            for (i in 0...(array.length / 3)) {
                var a = i;
                var b = i + 1;
                var c = i + 2;

                indices.push(a, b, b, c, c, a);
            }
        } else {
            return;
        }

        var attribute = new VertexBuffer3D(indices, 1);
        attribute.version = version;

        // Updating index buffer in VAO now. See WebGLBindingStates

        var previousAttribute = wireframeAttributes.get(geometry);
        if (previousAttribute != null) {
            Window.attributes.remove(previousAttribute);
        }

        wireframeAttributes.set(geometry, attribute);
    }

    public function getWireframeAttribute(geometry:Geometry):VertexBuffer3D {
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

class Geometry extends EventDispatcher {
    public var id:Int;
    public var index:IndexBuffer3D;
    public var attributes:HashMap<String,VertexBuffer3D>;
    public var morphAttributes:HashMap<String,Array<VertexBuffer3D>>;
}

class InstancedBufferGeometry extends Geometry {
    public var _maxInstanceCount:Int;
}

class Uint16BufferAttribute {
    public function new(data:Array<Int>, itemSize:Int) {}

    public var version:Int;
}

class Uint32BufferAttribute {
    public function new(data:Array<Int>, itemSize:Int) {}

    public var version:Int;
}

class WebGLBindingStates {
    public function releaseStatesOfGeometry(geometry:Geometry):Void {}
}

class WebGLAttributes {
    public function remove(attribute:VertexBuffer3D):Void {}

    public function update(attribute:VertexBuffer3D, bufferType:Int):Void {}
}

class WebGLMemoryInfo {
    public var geometries:Int;
}

class WebGLInfo {
    public var memory:WebGLMemoryInfo;
}