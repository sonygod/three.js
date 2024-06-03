import haxe.io.Bytes;
import three.extras.core.InstancedMesh;
import three.extras.objects.Mesh;
import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.core.BufferAttribute;
import three.core.Object3D;

class GLTFMeshGpuInstancing {

    public var writer:Dynamic;
    public var name:String = 'EXT_mesh_gpu_instancing';

    public function new(writer:Dynamic) {
        this.writer = writer;
    }

    public function writeNode(object:Object3D, nodeDef:Dynamic) {
        if (!cast(object, InstancedMesh)) return;

        var mesh = cast(object, InstancedMesh);

        var translationAttr = new Float32Array(mesh.count * 3);
        var rotationAttr = new Float32Array(mesh.count * 4);
        var scaleAttr = new Float32Array(mesh.count * 3);

        var matrix = new Matrix4();
        var position = new Vector3();
        var quaternion = new Quaternion();
        var scale = new Vector3();

        for (i in 0...mesh.count) {
            mesh.getMatrixAt(i, matrix);
            matrix.decompose(position, quaternion, scale);

            position.toArray(translationAttr, i * 3);
            quaternion.toArray(rotationAttr, i * 4);
            scale.toArray(scaleAttr, i * 3);
        }

        var attributes = {
            TRANSLATION: writer.processAccessor(new BufferAttribute(translationAttr, 3)),
            ROTATION: writer.processAccessor(new BufferAttribute(rotationAttr, 4)),
            SCALE: writer.processAccessor(new BufferAttribute(scaleAttr, 3)),
        };

        if (mesh.instanceColor != null)
            attributes._COLOR_0 = writer.processAccessor(mesh.instanceColor);

        nodeDef.extensions = nodeDef.extensions != null ? nodeDef.extensions : {};
        nodeDef.extensions[this.name] = {attributes: attributes};

        writer.extensionsUsed[this.name] = true;
        writer.extensionsRequired[this.name] = true;
    }
}