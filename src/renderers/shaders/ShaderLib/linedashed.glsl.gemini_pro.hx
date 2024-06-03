import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ComplexType;
import haxe.macro.Type;
import haxe.macro.Expr.Identifier;
import haxe.macro.Expr.Const;
import haxe.macro.Expr.Call;

class Glsl {
  static macro(glsl:Expr) : Expr {
    var code = glsl.toString().replace("`", "");
    return Const.CString(code);
  }
}

class VertexShader {
  public static function vertex():Expr {
    return Glsl.glsl(
      """
      uniform float scale;
      attribute float lineDistance;

      varying float vLineDistance;

      #include <common>
      #include <uv_pars_vertex>
      #include <color_pars_vertex>
      #include <fog_pars_vertex>
      #include <morphtarget_pars_vertex>
      #include <logdepthbuf_pars_vertex>
      #include <clipping_planes_pars_vertex>

      void main() {

          vLineDistance = scale * lineDistance;

          #include <uv_vertex>
          #include <color_vertex>
          #include <morphinstance_vertex>
          #include <morphcolor_vertex>
          #include <begin_vertex>
          #include <morphtarget_vertex>
          #include <project_vertex>
          #include <logdepthbuf_vertex>
          #include <clipping_planes_vertex>
          #include <fog_vertex>

      }
      """
    );
  }
}

class FragmentShader {
  public static function fragment():Expr {
    return Glsl.glsl(
      """
      uniform vec3 diffuse;
      uniform float opacity;

      uniform float dashSize;
      uniform float totalSize;

      varying float vLineDistance;

      #include <common>
      #include <color_pars_fragment>
      #include <uv_pars_fragment>
      #include <map_pars_fragment>
      #include <fog_pars_fragment>
      #include <logdepthbuf_pars_fragment>
      #include <clipping_planes_pars_fragment>

      void main() {

          vec4 diffuseColor = vec4( diffuse, opacity );
          #include <clipping_planes_fragment>

          if ( mod( vLineDistance, totalSize ) > dashSize ) {

              discard;

          }

          vec3 outgoingLight = vec3( 0.0 );

          #include <logdepthbuf_fragment>
          #include <map_fragment>
          #include <color_fragment>

          outgoingLight = diffuseColor.rgb; // simple shader

          #include <opaque_fragment>
          #include <tonemapping_fragment>
          #include <colorspace_fragment>
          #include <fog_fragment>
          #include <premultiplied_alpha_fragment>

      }
      """
    );
  }
}


**Explanation:**

1. **Glsl Macro:**
   - We define a `Glsl` class with a `glsl` macro. This macro takes a string expression containing the GLSL code and wraps it in a `Const.CString` expression. This ensures the GLSL code is treated as a raw string literal.

2. **Vertex and Fragment Shaders:**
   - We create `VertexShader` and `FragmentShader` classes with `vertex` and `fragment` static functions, respectively.
   - Inside these functions, we use the `Glsl.glsl` macro to wrap the GLSL code for the shaders.

**Usage:**

To use these shaders, you can access them through their static functions:


var vertexShader = VertexShader.vertex();
var fragmentShader = FragmentShader.fragment();