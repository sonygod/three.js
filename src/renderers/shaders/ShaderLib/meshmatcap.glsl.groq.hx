package three.shaderlib;

import three.shaderlib.common.Common;
import three.shaderlib.batching.Batching;
import three.shaderlib.uv.UV;
import three.shaderlib.color.Color;
import three.shaderlib.displacementmap.DisplacementMap;
import three.shaderlib.fog.Fog;
import three.shaderlib.normal.Normal;
import three.shaderlib.morphtarget.MorphTarget;
import three.shaderlib.skinning.Skinning;
import three.shaderlib.logdepthbuf.LogDepthBuf;
import three.shaderlib.clippingplanes.ClippingPlanes;

class MeshMatcapShader {
    public static var vertex:String = "
#define MATCAP

varying vec3 vViewPosition;

" + Common.common +
Batching.batching_pars_vertex +
UV.uv_pars_vertex +
Color.color_pars_vertex +
DisplacementMap.displacementmap_pars_vertex +
Fog.fog_pars_vertex +
Normal.normal_pars_vertex +
MorphTarget.morphtarget_pars_vertex +
Skinning.skinning_pars_vertex +
LogDepthBuf.logdepthbuf_pars_vertex +
ClippingPlanes.clipping_planes_pars_vertex +

"void main() {

    " + UV.uv_vertex +
Color.color_vertex +
MorphTarget.morphinstance_vertex +
MorphTarget.morphcolor_vertex +
Batching.batching_vertex +

Normal.beginnormal_vertex +
MorphTarget.morphnormal_vertex +
Skinning.skinbase_vertex +
Skinning.skinnormal_vertex +
Normal.defaultnormal_vertex +
Normal.normal_vertex +

MorphTarget.morphtarget_vertex +
Skinning.skinning_vertex +
DisplacementMap.displacementmap_vertex +
" project_vertex() + "

    LogDepthBuf.logdepthbuf_vertex +
ClippingPlanes.clipping_planes_vertex +
Fog.fog_vertex +

vViewPosition = - mvPosition.xyz;

}";

public static var fragment:String = "
#define MATCAP

uniform vec3 diffuse;
uniform float opacity;
uniform sampler2D matcap;

varying vec3 vViewPosition;

" + Common.common +
"<dithering_pars_fragment>" +
Color.color_pars_fragment +
UV.uv_pars_fragment +
"<map_pars_fragment>" +
"<alphamap_pars_fragment>" +
"<alphatest_pars_fragment>" +
"<alphahash_pars_fragment>" +
Fog.fog_pars_fragment +
Normal.normal_pars_fragment +
"<bumpmap_pars_fragment>" +
"<normalmap_pars_fragment>" +
LogDepthBuf.logdepthbuf_pars_fragment +
ClippingPlanes.clipping_planes_pars_fragment +

"void main() {

    vec4 diffuseColor = vec4( diffuse, opacity );
    " + ClippingPlanes.clipping_planes_fragment +

    LogDepthBuf.logdepthbuf_fragment +
"<map_fragment>" +
Color.color_fragment +
"<alphamap_fragment>" +
"<alphatest_fragment>" +
"<alphahash_fragment>" +
Normal.normal_fragment_begin +
Normal.normal_fragment_maps +

    vec3 viewDir = normalize( vViewPosition );
    vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
    vec3 y = cross( viewDir, x );
    vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;

    #ifdef USE_MATCAP

        vec4 matcapColor = texture2D( matcap, uv );

    #else

        vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );

    #endif

    vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;

    <opaque_fragment>" +
"<tonemapping_fragment>" +
"<colorspace_fragment>" +
Fog.fog_fragment +
"<premultiplied_alpha_fragment>" +
"<dithering_fragment>

}";
}