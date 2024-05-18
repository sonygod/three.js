class WebXRDepthSensing {

	constructor() {

		this.texture = null;
		this.mesh = null;

		this.depthNear = 0;
		this.depthFar = 0;

	}

	init( renderer, depthData, renderState ) {

		if ( this.texture === null ) {

			const texture = new Texture();

			const texProps = renderer.properties.get( texture );
			texProps.__webglTexture = depthData.texture;

			if ( ( depthData.depthNear != renderState.depthNear ) || ( depthData.depthFar != renderState.depthFar ) ) {

				this.depthNear = depthData.depthNear;
				this.depthFar = depthData.depthFar;

			}

			this.texture = texture;

		}

	}

	render( renderer, cameraXR ) {

		if ( this.texture !== null ) {

			if ( this.mesh === null ) {

				const viewport = cameraXR.cameras[ 0 ].viewport;
				const material = new ShaderMaterial( {
					vertexShader: _occlusion_vertex,
					fragmentShader: _occlusion_fragment,
					uniforms: {
						depthColor: { value: this.texture },
						depthWidth: { value: viewport.z },
						depthHeight: { value: viewport.w }
					}
				} );

				this.mesh = new Mesh( new PlaneGeometry( 20, 20 ), material );

			}

			renderer.render( this.mesh, cameraXR );

		}

	}

	reset() {

		this.texture = null;
		this.mesh = null;

	}

}