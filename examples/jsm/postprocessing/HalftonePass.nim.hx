import three.js.examples.jsm.postprocessing.Pass;
import three.js.examples.jsm.postprocessing.FullScreenQuad;
import three.js.examples.jsm.shaders.HalftoneShader;
import three.js.ShaderMaterial;
import three.js.UniformsUtils;

/**
 * RGB Halftone pass for three.js effects composer. Requires HalftoneShader.
 */

class HalftonePass extends Pass {

	public var uniforms:Dynamic;
	public var material:ShaderMaterial;
	public var fsQuad:FullScreenQuad;

	public function new( width:Float, height:Float, params:Dynamic ) {

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

	public function render( renderer:Dynamic, writeBuffer:Dynamic, readBuffer:Dynamic/*, deltaTime:Dynamic, maskActive:Dynamic*/ ) {

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

 	public function setSize( width:Float, height:Float ) {

 		this.uniforms.width.value = width;
 		this.uniforms.height.value = height;

 	}

	public function dispose() {

		this.material.dispose();

		this.fsQuad.dispose();

	}

}