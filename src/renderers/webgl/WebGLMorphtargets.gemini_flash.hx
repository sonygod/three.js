import {FloatType} from "../../constants";
import {DataArrayTexture} from "../../textures/DataArrayTexture";
import {Vector4} from "../../math/Vector4";
import {Vector2} from "../../math/Vector2";

class WebGLMorphtargets {

	private morphTextures:WeakMap<Dynamic, { count:Int, texture:DataArrayTexture, size:Vector2 }>;
	private morph:Vector4;

	public function new(gl:Dynamic, capabilities:Dynamic, textures:Dynamic) {
		this.morphTextures = new WeakMap();
		this.morph = new Vector4();
	}

	public function update(object:Dynamic, geometry:Dynamic, program:Dynamic) {

		var objectInfluences = object.morphTargetInfluences;

		// the following encodes morph targets into an array of data textures. Each layer represents a single morph target.

		var morphAttribute = geometry.morphAttributes.position || geometry.morphAttributes.normal || geometry.morphAttributes.color;
		var morphTargetsCount = (morphAttribute != null) ? morphAttribute.length : 0;

		var entry = this.morphTextures.get(geometry);

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

			// fill buffer

			var vertexDataStride = vertexDataCount * 4;

			for (var i = 0; i < morphTargetsCount; i++) {

				var morphTarget = morphTargets[i];
				var morphNormal = morphNormals[i];
				var morphColor = morphColors[i];

				var offset = width * height * 4 * i;

				for (var j = 0; j < morphTarget.count; j++) {

					var stride = j * vertexDataStride;

					if (hasMorphPosition) {

						this.morph.fromBufferAttribute(morphTarget, j);

						buffer[offset + stride + 0] = this.morph.x;
						buffer[offset + stride + 1] = this.morph.y;
						buffer[offset + stride + 2] = this.morph.z;
						buffer[offset + stride + 3] = 0;

					}

					if (hasMorphNormals) {

						this.morph.fromBufferAttribute(morphNormal, j);

						buffer[offset + stride + 4] = this.morph.x;
						buffer[offset + stride + 5] = this.morph.y;
						buffer[offset + stride + 6] = this.morph.z;
						buffer[offset + stride + 7] = 0;

					}

					if (hasMorphColors) {

						this.morph.fromBufferAttribute(morphColor, j);

						buffer[offset + stride + 8] = this.morph.x;
						buffer[offset + stride + 9] = this.morph.y;
						buffer[offset + stride + 10] = this.morph.z;
						buffer[offset + stride + 11] = (morphColor.itemSize == 4) ? this.morph.w : 1;

					}

				}

			}

			entry = {
				count: morphTargetsCount,
				texture: texture,
				size: new Vector2(width, height)
			};

			this.morphTextures.set(geometry, entry);

			function disposeTexture() {

				texture.dispose();

				this.morphTextures.delete(geometry);

				geometry.removeEventListener('dispose', disposeTexture);

			}

			geometry.addEventListener('dispose', disposeTexture);

		}

		//
		if (object.isInstancedMesh && object.morphTexture != null) {

			program.getUniforms().setValue(gl, 'morphTexture', object.morphTexture, textures);

		} else {

			var morphInfluencesSum = 0;

			for (var i = 0; i < objectInfluences.length; i++) {

				morphInfluencesSum += objectInfluences[i];

			}

			var morphBaseInfluence = geometry.morphTargetsRelative ? 1 : 1 - morphInfluencesSum;


			program.getUniforms().setValue(gl, 'morphTargetBaseInfluence', morphBaseInfluence);
			program.getUniforms().setValue(gl, 'morphTargetInfluences', objectInfluences);

		}

		program.getUniforms().setValue(gl, 'morphTargetsTexture', entry.texture, textures);
		program.getUniforms().setValue(gl, 'morphTargetsTextureSize', entry.size);

	}

}