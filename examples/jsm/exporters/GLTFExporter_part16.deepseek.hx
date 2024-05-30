class GLTFMeshGpuInstancing {

    var writer:GLTFExporter;
    var name:String;

    public function new(writer:GLTFExporter) {
        this.writer = writer;
        this.name = 'EXT_mesh_gpu_instancing';
    }

    public function writeNode(object:Dynamic, nodeDef:Dynamic) {
        if (!object.isInstancedMesh) return;

        var mesh = object;

        var translationAttr = new js.html.Float32Array(mesh.count * 3);
        var rotationAttr = new js.html.Float32Array(mesh.count * 4);
        var scaleAttr = new js.html.Float32Array(mesh.count * 3);

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
            TRANSLATION: this.writer.processAccessor(new BufferAttribute(translationAttr, 3)),
            ROTATION: this.writer.processAccessor(new BufferAttribute(rotationAttr, 4)),
            SCALE: this.writer.processAccessor(new BufferAttribute(scaleAttr, 3)),
        };

        if (mesh.instanceColor)
            attributes._COLOR_0 = this.writer.processAccessor(mesh.instanceColor);

        nodeDef.extensions = nodeDef.extensions || {};
        nodeDef.extensions[this.name] = {attributes:attributes};

        this.writer.extensionsUsed[this.name] = true;
        this.writer.extensionsRequired[this.name] = true;
    }
}