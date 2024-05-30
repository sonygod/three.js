class GLTFMeshGpuInstancing {

	var writer:GLTFExporter;
	var name:String;

	public function new( writer:GLTFExporter ) {

		this.writer = writer;
		this.name = 'EXT_mesh_gpu_instancing';

	}

	public function writeNode( object:Dynamic, nodeDef:Dynamic ) {

		if ( !Std.is(object, InstancedMesh)) return;

		var writer = this.writer;

		var mesh = cast(object, InstancedMesh);

		var translationAttr:Float32Array = new Float32Array(mesh.count * 3);
		var rotationAttr:Float32Array = new Float32Array(mesh.count * 4);
		var scaleAttr:Float32Array = new Float32Array(mesh.count * 3);

		var matrix:Matrix4 = new Matrix4();
		var position:Vector3 = new Vector3();
		var quaternion:Quaternion = new Quaternion();
		var scale:Vector3 = new Vector3();

		for ( i in 0...mesh.count ) {

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

		nodeDef.extensions = nodeDef.extensions != null ? nodeDef.extensions : {};
		nodeDef.extensions[this.name] = {attributes:attributes};

		writer.extensionsUsed[this.name] = true;
		writer.extensionsRequired[this.name] = true;

	}

}