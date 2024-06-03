package;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

class GlslEnvmap {
  public static function main():Expr {
    return macro {
      #ifdef USE_ENVMAP
        #ifdef ENV_WORLDPOS
          var cameraToFrag:Expr = macro vec3(0.0);
          if (isOrthographic) {
            cameraToFrag = macro normalize(vec3(-viewMatrix[0][2], -viewMatrix[1][2], -viewMatrix[2][2]));
          } else {
            cameraToFrag = macro normalize(vWorldPosition - cameraPosition);
          }

          // Transforming Normal Vectors with the Inverse Transformation
          var worldNormal:Expr = macro inverseTransformDirection(normal, viewMatrix);

          #ifdef ENVMAP_MODE_REFLECTION
            var reflectVec:Expr = macro reflect(cameraToFrag, worldNormal);
          #else
            var reflectVec:Expr = macro refract(cameraToFrag, worldNormal, refractionRatio);
          #endif
        #else
          var reflectVec:Expr = macro vReflect;
        #endif

        #ifdef ENVMAP_TYPE_CUBE
          var envColor:Expr = macro textureCube(envMap, envMapRotation * vec3(flipEnvMap * reflectVec.x, reflectVec.yz));
        #else
          var envColor:Expr = macro vec4(0.0);
        #endif

        #ifdef ENVMAP_BLENDING_MULTIPLY
          outgoingLight = macro mix(outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity);
        #elif defined(ENVMAP_BLENDING_MIX)
          outgoingLight = macro mix(outgoingLight, envColor.xyz, specularStrength * reflectivity);
        #elif defined(ENVMAP_BLENDING_ADD)
          outgoingLight += macro envColor.xyz * specularStrength * reflectivity;
        #endif
      #endif
    };
  }
}