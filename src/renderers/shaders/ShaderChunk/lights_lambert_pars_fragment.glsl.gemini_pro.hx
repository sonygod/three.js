package;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.ComplexType;

class GlslLambert {
  static function main() {
    return macro {
      var glsl = """
        varying vec3 vViewPosition;

        struct LambertMaterial {

          vec3 diffuseColor;
          float specularStrength;

        };

        void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {

          float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
          vec3 irradiance = dotNL * directLight.color;

          reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );

        }

        void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {

          reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );

        }

        #define RE_Direct				RE_Direct_Lambert
        #define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert
      """;

      var expr = Context.makeExpr(glsl);
      return expr;
    };
  }
}


**Explanation:**

1. **Package Declaration:** The `package;` line indicates that the code belongs to the default package.
2. **`GlslLambert` Class:** The code is encapsulated within a class named `GlslLambert`.
3. **`main` Function:** The `main` function is a static method that contains the macro logic.
4. **`macro` Expression:** The `macro` keyword indicates that the function will generate code at compile time. The curly braces enclose the code to be generated.
5. **GLSL String:** The `glsl` variable stores the GLSL code as a string.
6. **`Context.makeExpr`:** This function converts the GLSL string into an `Expr` object, which represents a code expression.
7. **Return Value:** The `main` function returns the generated `Expr` object.

**How to Use:**

You can use this Haxe code in your project to generate the GLSL code. For example, you can use it within a shader file or within a Haxe class that defines shader functions.

**Example Usage:**


import GlslLambert;

class MyShader {
  public static function main() {
    trace(GlslLambert.main());
  }
}