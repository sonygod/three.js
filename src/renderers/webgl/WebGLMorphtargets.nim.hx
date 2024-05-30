import three.constants.FloatType;
import three.textures.DataArrayTexture;
import three.math.Vector4;
import three.math.Vector2;

class WebGLMorphtargets {

	private var morphTextures:Map<Geometry, {
		count: Int,
		texture: DataArrayTexture,
		size: Vector2
	}>;
	private var morph:Vector4;

	public function new(gl:WebGLRenderingContext, capabilities:WebGLCapabilities, textures:WebGLTextures) {
		morphTextures = new Map();
		morph = new Vector4();
	}

	public function update(object:Object3D, geometry:Geometry, program:WebGLProgram) {
		var objectInfluences = object.morphTargetInfluences;

		var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
		var morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;

		var entry = morphTextures.get(geometry);

		if (entry == null || entry.count != morphTargetsCount) {
			if (entry != null) entry.texture.dispose();

			var hasMorphPosition = geometry.morphAttributes.position != null;
			var hasMorphNormals = geometry.morphAttributes.normal != null;
			var hasMorphColors = geometry.morphAttributes.color != null;

			var morphTargets = geometry.morphAttributes.position || [];
			var morphNormals = geometry.morphAttributes.normal || [];
			var morphColors = geometry.morphAttributes.color || [];

			var vertexDataCount = 0;

			if (hasMorphPosition) vertexDataCount = 1;
			if (hasMorphNormals) vertexDataCount = 2;
			if (hasMorphColors) vertexDataCount = 3;

			var width = geometry.attributes.position.count * vertexDataCount;
			var height = 1;

			if (width > capabilities.maxTextureSize) {
				height = Math.ceil(width / capabilities.maxTextureSize);
				width = capabilities.maxTextureSize;
			}

			var buffer = new Float32Array(width * height * 4 * morphTargetsCount);

			var texture = new DataArrayTexture(buffer, width, height, morphTargetsCount);
			texture.type = FloatType;
			texture.needsUpdate = true;

			var vertexDataStride = vertexDataCount * 4;

			for (i in 0...morphTargetsCount) {
				var morphTarget = morphTargets[i];
				var morphNormal = morphNormals[i];
				var morphColor = morphColors[i];

				var offset = width * height * 4 * i;

				for (j in 0...morphTarget.count) {
					var stride = j * vertexDataStride;

					if (hasMorphPosition) {
						morph.fromBufferAttribute(morphTarget, j);

						buffer[offset + stride + 0] = morph.x;
						buffer[offset + stride + 1] = morph.y;
						buffer[offset + stride + 2] = morph.z;
						buffer[offset + stride + 3] = 0;
					}

					if (hasMorphNormals) {
						morph.fromBufferAttribute(morphNormal, j);

						buffer[offset + stride + 4] = morph.x;
						buffer[offset + stride + 5] = morph.y;
						buffer[offset + stride + 6] = morph.z;
						buffer[offset + stride + 7] = 0;
					}

					if (hasMorphColors) {
						morph.fromBufferAttribute(morphColor, j);

						buffer[offset + stride + 8] = morph.x;
						buffer[offset + stride + 9] = morph.y;
						buffer[offset + stride + 10] = morph.z;
						buffer[offset + stride + 11] = (morphColor.itemSize == 4) ? morph.w : 1;
					}
				}
			}

			entry = {
				count: morphTargetsCount,
				texture: texture,
				size: new Vector2(width, height)
			};

			morphTextures.set(geometry, entry);

			function disposeTexture() {
				texture.dispose();

				morphTextures.remove(geometry);

				geometry.removeEventListener("dispose", disposeTexture);
			}

			geometry.addEventListener("dispose", disposeTexture);
		}

		if (object.isInstancedMesh && object.morphTexture != null) {
			program.getUniforms().setValue(gl, "morphTexture", object.morphTexture, textures);
		} else {
			var morphInfluencesSum = 0;

			for (i in 0...objectInfluences.length) {
				morphInfluencesSum += objectInfluences[i];
			}

			var morphBaseInfluence = geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;

			program.getUniforms().setValue(gl, "morphTargetBaseInfluence", morphBaseInfluence);
			program.getUniforms().setValue(gl, "morphTargetInfluences", objectInfluences);
		}

		program.getUniforms().setValue(gl, "morphTargetsTexture", entry.texture, textures);
		program.getUniforms().setValue(gl, "morphTargetsTextureSize", entry.size);
	}
}