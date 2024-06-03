import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.ExprTools;

class BlinnPhongMaterial {
  public var diffuseColor:Vec3;
  public var specularColor:Vec3;
  public var specularShininess:Float;
  public var specularStrength:Float;

  public function new(diffuseColor:Vec3, specularColor:Vec3, specularShininess:Float, specularStrength:Float) {
    this.diffuseColor = diffuseColor;
    this.specularColor = specularColor;
    this.specularShininess = specularShininess;
    this.specularStrength = specularStrength;
  }
}

class IncidentLight {
  public var direction:Vec3;
  public var color:Vec3;

  public function new(direction:Vec3, color:Vec3) {
    this.direction = direction;
    this.color = color;
  }
}

class ReflectedLight {
  public var directDiffuse:Vec3;
  public var directSpecular:Vec3;
  public var indirectDiffuse:Vec3;

  public function new() {
    directDiffuse = new Vec3(0, 0, 0);
    directSpecular = new Vec3(0, 0, 0);
    indirectDiffuse = new Vec3(0, 0, 0);
  }
}

class Vec3 {
  public var x:Float;
  public var y:Float;
  public var z:Float;

  public function new(x:Float, y:Float, z:Float) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public function dot(other:Vec3):Float {
    return x * other.x + y * other.y + z * other.z;
  }
}

@:macro
class GLSL {
  static public function glsl(ctx:Context, expr:Expr) {
    var code = expr.toString().split('\n');

    // Create a new code block
    var codeBlock = new haxe.macro.CodeBlock(ctx, "glsl");

    // Add each line of code to the code block
    for (line in code) {
      codeBlock.add(new haxe.macro.Expr(line, ctx));
    }

    // Return the code block
    return codeBlock;
  }

  static public function varying(ctx:Context, expr:Expr):Expr {
    var type = ExprTools.resolveType(expr, ctx);
    if (type == null) {
      ctx.error("Invalid type for varying declaration: ${expr}", expr);
      return null;
    }

    // Convert the type to a string
    var typeName = type.toString();

    // Check if the type is a valid type for a varying
    if (!typeName.startsWith("Vec")) {
      ctx.error("Invalid type for varying declaration: ${expr}", expr);
      return null;
    }

    // Create a new varying declaration
    var varyingDeclaration = new haxe.macro.Expr("varying $typeName vViewPosition;", ctx);

    // Return the varying declaration
    return varyingDeclaration;
  }

  static public function struct(ctx:Context, expr:Expr):Expr {
    var type = ExprTools.resolveType(expr, ctx);
    if (type == null) {
      ctx.error("Invalid type for struct declaration: ${expr}", expr);
      return null;
    }

    // Convert the type to a string
    var typeName = type.toString();

    // Check if the type is a valid type for a struct
    if (!typeName.startsWith("BlinnPhongMaterial")) {
      ctx.error("Invalid type for struct declaration: ${expr}", expr);
      return null;
    }

    // Create a new struct declaration
    var structDeclaration = new haxe.macro.Expr("struct $typeName {", ctx);

    // Add the fields to the struct declaration
    var fields = type.getFields();
    for (field in fields) {
      var fieldName = field.name;
      var fieldType = field.type;
      var fieldDeclaration = new haxe.macro.Expr("$fieldType $fieldName;", ctx);
      structDeclaration.add(fieldDeclaration);
    }

    // Close the struct declaration
    structDeclaration.add(new haxe.macro.Expr("}", ctx));

    // Return the struct declaration
    return structDeclaration;
  }

  static public function function(ctx:Context, expr:Expr):Expr {
    var type = ExprTools.resolveType(expr, ctx);
    if (type == null) {
      ctx.error("Invalid type for function declaration: ${expr}", expr);
      return null;
    }

    // Convert the type to a string
    var typeName = type.toString();

    // Check if the type is a valid type for a function
    if (!typeName.startsWith("RE_Direct_BlinnPhong")) {
      ctx.error("Invalid type for function declaration: ${expr}", expr);
      return null;
    }

    // Create a new function declaration
    var functionDeclaration = new haxe.macro.Expr("function $typeName(directLight:IncidentLight, geometryPosition:Vec3, geometryNormal:Vec3, geometryViewDir:Vec3, geometryClearcoatNormal:Vec3, material:BlinnPhongMaterial, reflectedLight:ReflectedLight) {", ctx);

    // Add the function body
    var functionBody = new haxe.macro.Expr("var dotNL = saturate(geometryNormal.dot(directLight.direction));", ctx);
    functionBody.add(new haxe.macro.Expr("var irradiance = dotNL * directLight.color;", ctx));

    // Add the reflected light calculations
    functionBody.add(new haxe.macro.Expr("reflectedLight.directDiffuse += irradiance * BRDF_Lambert(material.diffuseColor);", ctx));
    functionBody.add(new haxe.macro.Expr("reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong(directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess) * material.specularStrength;", ctx));

    // Add the function body to the function declaration
    functionDeclaration.add(functionBody);

    // Close the function declaration
    functionDeclaration.add(new haxe.macro.Expr("}", ctx));

    // Return the function declaration
    return functionDeclaration;
  }
}

