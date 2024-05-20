import three.math.ColorManagement;

/**
 * Uniform Utilities
 */

function cloneUniforms(src:Dynamic):Dynamic {

	var dst = {};

	for (u in src) {

		dst[u] = {};

		for (p in src[u]) {

			var property = src[u][p];

			if (property != null && (property.isColor ||
				property.isMatrix3 || property.isMatrix4 ||
				property.isVector2 || property.isVector3 || property.isVector4 ||
				property.isTexture || property.isQuaternion)) {

				if (property.isRenderTargetTexture) {

					trace('UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().');
					dst[u][p] = null;

				} else {

					dst[u][p] = property.clone();

				}

			} else if (Std.is(property, Array)) {

				dst[u][p] = property.slice();

			} else {

				dst[u][p] = property;

			}

		}

	}

	return dst;

}

function mergeUniforms(uniforms:Array<Dynamic>):Dynamic {

	var merged = {};

	for (u in uniforms) {

		var tmp = cloneUniforms(uniforms[u]);

		for (p in tmp) {

			merged[p] = tmp[p];

		}

	}

	return merged;

}

function cloneUniformsGroups(src:Array<Dynamic>):Array<Dynamic> {

	var dst = [];

	for (u in src) {

		dst.push(src[u].clone());

	}

	return dst;

}

function getUnlitUniformColorSpace(renderer:Dynamic):Dynamic {

	var currentRenderTarget = renderer.getRenderTarget();

	if (currentRenderTarget == null) {

		// https://github.com/mrdoob/three.js/pull/23937#issuecomment-1111067398
		return renderer.outputColorSpace;

	}

	// https://github.com/mrdoob/three.js/issues/27868
	if (currentRenderTarget.isXRRenderTarget == true) {

		return currentRenderTarget.texture.colorSpace;

	}

	return ColorManagement.workingColorSpace;

}

// Legacy

var UniformsUtils = { clone: cloneUniforms, merge: mergeUniforms };