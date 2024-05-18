class MeshBuilder {

	constructor( manager ) {

		this.crossOrigin = 'anonymous';
		this.geometryBuilder = new GeometryBuilder();
		this.materialBuilder = new MaterialBuilder( manager );

	}

	/**
	 * @param {string} crossOrigin
	 * @return {MeshBuilder}
	 */
	setCrossOrigin( crossOrigin ) {

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
	build( data, resourcePath, onProgress, onError ) {

		const geometry = this.geometryBuilder.build( data );
		const material = this.materialBuilder
			.setCrossOrigin( this.crossOrigin )
			.setResourcePath( resourcePath )
			.build( data, geometry, onProgress, onError );

		const mesh = new SkinnedMesh( geometry, material );

		const skeleton = new Skeleton( initBones( mesh ) );
		mesh.bind( skeleton );

		// console.log( mesh ); // for console debug

		return mesh;

	}

}