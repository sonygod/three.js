import three.math.ColorManagement;

/**
 * Uniform Utilities
 */

class UniformsUtils {

  public static function cloneUniforms(src:Dynamic):Dynamic {

    var dst:Dynamic = {};

    for (u in src) {

      dst[u] = {};

      for (p in src[u]) {

        var property = src[u][p];

        if (property != null && (property.isColor ||
          property.isMatrix3 || property.isMatrix4 ||
          property.isVector2 || property.isVector3 || property.isVector4 ||
          property.isTexture || property.isQuaternion)) {

          if (property.isRenderTargetTexture) {

            Sys.println("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms().");
            dst[u][p] = null;

          } else {

            dst[u][p] = property.clone();

          }

        } else if (Std.isOfType(property, Array)) {

          dst[u][p] = Std.string(property);

        } else {

          dst[u][p] = property;

        }

      }

    }

    return dst;

  }

  public static function mergeUniforms(uniforms:Array<Dynamic>):Dynamic {

    var merged:Dynamic = {};

    for (i in 0...uniforms.length) {

      var tmp:Dynamic = cloneUniforms(uniforms[i]);

      for (p in tmp) {

        merged[p] = tmp[p];

      }

    }

    return merged;

  }

  public static function cloneUniformsGroups(src:Array<Dynamic>):Array<Dynamic> {

    var dst:Array<Dynamic> = [];

    for (i in 0...src.length) {

      dst.push(src[i].clone());

    }

    return dst;

  }

  public static function getUnlitUniformColorSpace(renderer:Dynamic):String {

    var currentRenderTarget:Dynamic = renderer.getRenderTarget();

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

}