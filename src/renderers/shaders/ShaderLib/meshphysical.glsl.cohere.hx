package openfl.display3D.textures;

class StandardShader {
    public static var vertex:String =
        "#define STANDARD\n" +
        "\n" +
        "varying vec3 vViewPosition;\n" +
        "\n" +
        "#ifdef USE_TRANSMISSION\n" +
        "\t\n" +
        "varying vec3 vWorldPosition;\n" +
        "\n" +
        "#endif\n" +
        "\n" +
        "#include <common>\n" +
        "#include <batching_pars_vertex>\n" +
        "#include <uv_pars_vertex>\n" +
        "#include <displacementmap_pars_vertex>\n" +
        "#include <color_pars_vertex>\n" +
        "#include <fog_pars_vertex>\n" +
        "#include <normal_pars_vertex>\n" +
        "#include <morphtarget_pars_vertex>\n" +
        "#include <skinning_pars_vertex>\n" +
        "#include <shadowmap_pars_vertex>\n" +
        "#include <logdepthbuf_pars_vertex>\n" +
        "#include <clipping_planes_pars_vertex>\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	#include <uv_vertex>\n" +
        "	#include <color_vertex>\n" +
        "	#include <morphinstance_vertex>\n" +
        "	#include <morphcolor_vertex>\n" +
        "	#Multiplier = 1.0;\n" +
        "	#include <batching_vertex>\n" +
        "\n" +
        "	#include <beginnormal_vertex>\n" +
        "	#include <morphnormal_vertex>\n" +
        "	#include <skinbase_vertex>\n" +
        "	#include <skinnormal_vertex>\n" +
        "	#include <defaultnormal_vertex>\n" +
        "	#include <normal_vertex>\n" +
        "\n" +
        "	#include <begin_vertex>\n" +
        "	#include <morphtarget_vertex>\n" +
        "	#include <skinning_vertex>\n" +
        "	#include <displacementmap_vertex>\n" +
        "	#include <project_vertex>\n" +
        "	#include <logdepthbuf_vertex>\n" +
        "	#include <clipping_planes_vertex>\n" +
        "\n" +
        "	vViewPosition = - mvPosition.xyz;\n" +
        "\n" +
        "	#include <worldpos_vertex>\n" +
        "	#include <shadowmap_vertex>\n" +
        "	#include <fog_vertex>\n" +
        "\n" +
        "#ifdef USE_TRANSMISSION\n" +
        "\n" +
        "	vWorldPosition = worldPosition.xyz;\n" +
        "\n" +
        "#endif\n" +
        "}";

