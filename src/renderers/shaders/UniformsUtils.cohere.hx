import js.ColorManagement from '../../math/ColorManagement.js';

/**
 * Uniform Utilities
 */

function cloneUniforms(src : Dynamic) : Dynamic {
    var dst = {};
    for (u in src) {
        dst[u] = {};
        for (p in src[u]) {
            var property = src[u][p];
            if (property != null && property.isColor != null || property.isMatrix3 != null || property.isMatrix4 != null || property.isVector2 != null || property.isVector3 != null || property.isVector4 != null || property.isTexture != null || property.isQuaternion != null) {
                if (property.isRenderTargetTexture != null) {
                    trace("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().");
                    dst[u][p] = null;
                } else {
                    dst[u][p] = property.clone();
                }
            } else if (Reflect.isArray(property)) {
                dst[u][p] = property.slice();
            } else {
                dst[u][p] = property;
            }
        }
    }
    return dst;
}

function mergeUniforms(uniforms : Array<Dynamic>) : Dynamic {
    var merged = {};
    for (u in 0...uniforms.length) {
        var tmp = cloneUniforms(uniforms[u]);
        for (p in tmp) {
            merged[p] = tmp[p];
        }
    }
    return merged;
}

function cloneUniformsGroups(src : Array<Dynamic>) : Array<Dynamic> {
    var dst = [];
    for (u in 0...src.length) {
        dst.push(src[u].clone());
    }
    return dst;
}

function getUnlitUniformColorSpace(renderer : Dynamic) : Int {
    var currentRenderTarget = renderer.getRenderTarget();
    if (currentRenderTarget == null) {
        // https://github.com/mrdoob/three.js/pull/23937#issuecomment-1111067398
        return renderer.outputColorSpace;
    }
    // https://github.com/mrdoob/three.js/issues/27868
    if (currentRenderTarget.isXRRenderTarget != null) {
        return currentRenderTarget.texture.colorSpace;
    }
    return js.ColorManagement.workingColorSpace;
}

class UniformsUtils {
    public static function clone(src : Dynamic) : Dynamic {
        return cloneUniforms(src);
    }

    public static function merge(uniforms : Array<Dynamic>) : Dynamic {
        return mergeUniforms(uniforms);
    }
}

export { cloneUniforms, mergeUniforms, cloneUniformsGroups, getUnlitUniformColorSpace, UniformsUtils };