import js.WeakMap;
import js.lib.Function;

class WebGLObjects {
    private var gl:Dynamic;
    private var geometries:Dynamic;
    private var attributes:Dynamic;
    private var info:Dynamic;
    private var updateMap:WeakMap<Dynamic, Int>;

    public function new(gl:Dynamic, geometries:Dynamic, attributes:Dynamic, info:Dynamic) {
        this.gl = gl;
        this.geometries = geometries;
        this.attributes = attributes;
        this.info = info;
        this.updateMap = new WeakMap();
    }

    public function update(object:Dynamic):Dynamic {
        var frame:Int = info.render.frame;
        var geometry:Dynamic = object.geometry;
        var buffergeometry:Dynamic = geometries.get(object, geometry);

        if (updateMap.get(buffergeometry) !== frame) {
            geometries.update(buffergeometry);
            updateMap.set(buffergeometry, frame);
        }

        if (object.isInstancedMesh) {
            if (object.hasEventListener('dispose', onInstancedMeshDispose) === false) {
                object.addEventListener('dispose', onInstancedMeshDispose);
            }

            if (updateMap.get(object) !== frame) {
                attributes.update(object.instanceMatrix, gl.ARRAY_BUFFER);
                if (object.instanceColor !== null) {
                    attributes.update(object.instanceColor, gl.ARRAY_BUFFER);
                }
                updateMap.set(object, frame);
            }
        }

        if (object.isSkinnedMesh) {
            var skeleton:Dynamic = object.skeleton;
            if (updateMap.get(skeleton) !== frame) {
                skeleton.update();
                updateMap.set(skeleton, frame);
            }
        }

        return buffergeometry;
    }

    public function dispose() {
        updateMap = new WeakMap();
    }

    private function onInstancedMeshDispose(event:Dynamic) {
        var instancedMesh:Dynamic = event.target;
        instancedMesh.removeEventListener('dispose', onInstancedMeshDispose);
        attributes.remove(instancedMesh.instanceMatrix);
        if (instancedMesh.instanceColor !== null) attributes.remove(instancedMesh.instanceColor);
    }
}