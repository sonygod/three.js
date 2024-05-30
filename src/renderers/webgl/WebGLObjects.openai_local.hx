package three.renderers.webgl;

import js.html.webgl.RenderingContext;

class WebGLObjects {

    var gl:RenderingContext;
    var geometries:Geometries;
    var attributes:Attributes;
    var info:Info;

    var updateMap:haxe.ds.WeakMap<Dynamic, Int>;

    public function new(gl:RenderingContext, geometries:Geometries, attributes:Attributes, info:Info) {
        this.gl = gl;
        this.geometries = geometries;
        this.attributes = attributes;
        this.info = info;

        updateMap = new haxe.ds.WeakMap<Dynamic, Int>();
    }

    public function update(object:Object3D):BufferGeometry {
        var frame:Int = info.render.frame;

        var geometry:Geometry = object.geometry;
        var buffergeometry:BufferGeometry = geometries.get(object, geometry);

        // Update once per frame
        if (!updateMap.exists(buffergeometry) || updateMap.get(buffergeometry) != frame) {
            geometries.update(buffergeometry);
            updateMap.set(buffergeometry, frame);
        }

        if (object.isInstancedMesh) {
            if (!object.hasEventListener('dispose', onInstancedMeshDispose)) {
                object.addEventListener('dispose', onInstancedMeshDispose);
            }

            if (!updateMap.exists(object) || updateMap.get(object) != frame) {
                attributes.update(object.instanceMatrix, gl.ARRAY_BUFFER);

                if (object.instanceColor != null) {
                    attributes.update(object.instanceColor, gl.ARRAY_BUFFER);
                }

                updateMap.set(object, frame);
            }
        }

        if (object.isSkinnedMesh) {
            var skeleton:Skeleton = object.skeleton;

            if (!updateMap.exists(skeleton) || updateMap.get(skeleton) != frame) {
                skeleton.update();
                updateMap.set(skeleton, frame);
            }
        }

        return buffergeometry;
    }

    public function dispose():Void {
        updateMap = new haxe.ds.WeakMap<Dynamic, Int>();
    }

    private function onInstancedMeshDispose(event:Event):Void {
        var instancedMesh:Object3D = cast event.target;

        instancedMesh.removeEventListener('dispose', onInstancedMeshDispose);

        attributes.remove(instancedMesh.instanceMatrix);

        if (instancedMesh.instanceColor != null) {
            attributes.remove(instancedMesh.instanceColor);
        }
    }

}