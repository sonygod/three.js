import haxe.ds.WeakMap;
import js.html.webgl.WebGLRenderingContext;

class WebGLObjects {
    private var updateMap:WeakMap<Dynamic, Dynamic>;
    private var gl:WebGLRenderingContext;
    private var geometries:Dynamic;
    private var attributes:Dynamic;
    private var info:Dynamic;

    public function new(gl:WebGLRenderingContext, geometries:Dynamic, attributes:Dynamic, info:Dynamic) {
        this.gl = gl;
        this.geometries = geometries;
        this.attributes = attributes;
        this.info = info;
        this.updateMap = new WeakMap();
    }

    public function update(object:Dynamic):Dynamic {
        var frame = this.info.render.frame;
        var geometry = object.geometry;
        var buffergeometry = this.geometries.get(object, geometry);

        if (this.updateMap.get(buffergeometry) !== frame) {
            this.geometries.update(buffergeometry);
            this.updateMap.set(buffergeometry, frame);
        }

        if (object.isInstancedMesh) {
            if (!object.hasEventListener('dispose', this.onInstancedMeshDispose)) {
                object.addEventListener('dispose', this.onInstancedMeshDispose);
            }

            if (this.updateMap.get(object) !== frame) {
                this.attributes.update(object.instanceMatrix, this.gl.ARRAY_BUFFER);

                if (object.instanceColor != null) {
                    this.attributes.update(object.instanceColor, this.gl.ARRAY_BUFFER);
                }

                this.updateMap.set(object, frame);
            }
        }

        if (object.isSkinnedMesh) {
            var skeleton = object.skeleton;

            if (this.updateMap.get(skeleton) !== frame) {
                skeleton.update();
                this.updateMap.set(skeleton, frame);
            }
        }

        return buffergeometry;
    }

    public function dispose() {
        this.updateMap = new WeakMap();
    }

    public function onInstancedMeshDispose(event:Dynamic) {
        var instancedMesh = event.target;

        instancedMesh.removeEventListener('dispose', this.onInstancedMeshDispose);

        this.attributes.remove(instancedMesh.instanceMatrix);

        if (instancedMesh.instanceColor != null) this.attributes.remove(instancedMesh.instanceColor);
    }
}