package three.js.examples.jsm.exporters;

class GLTFMeshGpuInstancing {
    private var writer:Dynamic;
    private var name:String;

    public function new(writer:Dynamic) {
        this.writer = writer;
        this.name = 'EXT_mesh_gpu_instancing';
    }

    public function writeNode(object:Dynamic, nodeDef:Dynamic) {
        if (!object.isInstancedMesh) return;

        var writer:Dynamic = this.writer;
        var mesh:Dynamic = object;

        var translationAttr:Array<Float> = new Array<Float>();
        translationAttr.resize(mesh.count * 3);
        var rotationAttr:Array<Float> = new Array<Float>();
        rotationAttr.resize(mesh.count * 4);
        var scaleAttr:Array<Float> = new Array<Float>();
        scaleAttr.resize(mesh.count * 3);

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
        nodeDef.extensions[name] = { attributes: attributes };

        writer.extensionsUsed[name] = true;
        writer.extensionsRequired[name] = true;
    }
}