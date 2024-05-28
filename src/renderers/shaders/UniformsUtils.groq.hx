package three.renderers.shaders;

import three.math.ColorManagement;

/**
 * Uniform Utilities
 */

class UniformsUtils {
    public static function cloneUniforms(src:Dynamic) {
        var dst:Dynamic = {};

        for (u in src.keys()) {
            dst[u] = {};

            for (p in src[u].keys()) {
                var property = src[u][p];

                if (property != null && (property.isColor || property.isMatrix3 || property.isMatrix4 || property.isVector2 || property.isVector3 || property.isVector4 || property.isTexture || property.isQuaternion)) {
                    if (property.isRenderTargetTexture) {
                        trace("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().");
                        dst[u][p] = null;
                    } else {
                        dst[u][p] = property.clone();
                    }
                } else if (Std.isOfType(property, Array)) {
                    dst[u][p] = property.copy();
                } else {
                    dst[u][p] = property;
                }
            }
        }

        return dst;
    }

    public static function mergeUniforms(uniforms:Array<Dynamic>) {
        var merged:Dynamic = {};

        for (u in uniforms) {
            var tmp = cloneUniforms(u);

            for (p in tmp.keys()) {
                merged[p] = tmp[p];
            }
        }

        return merged;
    }

    public static function cloneUniformsGroups(src:Array<Dynamic>) {
        var dst:Array<Dynamic> = [];

        for (u in src) {
            dst.push(u.clone());
        }

        return dst;
    }

    public static function getUnlitUniformColorSpace(renderer:Dynamic) {
        var currentRenderTarget = renderer.getRenderTarget();

        if (currentRenderTarget == null) {
            return renderer.outputColorSpace;
        }

        if (currentRenderTarget.isXRRenderTarget) {
            return currentRenderTarget.texture.colorSpace;
        }

        return ColorManagement.workingColorSpace;
    }

    public static var UniformsUtils:Dynamic = { clone: cloneUniforms, merge: mergeUniforms };
}