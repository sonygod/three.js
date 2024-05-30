class GLTFMeshGpuInstancing {
	public var writer:Writer;
	public var name:String = 'EXT_mesh_gpu_instancing';

	public function new(writer:Writer) {
		this.writer = writer;
	}

	public function writeNode(object:Dynamic, nodeDef:Dynamic) {
		if (!object.isInstancedMesh) return;

		var writer = this.writer;
		var mesh = object;

		var translationAttr = new Float32Array(mesh.count * 3);
		var rotationAttr = new Float32Array(mesh.count * 4);
		var scaleAttr = new Float32Array(mesh.count * 3);

		var matrix = new Matrix4();
		var position = new Vector3();
		var quaternion = new Quaternion();
		var scale = new Vector3();

		var i:Int;
		for (i = 0; i < mesh.count; i++) {
			mesh.getMatrixAt(i, matrix);
			matrix.decompose(position, quaternion, scale);

			position.toArray(translationAttr, i * 3);
			quaternion.toArray(rotationAttr, i * 4);
			scale.toArray(scaleAttr, i * 3);
		}

		var attributes = {
			'TRANSLATION': writer.processAccessor(new BufferAttribute(translationAttr, 3)),
			'ROTATION': writer.processAccessor(new BufferAttribute(rotationAttr, 4)),
			'SCALE': writer.processAccessor(new BufferAttribute(scaleAttr, 3))
		};

		if (mesh.instanceColor != null) {
			attributes['_COLOR_0'] = writer.processAccessor(mesh.instanceColor);
		}

		nodeDef.extensions = nodeDef.extensions or { };
		nodeDef.extensions[name] = { attributes: attributes };

		writer.extensionsUsed[name] = true;
		writer.extensionsRequired[name] = true;
	}
}