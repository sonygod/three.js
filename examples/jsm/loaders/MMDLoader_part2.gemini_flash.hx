class MeshBuilder {

	var crossOrigin:String;
	var geometryBuilder:GeometryBuilder;
	var materialBuilder:MaterialBuilder;

	public function new(manager:Dynamic) {
		this.crossOrigin = 'anonymous';
		this.geometryBuilder = new GeometryBuilder();
		this.materialBuilder = new MaterialBuilder(manager);
	}

	/**
	 * @param {string} crossOrigin
	 * @return {MeshBuilder}
	 */
	public function setCrossOrigin(crossOrigin:String):MeshBuilder {
		this.crossOrigin = crossOrigin;
		return this;
	}

	/**
	 * @param {Object} data - parsed PMD/PMX data
	 * @param {string} resourcePath
	 * @param {function} onProgress
	 * @param {function} onError
	 * @return {SkinnedMesh}
	 */
	public function build(data:Dynamic, resourcePath:String, onProgress:Dynamic, onError:Dynamic):SkinnedMesh {
		var geometry = this.geometryBuilder.build(data);
		var material = this.materialBuilder
			.setCrossOrigin(this.crossOrigin)
			.setResourcePath(resourcePath)
			.build(data, geometry, onProgress, onError);

		var mesh = new SkinnedMesh(geometry, material);

		var skeleton = new Skeleton(initBones(mesh));
		mesh.bind(skeleton);

		// console.log(mesh); // for console debug

		return mesh;
	}

}

// Assuming initBones is a function that takes a SkinnedMesh and returns a Bone array
function initBones(mesh:SkinnedMesh):Array<Dynamic> {
	// Implement initBones logic here
	return [];
}