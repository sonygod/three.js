import three.constants.FloatType;
import three.textures.DataArrayTexture;
import three.math.Vector4;
import three.math.Vector2;

class WebGLMorphtargets {

	public static var morphTextures:WeakMap<Dynamic, {count:Int, texture:DataArrayTexture, size:Vector2}> = new WeakMap();
	public static var morph:Vector4 = new Vector4();

	public static function update(object:Dynamic, geometry:Dynamic, program:Dynamic):Void {

		var objectInfluences = object.morphTargetInfluences;

		// the following encodes morph targets into an array of data textures. Each layer represents a single morph target.

		var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
		var morphTargetsCount:Int = ( morphAttribute != null ) ? morphAttribute.length : 0;

		var entry = morphTextures.get(geometry);

		if ( entry == null || entry.count != morphTargetsCount ) {

			if ( entry != null ) entry.texture.dispose();

			var hasMorphPosition = geometry.morphAttributes.position != null;
			var hasMorphNormals = geometry.morphAttributes.normal != null;
			var hasMorphColors = geometry.morphAttributes.color != null;

			var morphTargets = geometry.morphAttributes.position || [];
			var morphNormals = geometry.morphAttributes.normal || [];
			var morphColors = geometry.morphAttributes.color || [];

			var vertexDataCount:Int = 0;

			if ( hasMorphPosition ) vertexDataCount = 1;
			if ( hasMorphNormals ) vertexDataCount = 2;
			if ( hasMorphColors ) vertexDataCount = 3;

			var width:Int = geometry.attributes.position.count * vertexDataCount;
			var height:Int = 1;

			if ( width > capabilities.maxTextureSize ) {

				height = Math.ceil( width / capabilities.maxTextureSize );
				width = capabilities.maxTextureSize;

			}

			var buffer = new Float32Array( width * height * 4 * morphTargetsCount );

			var texture = new DataArrayTexture( buffer, width, height, morphTargetsCount );
			texture.type = FloatType;
			texture.needsUpdate = true;

			// fill buffer

			var vertexDataStride = vertexDataCount * 4;

			for ( var i in 0...morphTargetsCount ) {

				var morphTarget = morphTargets[i];
				var morphNormal = morphNormals[i];
				var morphColor = morphColors[i];

				var offset = width * height * 4 * i;

				for ( var j in 0...morphTarget.count ) {

					var stride = j * vertexDataStride;

					if ( hasMorphPosition ) {

						morph.fromBufferAttribute( morphTarget, j );

						buffer[ offset + stride + 0 ] = morph.x;
						buffer[ offset + stride + 1 ] = morph.y;
						buffer[ offset + stride + 2 ] = morph.z;
						buffer[ offset + stride + 3 ] = 0;

					}

					if ( hasMorphNormals ) {

						morph.fromBufferAttribute( morphNormal, j );

						buffer[ offset + stride + 4 ] = morph.x;
						buffer[ offset + stride + 5 ] = morph.y;
						buffer[ offset + stride + 6 ] = morph.z;
						buffer[ offset + stride + 7 ] = 0;

					}

					if ( hasMorphColors ) {

						morph.fromBufferAttribute( morphColor, j );

						buffer[ offset + stride + 8 ] = morph.x;
						buffer[ offset + stride + 9 ] = morph.y;
						buffer[ offset + stride + 10 ] = morph.z;
						buffer[ offset + stride + 11 ] = ( morphColor.itemSize == 4 ) ? morph.w : 1;

					}

				}

			}

			entry = {
				count: morphTargetsCount,
				texture: texture,
				size: new Vector2( width, height )
			};

			morphTextures.set( geometry, entry );

			function disposeTexture() {

				texture.dispose();

				morphTextures.delete( geometry );

				geometry.removeEventListener( 'dispose', disposeTexture );

			}

			geometry.addEventListener( 'dispose', disposeTexture );

		}

		//
		if ( object.isInstancedMesh && object.morphTexture != null ) {

			program.getUniforms().setValue( gl, 'morphTexture', object.morphTexture, textures );

		} else {

			var morphInfluencesSum:Float = 0;

			for ( var i in 0...objectInfluences.length ) {

				morphInfluencesSum += objectInfluences[ i ];

			}

			var morphBaseInfluence = geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;


			program.getUniforms().setValue( gl, 'morphTargetBaseInfluence', morphBaseInfluence );
			program.getUniforms().setValue( gl, 'morphTargetInfluences', objectInfluences );

		}

		program.getUniforms().setValue( gl, 'morphTargetsTexture', entry.texture, textures );
		program.getUniforms().setValue( gl, 'morphTargetsTextureSize', entry.size );

	}

}