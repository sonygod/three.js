import three.extras.SSAARenderPass;
import three.textures.HalfFloatType;
import three.renderers.WebGLRenderTarget;

/**
 *
 * Temporal Anti-Aliasing Render Pass
 *
 * When there is no motion in the scene, the TAA render pass accumulates jittered camera samples across frames to create a high quality anti-aliased result.
 *
 * References:
 *
 * TODO: Add support for motion vector pas so that accumulation of samples across frames can occur on dynamics scenes.
 *
 */
class TAARenderPass extends SSAARenderPass {

	public var sampleLevel:Int = 0;
	public var accumulate:Bool = false;
	public var accumulateIndex:Int = -1;

	public function new( scene:three.scenes.Scene, camera:three.cameras.Camera, clearColor:Int, clearAlpha:Float ) {
		super( scene, camera, clearColor, clearAlpha );
	}

	override public function render( renderer:three.renderers.WebGLRenderer, writeBuffer:WebGLRenderTarget, readBuffer:WebGLRenderTarget, deltaTime:Float ):Void {
		if ( ! accumulate ) {
			super.render( renderer, writeBuffer, readBuffer, deltaTime );
			accumulateIndex = - 1;
			return;
		}

		const jitterOffsets = _JitterVectors[ 5 ];

		if ( sampleRenderTarget == null ) {
			sampleRenderTarget = new WebGLRenderTarget( readBuffer.width, readBuffer.height, { type: HalfFloatType } );
			sampleRenderTarget.texture.name = 'TAARenderPass.sample';
		}

		if ( holdRenderTarget == null ) {
			holdRenderTarget = new WebGLRenderTarget( readBuffer.width, readBuffer.height, { type: HalfFloatType } );
			holdRenderTarget.texture.name = 'TAARenderPass.hold';
		}

		if ( accumulateIndex == - 1 ) {
			super.render( renderer, holdRenderTarget, readBuffer, deltaTime );
			accumulateIndex = 0;
		}

		const autoClear = renderer.autoClear;
		renderer.autoClear = false;

		renderer.getClearColor( _oldClearColor );
		const oldClearAlpha = renderer.getClearAlpha();

		const sampleWeight = 1.0 / jitterOffsets.length;

		if ( accumulateIndex >= 0 && accumulateIndex < jitterOffsets.length ) {
			copyUniforms[ 'opacity' ].value = sampleWeight;
			copyUniforms[ 'tDiffuse' ].value = writeBuffer.texture;

			// render the scene multiple times, each slightly jitter offset from the last and accumulate the results.
			const numSamplesPerFrame = Math.pow( 2, sampleLevel );
			for ( i in 0...numSamplesPerFrame ) {
				const j = accumulateIndex;
				const jitterOffset = jitterOffsets[ j ];

				if ( cast camera.setViewOffset : three.cameras.OrthographicCamera ) {
					camera.setViewOffset( readBuffer.width, readBuffer.height,
						jitterOffset[ 0 ] * 0.0625, jitterOffset[ 1 ] * 0.0625, // 0.0625 = 1 / 16
						readBuffer.width, readBuffer.height );
				}

				renderer.setRenderTarget( writeBuffer );
				renderer.setClearColor( clearColor, clearAlpha );
				renderer.clear();
				renderer.render( scene, camera );

				renderer.setRenderTarget( sampleRenderTarget );
				if ( accumulateIndex == 0 ) {
					renderer.setClearColor( 0x000000, 0.0 );
					renderer.clear();
				}

				fsQuad.render( renderer );

				accumulateIndex ++;

				if ( accumulateIndex >= jitterOffsets.length ) break;
			}

			if ( cast camera.clearViewOffset : three.cameras.OrthographicCamera ) camera.clearViewOffset();
		}

		renderer.setClearColor( clearColor, clearAlpha );
		const accumulationWeight = accumulateIndex * sampleWeight;

		if ( accumulationWeight > 0 ) {
			copyUniforms[ 'opacity' ].value = 1.0;
			copyUniforms[ 'tDiffuse' ].value = sampleRenderTarget.texture;
			renderer.setRenderTarget( writeBuffer );
			renderer.clear();
			fsQuad.render( renderer );
		}

		if ( accumulationWeight < 1.0 ) {
			copyUniforms[ 'opacity' ].value = 1.0 - accumulationWeight;
			copyUniforms[ 'tDiffuse' ].value = holdRenderTarget.texture;
			renderer.setRenderTarget( writeBuffer );
			fsQuad.render( renderer );
		}

		renderer.autoClear = autoClear;
		renderer.setClearColor( _oldClearColor, oldClearAlpha );
	}

	override public function dispose():Void {
		super.dispose();
		if ( holdRenderTarget != null ) holdRenderTarget.dispose();
	}
}

const _JitterVectors:Array<Array<Array<Int>>> = [
	[
		[ 0, 0 ]
	],
	[
		[ 4, 4 ], [ - 4, - 4 ]
	],
	[
		[ - 2, - 6 ], [ 6, - 2 ], [ - 6, 2 ], [ 2, 6 ]
	],
	[
		[ 1, - 3 ], [ - 1, 3 ], [ 5, 1 ], [ - 3, - 5 ],
		[ - 5, 5 ], [ - 7, - 1 ], [ 3, 7 ], [ 7, - 7 ]
	],
	[
		[ 1, 1 ], [ - 1, - 3 ], [ - 3, 2 ], [ 4, - 1 ],
		[ - 5, - 2 ], [ 2, 5 ], [ 5, 3 ], [ 3, - 5 ],
		[ - 2, 6 ], [ 0, - 7 ], [ - 4, - 6 ], [ - 6, 4 ],
		[ - 8, 0 ], [ 7, - 4 ], [ 6, 7 ], [ - 7, - 8 ]
	],
	[
		[ - 4, - 7 ], [ - 7, - 5 ], [ - 3, - 5 ], [ - 5, - 4 ],
		[ - 1, - 4 ], [ - 2, - 2 ], [ - 6, - 1 ], [ - 4, 0 ],
		[ - 7, 1 ], [ - 1, 2 ], [ - 6, 3 ], [ - 3, 3 ],
		[ - 7, 6 ], [ - 3, 6 ], [ - 5, 7 ], [ - 1, 7 ],
		[ 5, - 7 ], [ 1, - 6 ], [ 6, - 5 ], [ 4, - 4 ],
		[ 2, - 3 ], [ 7, - 2 ], [ 1, - 1 ], [ 4, - 1 ],
		[ 2, 1 ], [ 6, 2 ], [ 0, 4 ], [ 4, 4 ],
		[ 2, 5 ], [ 7, 5 ], [ 5, 6 ], [ 3, 7 ]
	]
];

class TAARenderPass {
	public static function main():Void {
		// Add your Haxe code here
	}
}