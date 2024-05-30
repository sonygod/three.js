class MeshBuilder {

	var crossOrigin:String;
	var geometryBuilder:GeometryBuilder;
	var materialBuilder:MaterialBuilder;

	public function new(manager:Manager) {

		this.crossOrigin = 'anonymous';
		this.geometryBuilder = new GeometryBuilder();
		this.materialBuilder = new MaterialBuilder(manager);

	}

	/**
	 * @param crossOrigin
	 * @return {MeshBuilder}
	 */
	public function setCrossOrigin(crossOrigin:String):MeshBuilder {

		this.crossOrigin = crossOrigin;
		return this;

	}

	/**
	 * @param data - parsed PMD/PMX data
	 * @param resourcePath
	 * @param onProgress
	 * @param onError
	 * @return {SkinnedMesh}
	 */
	public function build(data:Dynamic, resourcePath:String, onProgress:Void->Void, onError:Dynamic->Void):SkinnedMesh {

		var geometry = this.geometryBuilder.build(data);
		var material = this.materialBuilder
			.setCrossOrigin(this.crossOrigin)
			.setResourcePath(resourcePath)
			.build(data, geometry, onProgress, onError);

		var mesh = new SkinnedMesh(geometry, material);

		var skeleton = new Skeleton(initBones(mesh));
		mesh.bind(skeleton);

		// console.log( mesh ); // for console debug

		return mesh;

	}

}