import ColorManagement.ColorManagement;

/**
 * Uniform Utilities
 */

class UniformsUtils {
    public static function cloneUniforms(src:Dynamic):Dynamic {
        var dst:Dynamic = new Dynamic();

        for (u in src) {
            dst[u] = new Dynamic();

            for (p in src[u]) {
                var property:Dynamic = src[u][p];

                if (property && (property.isColor ||
                    property.isMatrix3 || property.isMatrix4 ||
                    property.isVector2 || property.isVector3 || property.isVector4 ||
                    property.isTexture || property.isQuaternion)) {

                    if (property.isRenderTargetTexture) {
                        trace.warn("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().");
                        dst[u][p] = null;

                    } else {
                        dst[u][p] = property.clone();
                    }

                } else if (Std.is(property, Array<Dynamic>)) {
                    dst[u][p] = property.slice();

                } else {
                    dst[u][p] = property;
                }
            }
        }

        return dst;
    }

    public static function mergeUniforms(uniforms:Array<Dynamic>):Dynamic {
        var merged:Dynamic = new Dynamic();

        for (u in 0...uniforms.length) {
            var tmp:Dynamic = cloneUniforms(uniforms[u]);

            for (p in tmp) {
                merged[p] = tmp[p];
            }
        }

        return merged;
    }

    public static function cloneUniformsGroups(src:Array<Dynamic>):Array<Dynamic> {
        var dst:Array<Dynamic> = new Array<Dynamic>();

        for (u in 0...src.length) {
            dst.push(src[u].clone());
        }

        return dst;
    }

    public static function getUnlitUniformColorSpace(renderer:Dynamic):Dynamic {
        var currentRenderTarget:Dynamic = renderer.getRenderTarget();

        if (currentRenderTarget == null) {
            return renderer.outputColorSpace;
        }

        if (currentRenderTarget.isXRRenderTarget == true) {
            return currentRenderTarget.texture.colorSpace;
        }

        return ColorManagement.workingColorSpace;
    }
}

// Legacy
class LegacyUniformsUtils {
    public static var clone:Dynamic = UniformsUtils.cloneUniforms;
    public static var merge:Dynamic = UniformsUtils.mergeUniforms;
}