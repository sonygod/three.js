import haxe.macro.Expr;
import haxe.macro.Context;

class GlslConverter {
  static function convert(code:String):String {
    // Replace #ifdef with #if
    var code = code.replace(/#ifdef/g, "#if");
    // Replace #ifndef with #if !
    code = code.replace(/#ifndef/g, "#if !");
    // Replace #else with #elseif(true)
    code = code.replace(/#else/g, "#elseif(true)");
    // Replace #endif with #end
    code = code.replace(/#endif/g, "#end");
    // Replace gl_FrontFacing with frontFacing
    code = code.replace(/gl_FrontFacing/g, "frontFacing");
    // Replace dFdx with dfdx
    code = code.replace(/dFdx/g, "dfdx");
    // Replace dFdy with dfdy
    code = code.replace(/dFdy/g, "dfdy");
    // Replace normalize with normalize
    code = code.replace(/normalize/g, "normalize");
    // Replace cross with cross
    code = code.replace(/cross/g, "cross");
    // Replace vViewPosition with viewPosition
    code = code.replace(/vViewPosition/g, "viewPosition");
    // Replace vNormal with normal
    code = code.replace(/vNormal/g, "normal");
    // Replace vTangent with tangent
    code = code.replace(/vTangent/g, "tangent");
    // Replace vBitangent with bitangent
    code = code.replace(/vBitangent/g, "bitangent");
    // Replace vNormalMapUv with normalMapUv
    code = code.replace(/vNormalMapUv/g, "normalMapUv");
    // Replace vClearcoatNormalMapUv with clearcoatNormalMapUv
    code = code.replace(/vClearcoatNormalMapUv/g, "clearcoatNormalMapUv");
    // Replace vUv with uv
    code = code.replace(/vUv/g, "uv");
    // Replace getTangentFrame with getTangentFrame
    code = code.replace(/getTangentFrame/g, "getTangentFrame");
    // Replace mat3 with mat3
    code = code.replace(/mat3/g, "mat3");
    // Replace vec3 with vec3
    code = code.replace(/vec3/g, "vec3");
    // Replace *= with *=
    code = code.replace(/ *= /g, " *= ");
    return code;
  }

  static macro glsl(code:Expr):Expr {
    var codeStr = Context.toString(code);
    return Context.makeString(GlslConverter.convert(codeStr));
  }
}

class Main {
  static function main() {
    var code = glsl(
      `
      float faceDirection = frontFacing ? 1.0 : - 1.0;

      #if FLAT_SHADED

          vec3 fdx = dfdx( viewPosition );
          vec3 fdy = dfdy( viewPosition );
          vec3 normal = normalize( cross( fdx, fdy ) );

      #else

          vec3 normal = normalize( normal );

          #if DOUBLE_SIDED

              normal *= faceDirection;

          #end

      #end

      #if USE_NORMALMAP_TANGENTSPACE || USE_CLEARCOAT_NORMALMAP || USE_ANISOTROPY

          #if USE_TANGENT

              mat3 tbn = mat3( normalize( tangent ), normalize( bitangent ), normal );

          #else

              mat3 tbn = getTangentFrame( - viewPosition, normal,
              #if USE_NORMALMAP
                  normalMapUv
              #elseif USE_CLEARCOAT_NORMALMAP
                  clearcoatNormalMapUv
              #else
                  uv
              #end
              );

          #end

          #if DOUBLE_SIDED && ! FLAT_SHADED

              tbn[0] *= faceDirection;
              tbn[1] *= faceDirection;

          #end

      #end

      #if USE_CLEARCOAT_NORMALMAP

          #if USE_TANGENT

              mat3 tbn2 = mat3( normalize( tangent ), normalize( bitangent ), normal );

          #else

              mat3 tbn2 = getTangentFrame( - viewPosition, normal, clearcoatNormalMapUv );

          #end

          #if DOUBLE_SIDED && ! FLAT_SHADED

              tbn2[0] *= faceDirection;
              tbn2[1] *= faceDirection;

          #end

      #end

      // non perturbed normal for clearcoat among others

      vec3 nonPerturbedNormal = normal;

      `
    );

    trace(code);
  }
}