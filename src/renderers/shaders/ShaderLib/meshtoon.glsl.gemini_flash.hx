import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;

class ToonShader {

  public static function vertex(ctx:Context):Expr {
    return macro {
      #define TOON

      varying vec3 vViewPosition;

      #include <common>
      #include <batching_pars_vertex>
      #include <uv_pars_vertex>
      #include <displacementmap_pars_vertex>
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
        #include <shadowmap_vertex>
        #include <fog_vertex>

      }
    };
  }

  public static function fragment(ctx:Context):Expr {
    return macro {
      #define TOON

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
      #include <gradientmap_pars_fragment>
      #include <fog_pars_fragment>
      #include <bsdfs>
      #include <lights_pars_begin>
      #include <normal_pars_fragment>
      #include <lights_toon_pars_fragment>
      #include <shadowmap_pars_fragment>
      #include <bumpmap_pars_fragment>
      #include <normalmap_pars_fragment>
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
        #include <normal_fragment_begin>
        #include <normal_fragment_maps>
        #include <emissivemap_fragment>

        // accumulation
        #include <lights_toon_fragment>
        #include <lights_fragment_begin>
        #include <lights_fragment_maps>
        #include <lights_fragment_end>

        // modulation
        #include <aomap_fragment>

        vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;

        #include <opaque_fragment>
        #include <tonemapping_fragment>
        #include <colorspace_fragment>
        #include <fog_fragment>
        #include <premultiplied_alpha_fragment>
        #include <dithering_fragment>

      }
    };
  }
}


This code provides two Haxe functions `vertex` and `fragment` that encapsulate the JavaScript GLSL code provided.

Here's a breakdown of the code:

1. **Import necessary macros:**
   - `haxe.macro.Expr`: This is used to construct expressions in Haxe macros.
   - `haxe.macro.Context`: This provides access to the compilation context within a macro.
   - `haxe.macro.Type`: Used for working with type information within macros.

2. **Define `ToonShader` class:**
   - This class serves as a container for the GLSL code.

3. **`vertex` function:**
   - Takes a `Context` as an argument, representing the compilation context.
   - Uses the `macro` keyword to embed GLSL code directly into the Haxe code.
   - Defines the `#define TOON` preprocessor directive and the `varying` variable.
   - Includes standard GLSL libraries and functions.
   - Contains the vertex shader logic, which includes:
     - Transforming the vertex position.
     - Calculating view position.
     - Applying shaders and lighting effects.

4. **`fragment` function:**
   - Similar structure to the `vertex` function.
   - Defines `uniform` variables for diffuse color, emissive color, and opacity.
   - Includes additional GLSL libraries and functions.
   - Contains the fragment shader logic, which includes:
     - Calculating the final color of the fragment based on:
       - Diffuse color, emissive color, opacity.
       - Lighting effects, including toon shading.
       - Texture sampling, if applicable.
       - Other effects like ambient occlusion, fog.

This code essentially provides a way to define and embed GLSL code within Haxe, which can be used to create shaders for graphics rendering. The `vertex` and `fragment` functions represent the vertex and fragment shaders, respectively, which are essential components of the shader pipeline.

**To use this code:**

1. You would need to use the `macro` keyword in your Haxe code where you want to include the GLSL code:

   
   var vertexShader = ToonShader.vertex(ctx);
   var fragmentShader = ToonShader.fragment(ctx);