@:macro
class BRDF {
  static public function lambert(ctx:Context, expr:Expr):Expr {
    var type = ExprTools.resolveType(expr, ctx);
    if (type == null) {
      ctx.error("Invalid type for BRDF_Lambert: ${expr}", expr);
      return null;
    }

    // Convert the type to a string
    var typeName = type.toString();

    // Check if the type is a valid type for BRDF_Lambert
    if (!typeName.startsWith("Vec")) {
      ctx.error("Invalid type for BRDF_Lambert: ${expr}", expr);
      return null;
    }

    // Create a new BRDF_Lambert declaration
    var brdfLambertDeclaration = new haxe.macro.Expr("function BRDF_Lambert(color:$typeName):$typeName {", ctx);

    // Add the function body
    var brdfLambertBody = new haxe.macro.Expr("return color;", ctx);

    // Add the function body to the BRDF_Lambert declaration
    brdfLambertDeclaration.add(brdfLambertBody);

    // Close the BRDF_Lambert declaration
    brdfLambertDeclaration.add(new haxe.macro.Expr("}", ctx));

    // Return the BRDF_Lambert declaration
    return brdfLambertDeclaration;
  }

  static public function blinnPhong(ctx:Context, expr:Expr):Expr {
    var type = ExprTools.resolveType(expr, ctx);
    if (type == null) {
      ctx.error("Invalid type for BRDF_BlinnPhong: ${expr}", expr);
      return null;
    }

    // Convert the type to a string
    var typeName = type.toString();

    // Check if the type is a valid type for BRDF_BlinnPhong
    if (!typeName.startsWith("Vec")) {
      ctx.error("Invalid type for BRDF_BlinnPhong: ${expr}", expr);
      return null;
    }

    // Create a new BRDF_BlinnPhong declaration
    var brdfBlinnPhongDeclaration = new haxe.macro.Expr("function BRDF_BlinnPhong(lightDir:$typeName, viewDir:$typeName, normal:$typeName, color:$typeName, shininess:Float):$typeName {", ctx);

    // Add the function body
    var brdfBlinnPhongBody = new haxe.macro.Expr("var halfwayDir = normalize(lightDir + viewDir);", ctx);
    brdfBlinnPhongBody.add(new haxe.macro.Expr("var dotNH = saturate(normal.dot(halfwayDir));", ctx));
    brdfBlinnPhongBody.add(new haxe.macro.Expr("return color * pow(dotNH, shininess);", ctx));

    // Add the function body to the BRDF_BlinnPhong declaration
    brdfBlinnPhongDeclaration.add(brdfBlinnPhongBody);

    // Close the BRDF_BlinnPhong declaration
    brdfBlinnPhongDeclaration.add(new haxe.macro.Expr("}", ctx));

    // Return the BRDF_BlinnPhong declaration
    return brdfBlinnPhongDeclaration;
  }
}

@:macro
class Shader {
  static public function define(ctx:Context, expr:Expr):Expr {
    var type = ExprTools.resolveType(expr, ctx);
    if (type == null) {
      ctx.error("Invalid type for define: ${expr}", expr);
      return null;
    }

    // Convert the type to a string
    var typeName = type.toString();

    // Check if the type is a valid type for define
    if (!typeName.startsWith("RE_Direct")) {
      ctx.error("Invalid type for define: ${expr}", expr);
      return null;
    }

    // Create a new define declaration
    var defineDeclaration = new haxe.macro.Expr("#define $typeName $typeName", ctx);

    // Return the define declaration
    return defineDeclaration;
  }
}

class Main {
  static public function main() {
    // Define the varying declaration
    var varyingDeclaration = GLSL.varying(Context.current(), new haxe.macro.Expr("Vec3", Context.current()));

    // Define the struct declaration
    var structDeclaration = GLSL.struct(Context.current(), new haxe.macro.Expr("BlinnPhongMaterial", Context.current()));

    // Define the function declaration
    var functionDeclaration = GLSL.function(Context.current(), new haxe.macro.Expr("RE_Direct_BlinnPhong", Context.current()));

    // Define the function declaration
    var functionDeclaration2 = GLSL.function(Context.current(), new haxe.macro.Expr("RE_IndirectDiffuse_BlinnPhong", Context.current()));

    // Define the BRDF_Lambert declaration
    var brdfLambertDeclaration = BRDF.lambert(Context.current(), new haxe.macro.Expr("Vec3", Context.current()));

    // Define the BRDF_BlinnPhong declaration
    var brdfBlinnPhongDeclaration = BRDF.blinnPhong(Context.current(), new haxe.macro.Expr("Vec3", Context.current()));

    // Define the define declarations
    var defineDeclaration1 = Shader.define(Context.current(), new haxe.macro.Expr("RE_Direct", Context.current()));
    var defineDeclaration2 = Shader.define(Context.current(), new haxe.macro.Expr("RE_IndirectDiffuse", Context.current()));

    // Create a new GLSL code block
    var glslCodeBlock = GLSL.glsl(Context.current(), new haxe.macro.Expr("", Context.current()));

    // Add the declarations to the GLSL code block
    glslCodeBlock.add(varyingDeclaration);
    glslCodeBlock.add(structDeclaration);
    glslCodeBlock.add(functionDeclaration);
    glslCodeBlock.add(functionDeclaration2);
    glslCodeBlock.add(brdfLambertDeclaration);
    glslCodeBlock.add(brdfBlinnPhongDeclaration);
    glslCodeBlock.add(defineDeclaration1);
    glslCodeBlock.add(defineDeclaration2);

    // Print the GLSL code
    trace(glslCodeBlock);
  }
}