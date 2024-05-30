import three.math.ColorManagement;

/**
 * Uniform Utilities
 */

class UniformsUtils {

    public static function cloneUniforms(src:Dynamic):Dynamic {
        var dst:Dynamic = {};

        for (u in Reflect.fields(src)) {
            dst[u] = {};
            for (p in Reflect.fields(src[u])) {
                var property = Reflect.field(src[u], p);

                if (property != null && (Reflect.hasField(property, "isColor") ||
                    Reflect.hasField(property, "isMatrix3") || Reflect.hasField(property, "isMatrix4") ||
                    Reflect.hasField(property, "isVector2") || Reflect.hasField(property, "isVector3") || Reflect.hasField(property, "isVector4") ||
                    Reflect.hasField(property, "isTexture") || Reflect.hasField(property, "isQuaternion"))) {

                    if (Reflect.hasField(property, "isRenderTargetTexture")) {
                        trace('UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().');
                        Reflect.setField(dst[u], p, null);
                    } else {
                        Reflect.setField(dst[u], p, property.clone());
                    }
                } else if (Type.typeof(property) == TInst(Array)) {
                    Reflect.setField(dst[u], p, property.copy());
                } else {
                    Reflect.setField(dst[u], p, property);
                }
            }
        }

        return dst;
    }

    public static function mergeUniforms(uniforms:Array<Dynamic>):Dynamic {
        var merged:Dynamic = {};

        for (u in 0...uniforms.length) {
            var tmp = cloneUniforms(uniforms[u]);
            for (p in Reflect.fields(tmp)) {
                Reflect.setField(merged, p, Reflect.field(tmp, p));
            }
        }

        return merged;
    }

    public static function cloneUniformsGroups(src:Array<Dynamic>):Array<Dynamic> {
        var dst:Array<Dynamic> = [];

        for (u in 0...src.length) {
            dst.push(src[u].clone());
        }

        return dst;
    }

    public static function getUnlitUniformColorSpace(renderer:Dynamic):Dynamic {
        var currentRenderTarget = renderer.getRenderTarget();

        if (currentRenderTarget == null) {
            // https://github.com/mrdoob/three.js/pull/23937#issuecomment-1111067398
            return renderer.outputColorSpace;
        }

        // https://github.com/mrdoob/three.js/issues/27868
        if (Reflect.hasField(currentRenderTarget, "isXRRenderTarget") && currentRenderTarget.isXRRenderTarget == true) {
            return currentRenderTarget.texture.colorSpace;
        }

        return ColorManagement.workingColorSpace;
    }
}

// Legacy

typedef UniformsUtils = {
    public static var clone:Dynamic -> Dynamic = UniformsUtils.cloneUniforms;
    public static var merge:Array<Dynamic> -> Dynamic = UniformsUtils.mergeUniforms;
};