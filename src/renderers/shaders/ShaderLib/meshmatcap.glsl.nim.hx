package three.src.renderers.shaders.ShaderLib;

import three.src.renderers.shaders.ShaderChunk.common;
import three.src.renderers.shaders.ShaderChunk.batching_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.uv_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.color_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.displacementmap_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.fog_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.normal_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.morphtarget_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.skinning_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.logdepthbuf_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.clipping_planes_pars_vertex;
import three.src.renderers.shaders.ShaderChunk.uv_vertex;
import three.src.renderers.shaders.ShaderChunk.color_vertex;
import three.src.renderers.shaders.ShaderChunk.morphinstance_vertex;
import three.src.renderers.shaders.ShaderChunk.morphcolor_vertex;
import three.src.renderers.shaders.ShaderChunk.batching_vertex;
import three.src.renderers.shaders.ShaderChunk.beginnormal_vertex;
import three.src.renderers.shaders.ShaderChunk.morphnormal_vertex;
import three.src.renderers.shaders.ShaderChunk.skinbase_vertex;
import three.src.renderers.shaders.ShaderChunk.skinnormal_vertex;
import three.src.renderers.shaders.ShaderChunk.defaultnormal_vertex;
import three.src.renderers.shaders.ShaderChunk.normal_vertex;
import three.src.renderers.shaders.ShaderChunk.begin_vertex;
import three.src.renderers.shaders.ShaderChunk.morphtarget_vertex;
import three.src.renderers.shaders.ShaderChunk.skinning_vertex;
import three.src.renderers.shaders.ShaderChunk.displacementmap_vertex;
import three.src.renderers.shaders.ShaderChunk.project_vertex;
import three.src.renderers.shaders.ShaderChunk.logdepthbuf_vertex;
import three.src.renderers.shaders.ShaderChunk.clipping_planes_vertex;
import three.src.renderers.shaders.ShaderChunk.fog_vertex;
import three.src.renderers.shaders.ShaderChunk.dithering_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.color_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.uv_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.map_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.alphamap_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.alphatest_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.alphahash_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.fog_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.normal_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.bumpmap_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.normalmap_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.logdepthbuf_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.clipping_planes_pars_fragment;
import three.src.renderers.shaders.ShaderChunk.clipping_planes_fragment;
import three.src.renderers.shaders.ShaderChunk.logdepthbuf_fragment;
import three.src.renderers.shaders.ShaderChunk.map_fragment;
import three.src.renderers.shaders.ShaderChunk.color_fragment;
import three.src.renderers.shaders.ShaderChunk.alphamap_fragment;
import three.src.renderers.shaders.ShaderChunk.alphatest_fragment;
import three.src.renderers.shaders.ShaderChunk.alphahash_fragment;
import three.src.renderers.shaders.ShaderChunk.normal_fragment_begin;
import three.src.renderers.shaders.ShaderChunk.normal_fragment_maps;
import three.src.renderers.shaders.ShaderChunk.opaque_fragment;
import three.src.renderers.shaders.ShaderChunk.tonemapping_fragment;
import three.src.renderers.shaders.ShaderChunk.colorspace_fragment;
import three.src.renderers.shaders.ShaderChunk.fog_fragment;
import three.src.renderers.shaders.ShaderChunk.premultiplied_alpha_fragment;
import three.src.renderers.shaders.ShaderChunk.dithering_fragment;

class MeshMatcapShader {
    static var vertex = [
        '#define MATCAP',
        'varying vec3 vViewPosition;',
        common,
        batching_pars_vertex,
        uv_pars_vertex,
        color_pars_vertex,
        displacementmap_pars_vertex,
        fog_pars_vertex,
        normal_pars_vertex,
        morphtarget_pars_vertex,
        skinning_pars_vertex,
        logdepthbuf_pars_vertex,
        clipping_planes_pars_vertex,
        'void main() {',
        uv_vertex,
        color_vertex,
        morphinstance_vertex,
        morphcolor_vertex,
        batching_vertex,
        beginnormal_vertex,
        morphnormal_vertex,
        skinbase_vertex,
        skinnormal_vertex,
        defaultnormal_vertex,
        normal_vertex,
        begin_vertex,
        morphtarget_vertex,
        skinning_vertex,
        displacementmap_vertex,
        project_vertex,
        logdepthbuf_vertex,
        clipping_planes_vertex,
        fog_vertex,
        'vViewPosition = - mvPosition.xyz;',
        '}'
    ].join('\n');

    static var fragment = [
        '#define MATCAP',
        'uniform vec3 diffuse;',
        'uniform float opacity;',
        'uniform sampler2D matcap;',
        'varying vec3 vViewPosition;',
        common,
        dithering_pars_fragment,
        color_pars_fragment,
        uv_pars_fragment,
        map_pars_fragment,
        alphamap_pars_fragment,
        alphatest_pars_fragment,
        alphahash_pars_fragment,
        fog_pars_fragment,
        normal_pars_fragment,
        bumpmap_pars_fragment,
        normalmap_pars_fragment,
        logdepthbuf_pars_fragment,
        clipping_planes_pars_fragment,
        'void main() {',
        'vec4 diffuseColor = vec4( diffuse, opacity );',
        clipping_planes_fragment,
        logdepthbuf_fragment,
        map_fragment,
        color_fragment,
        alphamap_fragment,
        alphatest_fragment,
        alphahash_fragment,
        normal_fragment_begin,
        normal_fragment_maps,
        'vec3 viewDir = normalize( vViewPosition );',
        'vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );',
        'vec3 y = cross( viewDir, x );',
        'vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5; // 0.495 to remove artifacts caused by undersized matcap disks',
        '#ifdef USE_MATCAP',
        'vec4 matcapColor = texture2D( matcap, uv );',
        '#else',
        'vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 ); // default if matcap is missing',
        '#endif',
        'vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;',
        opaque_fragment,
        tonemapping_fragment,
        colorspace_fragment,
        fog_fragment,
        premultiplied_alpha_fragment,
        dithering_fragment,
        '}'
    ].join('\n');
}