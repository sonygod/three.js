// File path: three.js/src/renderers/shaders/ShaderLib/meshphysical.glsl.hx
import three.renderers.shaders.ShaderChunk;

class MeshPhysicalGLSL {

    public static final vertex:String = "
    #define STANDARD

    varying vec3 vViewPosition;

    #if defined(USE_TRANSMISSION)
        varying vec3 vWorldPosition;
    #end

    @:include('common')
    @:include('batching_pars_vertex')
    @:include('uv_pars_vertex')
    @:include('displacementmap_pars_vertex')
    @:include('color_pars_vertex')
    @:include('fog_pars_vertex')
    @:include('normal_pars_vertex')
    @:include('morphtarget_pars_vertex')
    @:include('skinning_pars_vertex')
    @:include('shadowmap_pars_vertex')
    @:include('logdepthbuf_pars_vertex')
    @:include('clipping_planes_pars_vertex')

    void main() {
        @:include('uv_vertex')
        @:include('color_vertex')
        @:include('morphinstance_vertex')
        @:include('morphcolor_vertex')
        @:include('batching_vertex')

        @:include('beginnormal_vertex')
        @:include('morphnormal_vertex')
        @:include('skinbase_vertex')
        @:include('skinnormal_vertex')
        @:include('defaultnormal_vertex')
        @:include('normal_vertex')

        @:include('begin_vertex')
        @:include('morphtarget_vertex')
        @:include('skinning_vertex')
        @:include('displacementmap_vertex')
        @:include('project_vertex')
        @:include('logdepthbuf_vertex')
        @:include('clipping_planes_vertex')

        vViewPosition = -mvPosition.xyz;

        @:include('worldpos_vertex')
        @:include('shadowmap_vertex')
        @:include('fog_vertex')

        #if defined(USE_TRANSMISSION)
            vWorldPosition = worldPosition.xyz;
        #end
    }
    ";

    public static final fragment:String = "
    #define STANDARD

    #if defined(PHYSICAL)
        #define IOR
        #define USE_SPECULAR
    #end

    uniform vec3 diffuse;
    uniform vec3 emissive;
    uniform float roughness;
    uniform float metalness;
    uniform float opacity;

    #if defined(IOR)
        uniform float ior;
    #end

    #if defined(USE_SPECULAR)
        uniform float specularIntensity;
        uniform vec3 specularColor;

        #if defined(USE_SPECULAR_COLORMAP)
            uniform sampler2D specularColorMap;
        #end

        #if defined(USE_SPECULAR_INTENSITYMAP)
            uniform sampler2D specularIntensityMap;
        #end
    #end

    #if defined(USE_CLEARCOAT)
        uniform float clearcoat;
        uniform float clearcoatRoughness;
    #end

    #if defined(USE_DISPERSION)
        uniform float dispersion;
    #end

    #if defined(USE_IRIDESCENCE)
        uniform float iridescence;
        uniform float iridescenceIOR;
        uniform float iridescenceThicknessMinimum;
        uniform float iridescenceThicknessMaximum;
    #end

    #if defined(USE_SHEEN)
        uniform vec3 sheenColor;
        uniform float sheenRoughness;

        #if defined(USE_SHEEN_COLORMAP)
            uniform sampler2D sheenColorMap;
        #end

        #if defined(USE_SHEEN_ROUGHNESSMAP)
            uniform sampler2D sheenRoughnessMap;
        #end
    #end

    #if defined(USE_ANISOTROPY)
        uniform vec2 anisotropyVector;

        #if defined(USE_ANISOTROPYMAP)
            uniform sampler2D anisotropyMap;
        #end
    #end

    varying vec3 vViewPosition;

    @:include('common')
    @:include('packing')
    @:include('dithering_pars_fragment')
    @:include('color_pars_fragment')
    @:include('uv_pars_fragment')
    @:include('map_pars_fragment')
    @:include('alphamap_pars_fragment')
    @:include('alphatest_pars_fragment')
    @:include('alphahash_pars_fragment')
    @:include('aomap_pars_fragment')
    @:include('lightmap_pars_fragment')
    @:include('emissivemap_pars_fragment')
    @:include('iridescence_fragment')
    @:include('cube_uv_reflection_fragment')
    @:include('envmap_common_pars_fragment')
    @:include('envmap_physical_pars_fragment')
    @:include('fog_pars_fragment')
    @:include('lights_pars_begin')
    @:include('normal_pars_fragment')
    @:include('lights_physical_pars_fragment')
    @:include('transmission_pars_fragment')
    @:include('shadowmap_pars_fragment')
    @:include('bumpmap_pars_fragment')
    @:include('normalmap_pars_fragment')
    @:include('clearcoat_pars_fragment')
    @:include('iridescence_pars_fragment')
    @:include('roughnessmap_pars_fragment')
    @:include('metalnessmap_pars_fragment')
    @:include('logdepthbuf_pars_fragment')
    @:include('clipping_planes_pars_fragment')

    void main() {
        vec4 diffuseColor = vec4(diffuse, opacity);
        @:include('clipping_planes_fragment')

        ReflectedLight reflectedLight = ReflectedLight(vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0));
        vec3 totalEmissiveRadiance = emissive;

        @:include('logdepthbuf_fragment')
        @:include('map_fragment')
        @:include('color_fragment')
        @:include('alphamap_fragment')
        @:include('alphatest_fragment')
        @:include('alphahash_fragment')
        @:include('roughnessmap_fragment')
        @:include('metalnessmap_fragment')
        @:include('normal_fragment_begin')
        @:include('normal_fragment_maps')
        @:include('clearcoat_normal_fragment_begin')
        @:include('clearcoat_normal_fragment_maps')
        @:include('emissivemap_fragment')

        // accumulation
        @:include('lights_physical_fragment')
        @:include('lights_fragment_begin')
        @:include('lights_fragment_maps')
        @:include('lights_fragment_end')

        // modulation
        @:include('aomap_fragment')

        vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
        vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;

        @:include('transmission_fragment')

        vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;

        #if defined(USE_SHEEN)
            // Sheen energy compensation approximation calculation can be found at the end of
            // https://drive.google.com/file/d/1T0D1VSyR4AllqIJTQAraEIzjlb5h4FKH/view?usp=sharing
            float sheenEnergyComp = 1.0 - 0.157 * max3(material.sheenColor);
            outgoingLight = outgoingLight * sheenEnergyComp + sheenSpecularDirect + sheenSpecularIndirect;
        #end

        #if defined(USE_CLEARCOAT)
            float dotNVcc = saturate(dot(geometryClearcoatNormal, geometryViewDir));
            vec3 Fcc = F_Schlick(material.clearcoatF0, material.clearcoatF90, dotNVcc);
            outgoingLight = outgoingLight * (1.0 - material.clearcoat * Fcc) + (clearcoatSpecularDirect + clearcoatSpecularIndirect) * material.clearcoat;
        #end

        @:include('opaque_fragment')
        @:include('tonemapping_fragment')
        @:include('colorspace_fragment')
        @:include('fog_fragment')
        @:include('premultiplied_alpha_fragment')
        @:include('dithering_fragment')
    }
    ";
}