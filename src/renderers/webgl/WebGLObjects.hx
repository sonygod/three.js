package renderers.webgl;

import js.html.webgl.WebGLRenderingContext;
import js.html.webgl.Buffer;
import js.html.webgl.VertexArrayObject;
import haxe.ds.WeakMap;

class WebGLObjects {
    private var gl:WebGLRenderingContext;
    private var geometries:Geometries;
    private var attributes:Attributes;
    private var info:RenderInfo;
    private var updateMap:WeakMap<Dynamic, Int>;

    public function new(gl:WebGLRenderingContext, geometries:Geometries, attributes:Attributes, info:RenderInfo) {
        this.gl = gl;
        this.geometries = geometries;
        this.attributes = attributes;
        this.info = info;
        this.updateMap = new WeakMap();
    }

    private function update(object:Object3D):BufferGeometry {
        var frame:Int = info.render.frame;
        var geometry:Geometry = object.geometry;
        var bufferGeometry:BufferGeometry = geometries.get(object, geometry);

        // Update once per frame
        if (updateMap.get(bufferGeometry) != frame) {
            geometries.update(bufferGeometry);
            updateMap.set(bufferGeometry, frame);
        }

        if (object.isInstancedMesh) {
            if (!object.hasEventListener('dispose', onInstancedMeshDispose)) {
                object.addEventListener('dispose', onInstancedMeshDispose);
            }

            if (updateMap.get(object) != frame) {
                attributes.update(object.instanceMatrix, gl.ARRAY_BUFFER);
                if (object.instanceColor != null) {
                    attributes.update(object.instanceColor, gl.ARRAY_BUFFER);
                }
                updateMap.set(object, frame);
            }
        }

        if (object.isSkinnedMesh) {
            var skeleton:Skeleton = object.skeleton;
            if (updateMap.get(skeleton) != frame) {
                skeleton.update();
                updateMap.set(skeleton, frame);
            }
        }

        return bufferGeometry;
    }

    private function dispose():Void {
        updateMap = new WeakMap();
    }

    private function onInstancedMeshDispose(event:Event):Void {
        var instancedMesh:Object3D = event.target;
        instancedMesh.removeEventListener('dispose', onInstancedMeshDispose);
        attributes.remove(instancedMesh.instanceMatrix);
        if (instancedMesh.instanceColor != null) attributes.remove(instancedMesh.instanceColor);
    }

    public function toJSON():Dynamic {
        return {
            update: update,
            dispose: dispose
        };
    }
}

// Export the class
extern class WebGLObjects {}