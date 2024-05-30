import h3d.Material;
import h3d.Shader;
import h3d.Texture;

/**
 * The aim of this mesh material is to use information from a post processing pass in the diffuse color pass.
 * This material is based on the MeshPhysicalMaterial.
 *
 * In the current state, only the information of a screen space AO pass can be used in the material.
 * Actually, the output of any screen space AO (SSAO, GTAO) can be used,
 * as it is only necessary to provide the AO in one color channel of a texture,
 * however the AO pass must be rendered prior to the color pass,
 * which makes the post-processing pass somewhat of a pre-processing pass.
 * For this purpose, a new map (`aoPassMap`) is added to the material.
 * The value of the map is used the same way as the `aoMap` value.
 *
 * Motivation to use the outputs AO pass directly in the material:
 * The incident light of a fragment is composed of ambient light, direct light, and indirect light.
 * Ambient Occlusion only occludes ambient light and environment light but not direct light.
 * Direct light is only occluded by geometry that casts shadows.
 * And of course, emitted light should not be darkened by ambient occlusion either.
 * This cannot be achieved if the AO post-processing pass is simply blended with the diffuse render pass.
 *
 * Further extension work might be to use the output of an SSR pass or an HBIL pass from a previous frame.
 * This would then create the possibility of SSR and IR depending on material properties such as `roughness`, `metalness`, and `reflectivity`.
 */
class MeshPostProcessingMaterial extends Material {
    public var aoPassMap:Texture;
    public var aoPassMapScale:Float;
    private var _shader:Shader;

    public function new(parameters:Dynamic) {
        super(parameters);
        this.aoPassMap = parameters.aoPassMap;
        this.aoPassMapScale = parameters.aoPassMapScale ?? 1.0;
        this.onBeforeCompile = _onBeforeCompile;
        this.customProgramCacheKey = _customProgramCacheKey;
    }

    private function _customProgramCacheKey():String {
        if (aoPassMap != null) {
            return "aoPassMap";
        } else {
            return "";
        }
    }

    private function _onBeforeCompile(shader:Shader) {
        _shader = shader;
        if (aoPassMap != null) {
            shader.fragmentShader = shader.fragmentShader.replace("#include <aomap_pars_fragment>", aomap_pars_fragment_replacement);
            shader.fragmentShader = shader.fragmentShader.replace("#include <aomap_fragment>", aomap_fragment_replacement);
        }
        _setUniforms();
    }

    private function _setUniforms() {
        if (_shader != null) {
            _shader.uniforms.tAoPassMap = { value: aoPassMap };
            _shader.uniforms.aoPassMapScale = { value: aoPassMapScale };
        }
    }

    private static var aomap_pars_fragment_replacement:String = "
#ifdef USE_AOMAP
    uniform sampler2D aoMap;
    uniform float aoMapIntensity;
#endif
    uniform sampler2D tAoPassMap;
    uniform float aoPassMapScale;
";

    private static var aomap_fragment_replacement:String = "
#ifndef AOPASSMAP_SWIZZLE
    #define AOPASSMAP_SWIZZLE r
#endif
    float ambientOcclusion = texelFetch(tAoPassMap, ivec2(gl_FragCoord.xy * aoPassMapScale), 0).AOPASSMAP_SWIZZLE;

#ifdef USE_AOMAP
    // reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
    ambientOcclusion = min(ambientOcclusion, texture2D(aoMap, vAoMapUv).r);
    ambientOcclusion *= (ambientOcclusion - 1.0) * aoMapIntensity + 1.0;
#endif

    reflectedLight.indirectDiffuse *= ambientOcclusion;

#if defined(USE_CLEARCOAT)
    clearcoatSpecularIndirect *= ambientOcclusion;
#endif

#if defined(USE_SHEEN)
    sheenSpecularIndirect *= ambientOcclusion;
#endif

#if defined(USE_ENVMAP) && defined(STANDARD)
    float dotNV = saturate(dot(geometryNormal, geometryViewDir));
    reflectedLight.indirectSpecular *= computeSpecularOcclusion(dotNV, ambientOcclusion, material.roughness);
#endif
";
}