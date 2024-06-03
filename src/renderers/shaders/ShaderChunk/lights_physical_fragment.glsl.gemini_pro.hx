import haxe.macro.Expr;
import haxe.macro.Context;

class GlslConverter {
  public static function convert(code:String):String {
    return Context.current().extract(code, function(expr) {
      if (expr.expr.is(Expr.Id)) {
        var id = expr.expr.get(Expr.Id);
        if (id.name == "PhysicalMaterial") {
          return Expr.Function({args: [], body: Expr.Struct({
            fields: [
              {name: "diffuseColor", expr: Expr.Binop(Expr.Binop(Expr.Field(Expr.Id("diffuseColor"), "rgb"), Expr.Op.Mul, Expr.Id("1.0")), Expr.Op.Sub, Expr.Field(Expr.Id("metalnessFactor"), "rgb"))},
              {name: "roughness", expr: Expr.Binop(Expr.Call("max", [Expr.Field(Expr.Id("roughnessFactor"), "rgb"), Expr.Float(0.0525)]), Expr.Op.Add, Expr.Call("max", [Expr.Call("max", [Expr.Field(Expr.Call("abs", [Expr.Call("dFdx", [Expr.Id("nonPerturbedNormal")])]), "x"), Expr.Field(Expr.Call("abs", [Expr.Call("dFdy", [Expr.Id("nonPerturbedNormal")])]), "y")]), Expr.Field(Expr.Call("abs", [Expr.Call("dFdy", [Expr.Id("nonPerturbedNormal")])]), "z")]))},
              {name: "roughness", expr: Expr.Call("min", [Expr.Field(Expr.Id("roughness"), "rgb"), Expr.Float(1.0)])},
              {name: "ior", expr: Expr.Id("ior")},
              {name: "specularF90", expr: Expr.Call("mix", [Expr.Field(Expr.Id("specularIntensityFactor"), "rgb"), Expr.Float(1.0), Expr.Field(Expr.Id("metalnessFactor"), "rgb")])},
              {name: "specularColor", expr: Expr.Call("mix", [Expr.Call("min", [Expr.Binop(Expr.Call("pow2", [Expr.Binop(Expr.Binop(Expr.Field(Expr.Id("ior"), "rgb"), Expr.Op.Sub, Expr.Float(1.0)), Expr.Op.Div, Expr.Binop(Expr.Field(Expr.Id("ior"), "rgb"), Expr.Op.Add, Expr.Float(1.0)))])], Expr.Field(Expr.Id("specularColorFactor"), "rgb"), Expr.Float(1.0)), Expr.Float(1.0)], Expr.Field(Expr.Id("specularIntensityFactor"), "rgb"), Expr.Field(Expr.Id("diffuseColor"), "rgb"), Expr.Field(Expr.Id("metalnessFactor"), "rgb")])},
              {name: "specularColor", expr: Expr.Call("mix", [Expr.Float(0.04), Expr.Field(Expr.Id("diffuseColor"), "rgb"), Expr.Field(Expr.Id("metalnessFactor"), "rgb")])},
              {name: "specularF90", expr: Expr.Float(1.0)},
              {name: "clearcoat", expr: Expr.Id("clearcoat")},
              {name: "clearcoatRoughness", expr: Expr.Id("clearcoatRoughness")},
              {name: "clearcoatF0", expr: Expr.Float(0.04)},
              {name: "clearcoatF90", expr: Expr.Float(1.0)},
              {name: "clearcoat", expr: Expr.Call("saturate", [Expr.Field(Expr.Id("clearcoat"), "rgb")])},
              {name: "clearcoatRoughness", expr: Expr.Call("max", [Expr.Field(Expr.Id("clearcoatRoughness"), "rgb"), Expr.Float(0.0525)])},
              {name: "clearcoatRoughness", expr: Expr.Binop(Expr.Field(Expr.Id("clearcoatRoughness"), "rgb"), Expr.Op.Add, Expr.Call("max", [Expr.Call("max", [Expr.Field(Expr.Call("abs", [Expr.Call("dFdx", [Expr.Id("nonPerturbedNormal")])]), "x"), Expr.Field(Expr.Call("abs", [Expr.Call("dFdy", [Expr.Id("nonPerturbedNormal")])]), "y")]), Expr.Field(Expr.Call("abs", [Expr.Call("dFdy", [Expr.Id("nonPerturbedNormal")])]), "z")]))},
              {name: "clearcoatRoughness", expr: Expr.Call("min", [Expr.Field(Expr.Id("clearcoatRoughness"), "rgb"), Expr.Float(1.0)])},
              {name: "dispersion", expr: Expr.Id("dispersion")},
              {name: "iridescence", expr: Expr.Id("iridescence")},
              {name: "iridescenceIOR", expr: Expr.Id("iridescenceIOR")},
              {name: "iridescence", expr: Expr.Call("mix", [Expr.Float(0.0), Expr.Field(Expr.Id("iridescence"), "rgb"), Expr.Field(Expr.Id("iridescence"), "rgb")])},
              {name: "iridescenceThickness", expr: Expr.Binop(Expr.Binop(Expr.Binop(Expr.Field(Expr.Id("iridescenceThicknessMaximum"), "rgb"), Expr.Op.Sub, Expr.Field(Expr.Id("iridescenceThicknessMinimum"), "rgb")), Expr.Op.Mul, Expr.Field(Expr.Id("iridescenceThickness"), "rgb")), Expr.Op.Add, Expr.Field(Expr.Id("iridescenceThicknessMinimum"), "rgb"))},
              {name: "iridescenceThickness", expr: Expr.Field(Expr.Id("iridescenceThicknessMaximum"), "rgb")},
              {name: "sheenColor", expr: Expr.Id("sheenColor")},
              {name: "sheenRoughness", expr: Expr.Call("clamp", [Expr.Field(Expr.Id("sheenRoughness"), "rgb"), Expr.Float(0.07), Expr.Float(1.0)])},
              {name: "sheenRoughness", expr: Expr.Call("mix", [Expr.Float(0.0), Expr.Field(Expr.Id("sheenRoughness"), "rgb"), Expr.Field(Expr.Id("sheenRoughness"), "rgb")])},
              {name: "anisotropy", expr: Expr.Call("length", [Expr.Field(Expr.Id("anisotropyV"), "rgb")])},
              {name: "anisotropy", expr: Expr.Call("saturate", [Expr.Field(Expr.Id("anisotropy"), "rgb")])},
              {name: "alphaT", expr: Expr.Call("mix", [Expr.Call("pow2", [Expr.Field(Expr.Id("roughness"), "rgb")]), Expr.Float(1.0), Expr.Call("pow2", [Expr.Field(Expr.Id("anisotropy"), "rgb")])])},
              {name: "anisotropyT", expr: Expr.Binop(Expr.Binop(Expr.ArrayAccess(Expr.Id("tbn"), Expr.Int(0)), Expr.Op.Mul, Expr.Field(Expr.Id("anisotropyV"), "x")), Expr.Op.Add, Expr.Binop(Expr.ArrayAccess(Expr.Id("tbn"), Expr.Int(1)), Expr.Op.Mul, Expr.Field(Expr.Id("anisotropyV"), "y")))},
              {name: "anisotropyB", expr: Expr.Binop(Expr.Binop(Expr.ArrayAccess(Expr.Id("tbn"), Expr.Int(1)), Expr.Op.Mul, Expr.Field(Expr.Id("anisotropyV"), "x")), Expr.Op.Sub, Expr.Binop(Expr.ArrayAccess(Expr.Id("tbn"), Expr.Int(0)), Expr.Op.Mul, Expr.Field(Expr.Id("anisotropyV"), "y")))}
            ]
          })});
        }
      }
      return expr;
    });
  }
}

