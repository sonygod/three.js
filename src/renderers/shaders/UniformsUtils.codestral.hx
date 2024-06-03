import three.math.ColorManagement;
import three.renderers.shaders.Uniform;
import three.renderers.WebGLRenderer;

class UniformsUtils {
    public static function cloneUniforms(src:Dynamic):Dynamic {
        var dst:Dynamic = {};
        for (uniform in src.keys()) {
            dst[uniform] = {};
            for (property in src[uniform].keys()) {
                var val = src[uniform][property];
                if (val != null && (Std.is(val, Uniform.Color) ||
                    Std.is(val, Uniform.Matrix3) || Std.is(val, Uniform.Matrix4) ||
                    Std.is(val, Uniform.Vector2) || Std.is(val, Uniform.Vector3) || Std.is(val, Uniform.Vector4) ||
                    Std.is(val, Uniform.Texture) || Std.is(val, Uniform.Quaternion))) {
                    if (Std.is(val, Uniform.RenderTargetTexture)) {
                        trace('UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().');
                        dst[uniform][property] = null;
                    } else {
                        dst[uniform][property] = val.clone();
                    }
                } else if (Std.is(val, Array)) {
                    dst[uniform][property] = val.copy();
                } else {
                    dst[uniform][property] = val;
                }
            }
        }
        return dst;
    }

    public static function mergeUniforms(uniforms:Array<Dynamic>):Dynamic {
        var merged:Dynamic = {};
        for (uniform in uniforms) {
            var tmp = cloneUniforms(uniform);
            for (property in tmp.keys()) {
                merged[property] = tmp[property];
            }
        }
        return merged;
    }

    public static function cloneUniformsGroups(src:Array<Dynamic>):Array<Dynamic> {
        var dst:Array<Dynamic> = [];
        for (uniform in src) {
            dst.push(uniform.clone());
        }
        return dst;
    }

    public static function getUnlitUniformColorSpace(renderer:WebGLRenderer):String {
        var currentRenderTarget = renderer.getRenderTarget();
        if (currentRenderTarget == null) {
            return renderer.outputColorSpace;
        }
        if (Std.is(currentRenderTarget, Uniform.XRRenderTarget)) {
            return currentRenderTarget.texture.colorSpace;
        }
        return ColorManagement.workingColorSpace;
    }
}

class UniformsUtilsLegacy {
    public static function clone(src:Dynamic):Dynamic {
        return UniformsUtils.cloneUniforms(src);
    }

    public static function merge(uniforms:Array<Dynamic>):Dynamic {
        return UniformsUtils.mergeUniforms(uniforms);
    }
}