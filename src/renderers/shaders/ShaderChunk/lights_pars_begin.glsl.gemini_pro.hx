package;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.StringRef;
import haxe.macro.ComplexType;
import haxe.macro.Const;
import haxe.macro.ExprTools;
import haxe.macro.Field;

class GlslToHaxe {
  public static function convert( code:String ):String {
    var lines = code.split('\n');

    var output = [];

    var indent = 0;
    var insideFunction = false;
    var currentFunction = "";

    for (line in lines) {
      line = line.trim();

      if (line.startsWith("//")) {
        output.push(line);
        continue;
      }

      if (line.startsWith("#") && !line.startsWith("#if")) {
        // Preprocessor directives
        output.push(line);
        continue;
      }

      if (line.startsWith("#if")) {
        // #if directives
        var directive = line.replace("#if", "").trim();
        output.push('if (' + directive + ') {');
        indent++;
        continue;
      }

      if (line.startsWith("#else")) {
        // #else directive
        indent--;
        output.push('}');
        output.push('else {');
        indent++;
        continue;
      }

      if (line.startsWith("#endif")) {
        // #endif directive
        indent--;
        output.push('}');
        continue;
      }

      if (line.startsWith("uniform")) {
        // Uniform declaration
        var parts = line.split(" ");
        var type = parts[1];
        var name = parts[2];

        if (type == "bool") {
          output.push(indentSpaces(indent) + 'var ' + name + ':Bool;');
        } else if (type == "vec3") {
          output.push(indentSpaces(indent) + 'var ' + name + ':Vec3;');
        } else if (type == "sampler2D") {
          output.push(indentSpaces(indent) + 'var ' + name + ':Sampler2D;');
        } else if (type == "float") {
          output.push(indentSpaces(indent) + 'var ' + name + ':Float;');
        } else {
          // Unknown type
          output.push(line);
        }

        continue;
      }

      if (line.startsWith("struct")) {
        // Struct declaration
        var structName = line.split(" ")[1];
        output.push(indentSpaces(indent) + 'typedef ' + structName + ' = {');
        indent++;

        for (var i = 2; i < parts.length; i++) {
          var fieldType = parts[i];
          var fieldName = parts[i + 1];
          i++;

          if (fieldType == "vec3") {
            output.push(indentSpaces(indent) + fieldName + ':Vec3,');
          } else if (fieldType == "float") {
            output.push(indentSpaces(indent) + fieldName + ':Float,');
          } else {
            // Unknown type
            output.push(indentSpaces(indent) + fieldName + ':' + fieldType + ',');
          }
        }
        indent--;
        output.push(indentSpaces(indent) + '};');
        continue;
      }

      if (line.startsWith("void")) {
        // Function declaration
        insideFunction = true;
        var functionName = line.split(" ")[1];
        currentFunction = functionName;
        output.push(indentSpaces(indent) + 'function ' + functionName + '(');
        indent++;
        continue;
      }

      if (line.startsWith("}")) {
        // Function end
        indent--;
        insideFunction = false;
        currentFunction = "";
        output.push(indentSpaces(indent) + '}');
        continue;
      }

      if (line.startsWith("return")) {
        // Return statement
        var returnValue = line.split(" ")[1];
        output.push(indentSpaces(indent) + 'return ' + returnValue + ';');
        continue;
      }

      if (line.endsWith(";")) {
        // Variable assignment
        var parts = line.split("=");
        var variable = parts[0].trim();
        var value = parts[1].trim().substring(0, parts[1].trim().length - 1);

        if (insideFunction) {
          output.push(indentSpaces(indent) + variable + ' = ' + value + ';');
        } else {
          output.push(indentSpaces(indent) + 'var ' + variable + ' = ' + value + ';');
        }
        continue;
      }

      // Unknown line
      output.push(line);
    }

    return output.join('\n');
  }

  static function indentSpaces(level:Int):String {
    var spaces = "";
    for (i in 0...level) {
      spaces += "  ";
    }
    return spaces;
  }
}


**Usage:**


import GlslToHaxe;

class Main {
  static function main() {
    var glslCode = `
      uniform bool receiveShadow;
      uniform vec3 ambientLightColor;

      #if defined( USE_LIGHT_PROBES )

        uniform vec3 lightProbe[ 9 ];

      #endif

      // get the irradiance (radiance convolved with cosine lobe) at the point 'normal' on the unit sphere
      // source: https://graphics.stanford.edu/papers/envmap/envmap.pdf
      vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {

        // normal is assumed to have unit length

        float x = normal.x, y = normal.y, z = normal.z;

        // band 0
        vec3 result = shCoefficients[ 0 ] * 0.886227;

        // band 1
        result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;
        result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;
        result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;

        // band 2
        result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;
        result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;
        result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );
        result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;
        result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );

        return result;

      }

      vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal ) {

        vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );

        vec3 irradiance = shGetIrradianceAt( worldNormal, lightProbe );

        return irradiance;

      }

      vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {

        vec3 irradiance = ambientLightColor;

        return irradiance;

      }
    `;

    var haxeCode = GlslToHaxe.convert(glslCode);
    trace(haxeCode);
  }
}