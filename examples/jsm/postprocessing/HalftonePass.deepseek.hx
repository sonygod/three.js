import three.ShaderMaterial;
import three.UniformsUtils;
import three.examples.jsm.postprocessing.Pass;
import three.examples.jsm.postprocessing.FullScreenQuad;
import three.examples.jsm.shaders.HalftoneShader;

/**
 * RGB Halftone pass for three.js effects composer. Requires HalftoneShader.
 */

class HalftonePass extends Pass {

	public function new(width:Float, height:Float, params:Dynamic) {

		super();

	 	this.uniforms = UniformsUtils.clone( HalftoneShader.uniforms );
	 	this.material = new ShaderMaterial( {
	 		uniforms: this.uniforms,
	 		fragmentShader: HalftoneShader.fragmentShader,
	 		vertexShader: HalftoneShader.vertexShader
	 	} );

		// set params
		this.uniforms.width.value = width;
		this.uniforms.height.value = height;

		for ( key in params ) {

			if ( params.hasOwnProperty( key ) && this.uniforms.hasOwnProperty( key ) ) {

				this.uniforms[ key ].value = params[ key ];

			}

		}

		this.fsQuad = new FullScreenQuad( this.material );

	}

	public function render(renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic/*, deltaTime:Float, maskActive:Bool*/) {

 		this.material.uniforms[ 'tDiffuse' ].value = readBuffer.texture;

 		if ( this.renderToScreen ) {

 			renderer.setRenderTarget( null );
 			this.fsQuad.render( renderer );

		} else {

 			renderer.setRenderTarget( writeBuffer );
 			if ( this.clear ) renderer.clear();
			this.fsQuad.render( renderer );

		}

 	}

 	public function setSize(width:Float, height:Float) {

 		this.uniforms.width.value = width;
 		this.uniforms.height.value = height;

 	}

	public function dispose() {

		this.material.dispose();

		this.fsQuad.dispose();

	}

}