    public static var fragment:String =
        "#define STANDARD\n" +
        "\n" +
        "#ifdef PHYSICAL\n" +
        "	#define IOR\n" +
        "	#define USE_SPECULAR\n" +
        "#endif\n" +
        "\n" +
        "uniform vec3 diffuse;\n" +
        "uniform vec3 emissive;\n" +
        "uniform float roughness;\n" +
        "uniform float metalness;\n" +
        "uniform float opacity;\n" +
        "\n" +
        "#ifdef IOR\n" +
        "	uniform float ior;\n" +
        "#endif\n" +
        "\n" +
        "#ifdef USE_SPECULAR\n" +
        "	uniform float specularIntensity;\n" +
        "	uniform vec3 specularColor;\n" +
        "\n" +
        "	#ifdef USE_SPECULAR_COLORMAP\n" +
        "		uniform sampler2D specularColorMap;\n" +
        "	#endif\n" +
        "\n" +
        "	#ifdef USE_SPECULAR_INTENSITYMAP\n" +
        "		uniform sampler2D specularIntensityMap;\n" +
        "	#endif\n" +
        "#endif\n" +
        "\n" +
        "#ifdef USE_CLEARCOAT\n" +
        "	uniform float clearcoat;\n" +
        "	uniform float clearcoatRoughness;\n" +
        "#endif\n" +
        "\n" +
        "#ifdef USE_DISPERSION\n" +
        "	uniform float dispersion;\n" +
        "#endif\n" +
        "\n" +
        "#ifdef USE_IRIDESCENCE\n" +
        "	uniform float iridescence;\n" +
        "	uniform float iridescenceIOR;\n" +
        "	uniform float iridescenceThicknessMinimum;\n" +
        "	uniform float iridescenceThicknessMaximum;\n" +
        "#endif\n" +
        "\n" +
        "#ifdef USE_SHEEN\n" +
        "	uniform vec3 sheenColor;\n" +
        "	uniform float sheenRoughness;\n" +
        "\n" +
        "	#ifdef USE_SHEEN_COLORMAP\n" +
        "		uniform sampler2D sheenColorMap;\n" +
        "	#endif\n" +
        "\n" +
        "	#ifdef USE_SHEEN_ROUGHNESSMAP\n" +
        "		uniform sampler2D sheenRoughnessMap;\n" +
        "	#endif\n" +
        "#endif\n" +
        "\n" +
        "#ifdef USE_ANISOTROPY\n" +
        "	uniform vec2 anisotropyVector;\n" +
        "\n" +
        "	#ifdef USE_ANISOTROPYMAP\n" +
        "		uniform sampler2D anisotropyMap;\n" +
        "	#endif\n" +
        "#endif\n" +
        "\n" +
        "varying vec3 vViewPosition;\n" +
        "\n" +
        "#include <common>\n" +
        "#include <packing>\n" +
        "#include <dithering_pars_fragment>\n" +
        "#include <color_pars_fragment>\n" +
        "#include <uv_pars_fragment>\n" +
        "#include <map_pars_fragment>\n" +
        "#include <alphamap_pars_fragment>\n" +
        "#include <alphatest_pars_fragment>\n" +
        "#include <alphahash_pars_fragment>\n" +
        "#include <aomap_pars_fragment>\n" +
        "#include <lightmap_pars_fragment>\n" +
        "#include <emissivemap_pars_fragment>\n" +
        "#include <iridescence_fragment>\n" +
        "#include <cube_uv_reflection_fragment>\n" +
        "#include <envmap_common_pars_fragment>\n" +
        "#include <envmap_physical_pars_fragment>\n" +
        "#include <fog_pars_fragment>\n" +
        "#include <lights_pars_begin>\n" +
        "#include <normal_pars_fragment>\n" +
        "#include <lights_physical_pars_fragment>\n" +
        "#include <transmission_pars_fragment>\n" +
        "#include <shadowmap_pars_fragment>\n" +
        "#include <bumpmap_pars_fragment>\n" +
        "#include <normalmap_pars_fragment>\n" +
        "#include <clearcoat_pars_fragment>\n" +
        "#include <iridescence_pars_fragment>\n" +
        "#include <roughnessmap_pars_fragment>\n" +
        "#include <metalnessmap_pars_fragment>\n" +
        "#include <logdepthbuf_pars_fragment>\n" +
        "#include <clipping_planes_pars_fragment>\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	vec4 diffuseColor = vec4( diffuse, opacity );\n" +
        "	#include <clipping_planes_fragment>\n" +
        "\n" +
        "	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );\n" +
        "	vec3 totalEmissiveRadiance = emissive;\n" +
        "\n" +
        "	#include <logdepthbuf_fragment>\n" +
        "	#include <map_fragment>\n" +
        "	#include <color_fragment>\n" +
        "	#include <alphamap_fragment>\n" +
        "	#include <alphatest_fragment>\n" +
        "	#include <alphahash_fragment>\n" +
        "	#include <roughnessmap_fragment>\n" +
        "	#include <metalnessmap_fragment>\n" +
        "	#include <normal_fragment_begin>\n" +
        "	#include <normal_fragment_maps>\n" +
        "	#include <clearcoat_normal_fragment_begin>\n" +
        "	#include <clearcoat_normal_fragment_maps>\n" +
        "	#include <emissivemap_fragment>\n" +
        "\n" +
        "	// accumulation\n" +
        "	#include <lights_physical_fragment>\n" +
        "	#include <lights_fragment_begin>\n" +
        "	#include <lights_fragment_maps>\n" +
        "	#include <lights_fragment_end>\n" +
        "\n" +
        "	// modulation\n" +
        "	#include <aomap_fragment>\n" +
        "\n" +
        "	vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;\n" +
        "	vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;\n" +
        "\n" +
        "	#include <transmission_fragment>\n" +
        "\n" +
        "	vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;\n" +
        "\n" +
        "#ifdef USE_SHEEN\n" +
        "\n" +
        "	// Sheen energy compensation approximation calculation can be found at the end of\n" +
        "	// https://drive.google.com/file/d/1T0D1VSyR4AllqIJTQAraEIzjlb5h4FKH/view?usp=sharing\n" +
        "	float sheenEnergyComp = 1.0 - 0.157 * max3( material.sheenColor );\n" +
        "\n" +
        "	outgoingLight = outgoingLight * sheenEnergyComp + sheenSpecularDirect + sheenSpecularIndirect;\n" +
        "\n" +
        "#endif\n" +
        "\n" +
        "#ifdef USE_CLEARCOAT\n" +
        "\n" +
        "	float dotNVcc = saturate( dot( geometryClearcoatNormal, geometryViewDir ) );\n" +
        "\n" +
        "	vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );\n" +
        "\n" +
        "	outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + ( clearcoatSpecularDirect + clearcoatSpecularIndirect ) * material.clearcoat;\n" +
        "\n" +
        "#endif\n" +
        "\n" +
        "	#include <opaque_fragment>\n" +
        "	#include <tonemapping_fragment>\n" +
        "	#include <colorspace_fragment>\n" +
        "	#include <fog_fragment>\n" +
        "	#include <premultiplied_alpha_fragment>\n" +
        "	#include <dithering_fragment>\n" +
        "\n" +
        "}";
}