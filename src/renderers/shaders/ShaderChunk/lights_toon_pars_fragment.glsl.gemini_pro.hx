import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class ToonMaterial {
  public var diffuseColor:Vec3;
}

class ReflectedLight {
  public var directDiffuse:Vec3;
  public var indirectDiffuse:Vec3;
}

class IncidentLight {
  public var color:Vec3;
  public var direction:Vec3;
}

class Vec3 {
  public var x:Float;
  public var y:Float;
  public var z:Float;
}

@:macro
class GlslMacro {
  public static function main(c:Context, args:Array<Expr>):Expr {
    var code = """
      varying vec3 vViewPosition;

      struct ToonMaterial {

        vec3 diffuseColor;

      };

      void RE_Direct_Toon( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {

        vec3 irradiance = getGradientIrradiance( geometryNormal, directLight.direction ) * directLight.color;

        reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );

      }

      void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {

        reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );

      }

      #define RE_Direct				RE_Direct_Toon
      #define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon
    """;
    return c.parseCode(code);
  }
}


**Explanation:**

1. **Haxe Structs:**
   - We define Haxe structs `ToonMaterial`, `ReflectedLight`, `IncidentLight`, and `Vec3` to represent the data structures used in the GLSL code.

2. **Macro Class:**
   - The `GlslMacro` class is defined using the `@:macro` annotation.
   - The `main` method of the macro class receives the `Context` and `args` parameters.
   - Inside the `main` method, the GLSL code is embedded as a string within the `code` variable.
   - The `c.parseCode(code)` method is used to parse the GLSL code and return it as an `Expr` object, which can be used in the Haxe code.

3. **Usage:**
   - In your Haxe code, you can use the macro like this:
     
     @:glsl
     class MyShader {
       // ... your Haxe code ...
     }