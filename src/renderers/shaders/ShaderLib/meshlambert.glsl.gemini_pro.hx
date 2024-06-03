import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ExprTools;
import haxe.macro.StringTools;

class GlslConverter {

  public static function convert(code:String, kind:String):Expr {
    var lines = code.split("\n");
    var newLines:Array<String> = [];
    var inString = false;
    var inMultilineComment = false;
    var inSinglelineComment = false;
    var insidePreprocessor = false;
    for (line in lines) {
      var newLine = "";
      var i = 0;
      while (i < line.length) {
        var char = line.charAt(i);
        if (inString) {
          if (char == '"' && line.charAt(i - 1) != '\\') {
            inString = false;
          }
        } else if (inMultilineComment) {
          if (char == '*' && line.charAt(i + 1) == '/') {
            inMultilineComment = false;
            i++;
          }
        } else if (inSinglelineComment) {
          if (char == '\n') {
            inSinglelineComment = false;
          }
        } else {
          if (char == '"') {
            inString = true;
          } else if (char == '/' && line.charAt(i + 1) == '*') {
            inMultilineComment = true;
            i++;
          } else if (char == '/' && line.charAt(i + 1) == '/') {
            inSinglelineComment = true;
            i++;
          } else if (char == '#' && !insidePreprocessor) {
            insidePreprocessor = true;
          } else if (insidePreprocessor && char == '\n') {
            insidePreprocessor = false;
          } else if (char == ' ' && insidePreprocessor) {
            // ignore spaces in preprocessor directives
          } else {
            newLine += char;
          }
        }
        i++;
      }
      newLines.push(newLine);
    }

    var codeString = newLines.join("\n");

    switch (kind) {
      case "vertex":
        return macro {
          var vertexShader =  """
            #define LAMBERT

            varying vec3 vViewPosition;

            #include <common>
            #include <batching_pars_vertex>
            #include <uv_pars_vertex>
            #include <displacementmap_pars_vertex>
            #include <envmap_pars_vertex>
            #include <color_pars_vertex>
            #include <fog_pars_vertex>
            #include <normal_pars_vertex>
            #include <morphtarget_pars_vertex>
            #include <skinning_pars_vertex>
            #include <shadowmap_pars_vertex>
            #include <logdepthbuf_pars_vertex>
            #include <clipping_planes_pars_vertex>

            void main() {

              #include <uv_vertex>
              #include <color_vertex>
              #include <morphinstance_vertex>
              #include <morphcolor_vertex>
              #include <batching_vertex>

              #include <beginnormal_vertex>
              #include <morphnormal_vertex>
              #include <skinbase_vertex>
              #include <skinnormal_vertex>
              #include <defaultnormal_vertex>
              #include <normal_vertex>

              #include <begin_vertex>
              #include <morphtarget_vertex>
              #include <skinning_vertex>
              #include <displacementmap_vertex>
              #include <project_vertex>
              #include <logdepthbuf_vertex>
              #include <clipping_planes_vertex>

              vViewPosition = - mvPosition.xyz;

              #include <worldpos_vertex>
              #include <envmap_vertex>
              #include <shadowmap_vertex>
              #include <fog_vertex>

            }
          """;
          var code:String = StringTools.replace(vertexShader, "/* glsl */", codeString);
          var codeExpr = ExprTools.makeString(code);
          return codeExpr;
        };
      case "fragment":
        return macro {
          var fragmentShader = """
            #define LAMBERT

            uniform vec3 diffuse;
            uniform vec3 emissive;
            uniform float opacity;

            #include <common>
            #include <packing>
            #include <dithering_pars_fragment>
            #include <color_pars_fragment>
            #include <uv_pars_fragment>
            #include <map_pars_fragment>
            #include <alphamap_pars_fragment>
            #include <alphatest_pars_fragment>
            #include <alphahash_pars_fragment>
            #include <aomap_pars_fragment>
            #include <lightmap_pars_fragment>
            #include <emissivemap_pars_fragment>
            #include <envmap_common_pars_fragment>
            #include <envmap_pars_fragment>
            #include <fog_pars_fragment>
            #include <bsdfs>
            #include <lights_pars_begin>
            #include <normal_pars_fragment>
            #include <lights_lambert_pars_fragment>
            #include <shadowmap_pars_fragment>
            #include <bumpmap_pars_fragment>
            #include <normalmap_pars_fragment>
            #include <specularmap_pars_fragment>
            #include <logdepthbuf_pars_fragment>
            #include <clipping_planes_pars_fragment>

            void main() {

              vec4 diffuseColor = vec4( diffuse, opacity );
              #include <clipping_planes_fragment>

              ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
              vec3 totalEmissiveRadiance = emissive;

              #include <logdepthbuf_fragment>
              #include <map_fragment>
              #include <color_fragment>
              #include <alphamap_fragment>
              #include <alphatest_fragment>
              #include <alphahash_fragment>
              #include <specularmap_fragment>
              #include <normal_fragment_begin>
              #include <normal_fragment_maps>
              #include <emissivemap_fragment>

              // accumulation
              #include <lights_lambert_fragment>
              #include <lights_fragment_begin>
              #include <lights_fragment_maps>
              #include <lights_fragment_end>

              // modulation
              #include <aomap_fragment>

              vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;

              #include <envmap_fragment>
              #include <opaque_fragment>
              #include <tonemapping_fragment>
              #include <colorspace_fragment>
              #include <fog_fragment>
              #include <premultiplied_alpha_fragment>
              #include <dithering_fragment>

            }
          """;
          var code:String = StringTools.replace(fragmentShader, "/* glsl */", codeString);
          var codeExpr = ExprTools.makeString(code);
          return codeExpr;
        };
      default:
        return macro {
          throw "Unknown GLSL kind: " + kind;
        };
    }
  }
}

@:macro
class Glsl {
  public static function vertex(code:String):Expr {
    return GlslConverter.convert(code, "vertex");
  }

  public static function fragment(code:String):Expr {
    return GlslConverter.convert(code, "fragment");
  }
}


**Explanation:**

1. **Haxe Macros:** The code uses Haxe macros to dynamically generate the GLSL code. This allows you to embed the GLSL code directly in your Haxe code, making it easier to manage.

2. **Preprocessing:** The `convert` function handles the preprocessing of the GLSL code. It handles comments, strings, and preprocessor directives, ensuring that the generated code is valid Haxe.

3. **Haxe Syntax:** The generated code uses Haxe syntax for string literals and macros.

**How to use:**

1. **Import:** Import the `Glsl` class in your Haxe file.
2. **Use `vertex` or `fragment`:** Use the `vertex` or `fragment` methods of the `Glsl` class to embed your GLSL code.

**Example:**


import Glsl;

class Main {
  static function main() {
    var vertexShader = Glsl.vertex(`
      #define LAMBERT

      varying vec3 vViewPosition;

      // Your GLSL code here...

    `);

    var fragmentShader = Glsl.fragment(`
      #define LAMBERT

      uniform vec3 diffuse;
      uniform vec3 emissive;
      uniform float opacity;

      // Your GLSL code here...

    `);

    // Use vertexShader and fragmentShader variables
  }
}