import haxe.macro.Expr;
import haxe.macro.Context;

class GlslConverter {
  static function convert(code:String):Expr {
    var lines = code.split("\n");
    var outputLines:Array<Expr> = [];

    for (line in lines) {
      var trimmedLine = line.trim();

      // Handle #ifdef and #elif directives
      if (trimmedLine.startsWith("#ifdef")) {
        var directive = trimmedLine.substring(7).trim();
        outputLines.push(Context.if_(Expr.identifier(directive), [
          convert(lines.slice(lines.indexOf(line) + 1).join("\n"))
        ]));
      } else if (trimmedLine.startsWith("#elif")) {
        var directive = trimmedLine.substring(6).trim();
        outputLines.push(Context.elseif_(Expr.identifier(directive), [
          convert(lines.slice(lines.indexOf(line) + 1).join("\n"))
        ]));
      } else if (trimmedLine.startsWith("#endif")) {
        // Do nothing, just skip the line
      } else {
        // Convert the rest of the code to Haxe
        var haxeLine = convertLine(trimmedLine);
        if (haxeLine != null) {
          outputLines.push(haxeLine);
        }
      }
    }

    return Context.block(outputLines);
  }

  static function convertLine(line:String):Expr {
    // Handle specific cases
    if (line == "normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;") {
      return Context.assign(Expr.identifier("normal"), [
        Expr.operator(Expr.identifier("normal"), "*", [
          Expr.identifier("texture2D"),
          Expr.identifier("normalMap"),
          Expr.identifier("vNormalMapUv")
        ]),
        Expr.operator(Expr.literal(2.0), "*", [Expr.identifier("normal")]),
        Expr.operator(Expr.identifier("normal"), "-", [Expr.literal(1.0)])
      ]);
    } else if (line == "normal = - normal;") {
      return Context.assign(Expr.identifier("normal"), [Expr.operator(Expr.literal(-1.0), "*", [Expr.identifier("normal")])]);
    } else if (line == "normal = normal * faceDirection;") {
      return Context.assign(Expr.identifier("normal"), [Expr.operator(Expr.identifier("normal"), "*", [Expr.identifier("faceDirection")])]);
    } else if (line == "normal = normalize( normalMatrix * normal );") {
      return Context.assign(Expr.identifier("normal"), [
        Expr.identifier("normalize"),
        Expr.operator(Expr.identifier("normalMatrix"), "*", [Expr.identifier("normal")])
      ]);
    } else if (line == "vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;") {
      return Context.var(Expr.identifier("mapN"), [
        Expr.operator(Expr.identifier("texture2D"), "*", [
          Expr.identifier("normalMap"),
          Expr.identifier("vNormalMapUv")
        ]),
        Expr.operator(Expr.literal(2.0), "*", [Expr.identifier("mapN")]),
        Expr.operator(Expr.identifier("mapN"), "-", [Expr.literal(1.0)])
      ]);
    } else if (line == "mapN.xy *= normalScale;") {
      return Context.assign(Expr.fieldAccess(Expr.identifier("mapN"), "xy"), [
        Expr.operator(Expr.fieldAccess(Expr.identifier("mapN"), "xy"), "*", [Expr.identifier("normalScale")])
      ]);
    } else if (line == "normal = normalize( tbn * mapN );") {
      return Context.assign(Expr.identifier("normal"), [
        Expr.identifier("normalize"),
        Expr.operator(Expr.identifier("tbn"), "*", [Expr.identifier("mapN")])
      ]);
    } else if (line == "normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );") {
      return Context.assign(Expr.identifier("normal"), [
        Expr.identifier("perturbNormalArb"),
        Expr.operator(Expr.literal(-1.0), "*", [Expr.identifier("vViewPosition")]),
        Expr.identifier("normal"),
        Expr.identifier("dHdxy_fwd"),
        Expr.identifier("faceDirection")
      ]);
    } else {
      // Just return the line as is
      return Context.code(line);
    }
  }
}

class Main {
  static function main() {
    // Your code here
    var code = """
#ifdef USE_NORMALMAP_OBJECTSPACE

	normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0; // overrides both flatShading and attribute normals

	#ifdef FLIP_SIDED

		normal = - normal;

	#endif

	#ifdef DOUBLE_SIDED

		normal = normal * faceDirection;

	#endif

	normal = normalize( normalMatrix * normal );

#elif defined( USE_NORMALMAP_TANGENTSPACE )

	vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	mapN.xy *= normalScale;

	normal = normalize( tbn * mapN );

#elif defined( USE_BUMPMAP )

	normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );

#endif
""";

    var haxeCode = GlslConverter.convert(code);
    trace(haxeCode);
  }
}