class Main {
  static function main() {
    var code = "export default /* glsl */`\n" + 
    "PhysicalMaterial material;\n" + 
    "material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );\n" + 
    "\n" + 
    "vec3 dxy = max( abs( dFdx( nonPerturbedNormal ) ), abs( dFdy( nonPerturbedNormal ) ) );\n" + 
    "float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );\n" + 
    "\n" + 
    "material.roughness = max( roughnessFactor, 0.0525 );// 0.0525 corresponds to the base mip of a 256 cubemap.\n" + 
    "material.roughness += geometryRoughness;\n" + 
    "material.roughness = min( material.roughness, 1.0 );\n" + 
    "\n" + 
    "#ifdef IOR\n" + 
    "\n" + 
    "\tmaterial.ior = ior;\n" + 
    "\n" + 
    "\t#ifdef USE_SPECULAR\n" + 
    "\n" + 
    "\t\tfloat specularIntensityFactor = specularIntensity;\n" + 
    "\t\tvec3 specularColorFactor = specularColor;\n" + 
    "\n" + 
    "\t\t#ifdef USE_SPECULAR_COLORMAP\n" + 
    "\n" + 
    "\t\t\tspecularColorFactor *= texture2D( specularColorMap, vSpecularColorMapUv ).rgb;\n" + 
    "\n" + 
    "\t\t#endif\n" + 
    "\n" + 
    "\t\t#ifdef USE_SPECULAR_INTENSITYMAP\n" + 
    "\n" + 
    "\t\t\tspecularIntensityFactor *= texture2D( specularIntensityMap, vSpecularIntensityMapUv ).a;\n" + 
    "\n" + 
    "\t\t#endif\n" + 
    "\n" + 
    "\t\tmaterial.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );\n" + 
    "\n" + 
    "\t#else\n" + 
    "\n" + 
    "\t\tfloat specularIntensityFactor = 1.0;\n" + 
    "\t\tvec3 specularColorFactor = vec3( 1.0 );\n" + 
    "\t\tmaterial.specularF90 = 1.0;\n" + 
    "\n" + 
    "\t#endif\n" + 
    "\n" + 
    "\tmaterial.specularColor = mix( min( pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) ) * specularColorFactor, vec3( 1.0 ) ) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor );\n" + 
    "\n" + 
    "#else\n" + 
    "\n" + 
    "\tmaterial.specularColor = mix( vec3( 0.04 ), diffuseColor.rgb, metalnessFactor );\n" + 
    "\tmaterial.specularF90 = 1.0;\n" + 
    "\n" + 
    "#endif\n" + 
    "\n" + 
    "#ifdef USE_CLEARCOAT\n" + 
    "\n" + 
    "\tmaterial.clearcoat = clearcoat;\n" + 
    "\tmaterial.clearcoatRoughness = clearcoatRoughness;\n" + 
    "\tmaterial.clearcoatF0 = vec3( 0.04 );\n" + 
    "\tmaterial.clearcoatF90 = 1.0;\n" + 
    "\n" + 
    "\t#ifdef USE_CLEARCOATMAP\n" + 
    "\n" + 
    "\t\tmaterial.clearcoat *= texture2D( clearcoatMap, vClearcoatMapUv ).x;\n" + 
    "\n" + 
    "\t#endif\n" + 
    "\n" + 
    "\t#ifdef USE_CLEARCOAT_ROUGHNESSMAP\n" + 
    "\n" + 
    "\t\tmaterial.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vClearcoatRoughnessMapUv ).y;\n" + 
    "\n" + 
    "\t#endif\n" + 
    "\n" + 
    "\tmaterial.clearcoat = saturate( material.clearcoat ); // Burley clearcoat model\n" + 
    "\tmaterial.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );\n" + 
    "\tmaterial.clearcoatRoughness += geometryRoughness;\n" + 
    "\tmaterial.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );\n" + 
    "\n" + 
    "#endif\n" + 
    "\n" + 
    "#ifdef USE_DISPERSION\n" + 
    "\n" + 
    "\tmaterial.dispersion = dispersion;\n" + 
    "\n" + 
    "#endif\n" + 
    "\n" + 
    "#ifdef USE_IRIDESCENCE\n" + 
    "\n" + 
    "\tmaterial.iridescence = iridescence;\n" + 
    "\tmaterial.iridescenceIOR = iridescenceIOR;\n" + 
    "\n" + 
    "\t#ifdef USE_IRIDESCENCEMAP\n" + 
    "\n" + 
    "\t\tmaterial.iridescence *= texture2D( iridescenceMap, vIridescenceMapUv ).r;\n" + 
    "\n" + 
    "\t#endif\n" + 
    "\n" + 
    "\t#ifdef USE_IRIDESCENCE_THICKNESSMAP\n" + 
    "\n" + 
    "\t\tmaterial.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D( iridescenceThicknessMap, vIridescenceThicknessMapUv ).g + iridescenceThicknessMinimum;\n" + 
    "\n" + 
    "\t#else\n" + 
    "\n" + 
    "\t\tmaterial.iridescenceThickness = iridescenceThicknessMaximum;\n" + 
    "\n" + 
    "\t#endif\n" + 
    "\n" + 
    "#endif\n" + 
    "\n" + 
    "#ifdef USE_SHEEN\n" + 
    "\n" + 
    "\tmaterial.sheenColor = sheenColor;\n" + 
    "\n" + 
    "\t#ifdef USE_SHEEN_COLORMAP\n" + 
    "\n" + 
    "\t\tmaterial.sheenColor *= texture2D( sheenColorMap, vSheenColorMapUv ).rgb;\n" + 
    "\n" + 
    "\t#endif\n" + 
    "\n" + 
    "\tmaterial.sheenRoughness = clamp( sheenRoughness, 0.07, 1.0 );\n" + 
    "\n" + 
    "\t#ifdef USE_SHEEN_ROUGHNESSMAP\n" + 
    "\n" + 
    "\t\tmaterial.sheenRoughness *= texture2D( sheenRoughnessMap, vSheenRoughnessMapUv ).a;\n" + 
    "\n" + 
    "\t#endif\n" + 
    "\n" + 
    "#endif\n" + 
    "\n" + 
    "#ifdef USE_ANISOTROPY\n" + 
    "\n" + 
    "\t#ifdef USE_ANISOTROPYMAP\n" + 
    "\n" + 
    "\t\tmat2 anisotropyMat = mat2( anisotropyVector.x, anisotropyVector.y, - anisotropyVector.y, anisotropyVector.x );\n" + 
    "\t\tvec3 anisotropyPolar = texture2D( anisotropyMap, vAnisotropyMapUv ).rgb;\n" + 
    "\t\tvec2 anisotropyV = anisotropyMat * normalize( 2.0 * anisotropyPolar.rg - vec2( 1.0 ) ) * anisotropyPolar.b;\n" + 
    "\n" + 
    "\t#else\n" + 
    "\n" + 
    "\t\tvec2 anisotropyV = anisotropyVector;\n" + 
    "\n" + 
    "\t#endif\n" + 
    "\n" + 
    "\tmaterial.anisotropy = length( anisotropyV );\n" + 
    "\n" + 
    "\tif( material.anisotropy == 0.0 ) {\n" + 
    "\t\tanisotropyV = vec2( 1.0, 0.0 );\n" + 
    "\t} else {\n" + 
    "\t\tanisotropyV /= material.anisotropy;\n" + 
    "\t\tmaterial.anisotropy = saturate( material.anisotropy );\n" + 
    "\t}\n" + 
    "\n" + 
    "\t// Roughness along the anisotropy bitangent is the material roughness, while the tangent roughness increases with anisotropy.\n" + 
    "\tmaterial.alphaT = mix( pow2( material.roughness ), 1.0, pow2( material.anisotropy ) );\n" + 
    "\n" + 
    "\tmaterial.anisotropyT = tbn[ 0 ] * anisotropyV.x + tbn[ 1 ] * anisotropyV.y;\n" + 
    "\tmaterial.anisotropyB = tbn[ 1 ] * anisotropyV.x - tbn[ 0 ] * anisotropyV.y;\n" + 
    "\n" + 
    "#endif\n" + 
    "`";
    var converted = GlslConverter.convert(code);
    trace(converted);
  }
}