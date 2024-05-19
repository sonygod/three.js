package three.js.examples.jm.exporters;

import haxe.io.Float32Array;
import three.js.Matrix4;
import three.js.Vector3;
import three.js.Quaternion;
import three.js.BufferAttribute;

class GLTFMeshGpuInstancing {

    public var writer:Dynamic;
    public var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'EXT_mesh_gpu_instancing';
    }

    public function writeNode(object:Dynamic, nodeDef:Dynamic) {
        if (!object.isInstancedMesh) return;

        var writer:Dynamic = this.writer;
        var mesh:Dynamic = object;

        var translationAttr:Float32Array = new Float32Array(mesh.count * 3);
        var rotationAttr:Float32Array = new Float32Array(mesh.count * 4);
        var scaleAttr:Float32Array = new Float32Array(mesh.count * 3);

        var matrix:Matrix4 = new Matrix4();
        var position:Vector3 = new Vector3();
        var quaternion:Quaternion = new Quaternion();
        var scale:Vector3 = new Vector3();

        for (i in 0...mesh.count) {
            mesh.getMatrixAt(i, matrix);
            matrix.decompose(position, quaternion, scale);

            position.toArray(translationAttr, i * 3);
            quaternion.toArray(rotationAttr, i * 4);
            scale.toArray(scaleAttr, i * 3);
        }

        var attributes:Dynamic = {
            TRANSLATION: writer.processAccessor(new BufferAttribute(translationAttr, 3)),
            ROTATION: writer.processAccessor(new BufferAttribute(rotationAttr, 4)),
            SCALE: writer.processAccessor(new BufferAttribute(scaleAttr, 3)),
        };

        if (mesh.instanceColor != null)
            attributes._COLOR_0 = writer.processAccessor(mesh.instanceColor);

        nodeDef.extensions = nodeDef.extensions || {};
        nodeDef.extensions[this.name] = { attributes: attributes };

        writer.extensionsUsed[this.name] = true;
        writer.extensionsRequired[this.name] = true;
    }
}