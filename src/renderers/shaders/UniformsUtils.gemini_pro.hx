import ColorManagement from '../../math/ColorManagement';

/**
 * Uniform Utilities
 */

class UniformsUtils {

	public static clone( src:Dynamic ):Dynamic {

		var dst = {};

		for ( u in src ) {

			dst[ u ] = {};

			for ( p in src[ u ] ) {

				var property = src[ u ][ p ];

				if ( property && ( property.isColor ||
					property.isMatrix3 || property.isMatrix4 ||
					property.isVector2 || property.isVector3 || property.isVector4 ||
					property.isTexture || property.isQuaternion ) ) {

					if ( property.isRenderTargetTexture ) {

						console.warn( 'UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().' );
						dst[ u ][ p ] = null;

					} else {

						dst[ u ][ p ] = property.clone();

					}

				} else if ( Std.is( property, Array ) ) {

					dst[ u ][ p ] = property.copy();

				} else {

					dst[ u ][ p ] = property;

				}

			}

		}

		return dst;

	}

	public static merge( uniforms:Array<Dynamic> ):Dynamic {

		var merged = {};

		for ( u in 0...uniforms.length ) {

			var tmp = this.clone( uniforms[ u ] );

			for ( p in tmp ) {

				merged[ p ] = tmp[ p ];

			}

		}

		return merged;

	}

	public static cloneGroups( src:Array<Dynamic> ):Array<Dynamic> {

		var dst = [];

		for ( u in 0...src.length ) {

			dst.push( src[ u ].clone() );

		}

		return dst;

	}

	public static getUnlitUniformColorSpace( renderer:Dynamic ):String {

		var currentRenderTarget = renderer.getRenderTarget();

		if ( currentRenderTarget == null ) {

			// https://github.com/mrdoob/three.js/pull/23937#issuecomment-1111067398
			return renderer.outputColorSpace;

		}

		// https://github.com/mrdoob/three.js/issues/27868
		if ( currentRenderTarget.isXRRenderTarget ) {

			return currentRenderTarget.texture.colorSpace;

		}

		return ColorManagement.workingColorSpace;

	}

}

export default UniformsUtils;