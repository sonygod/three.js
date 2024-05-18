package three.shaderlib;

import haxe.ds.StringMap;

class PointsShader {
  public static var vertex:String = "
  uniform float size;
  uniform float scale;

  #ifdef USE_POINTS_UV
  varying vec2 vUv;
  uniform mat3 uvTransform;

  void main() {
    #ifdef USE_POINTS_UV
    vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
    #endif

    #include <color_vertex>
    #include <morphinstance_vertex>
    #include <morphcolor_vertex>
    #include <begin_vertex>
    #include <morphtarget_vertex>
    #include <project_vertex>

    gl_PointSize = size;

    #ifdef USE_SIZEATTENUATION
    bool isPerspective = isPerspectiveMatrix( projectionMatrix );

    if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );
    #endif

    #include <logdepthbuf_vertex>
    #include <clipping_planes_vertex>
    #include <worldpos_vertex>
    #include <fog_vertex>
  }
  ";

  public static var fragment:String = "
  uniform vec3 diffuse;
  uniform float opacity;

  void main() {
    vec4 diffuseColor = vec4( diffuse, opacity );

    #include <clipping_planes_fragment>

    vec3 outgoingLight = vec3( 0.0 );

    #include <logdepthbuf_fragment>
    #include <map_particle_fragment>
    #include <color_fragment>
    #include <alphatest_fragment>
    #include <alphahash_fragment>

    outgoingLight = diffuseColor.rgb;

    #include <opaque_fragment>
    #include <tonemapping_fragment>
    #include <colorspace_fragment>
    #include <fog_fragment>
    #include <premultiplied_alpha_fragment>
  }
  ";
}