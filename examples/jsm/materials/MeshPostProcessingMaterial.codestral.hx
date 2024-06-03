import three.materials.MeshPhysicalMaterial;
import three.textures.Texture;
import three.shaders.Shader;
import three.uniforms.Uniform;

class MeshPostProcessingMaterial extends MeshPhysicalMaterial {

    private var _aoPassMap: Texture;
    private var _aoPassMapScale: Float;
    private var _shader: Shader;

    public function new(parameters: Dynamic) {
        super(parameters);

        this._aoPassMap = parameters.aoPassMap;
        this._aoPassMapScale = parameters.aoPassMapScale != null ? parameters.aoPassMapScale : 1.0;
        delete parameters.aoPassMap;
        delete parameters.aoPassMapScale;

        this._shader = null;
    }

    public function get_aoPassMap(): Texture {
        return this._aoPassMap;
    }

    public function set_aoPassMap(aoPassMap: Texture) {
        this._aoPassMap = aoPassMap;
        this.needsUpdate = true;
        this._setUniforms();
    }

    private function _customProgramCacheKey(): String {
        return this._aoPassMap != null ? 'aoPassMap' : '';
    }

    private function _onBeforeCompile(shader: Shader) {
        this._shader = shader;

        if (this._aoPassMap != null) {
            shader.fragmentShader = shader.fragmentShader.replace('#include <aomap_pars_fragment>', aomap_pars_fragment_replacement);
            shader.fragmentShader = shader.fragmentShader.replace('#include <aomap_fragment>', aomap_fragment_replacement);
        }

        this._setUniforms();
    }

    private function _setUniforms() {
        if (this._shader != null) {
            this._shader.uniforms.tAoPassMap = new Uniform(this._aoPassMap);
            this._shader.uniforms.aoPassMapScale = new Uniform(this._aoPassMapScale);
        }
    }
}

final var aomap_pars_fragment_replacement = "
#ifdef USE_AOMAP

	uniform sampler2D aoMap;
	uniform float aoMapIntensity;

#endif

	uniform sampler2D tAoPassMap;
	uniform float aoPassMapScale;
";

final var aomap_fragment_replacement = "
#ifndef AOPASSMAP_SWIZZLE
	#define AOPASSMAP_SWIZZLE r
#endif
	float ambientOcclusion = texelFetch( tAoPassMap, ivec2( gl_FragCoord.xy * aoPassMapScale ), 0 ).AOPASSMAP_SWIZZLE;

#ifdef USE_AOMAP

	// reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
	ambientOcclusion = min( ambientOcclusion, texture2D( aoMap, vAoMapUv ).r );
	ambientOcclusion *= ( ambientOcclusion - 1.0 ) * aoMapIntensity + 1.0;

#endif

	reflectedLight.indirectDiffuse *= ambientOcclusion;

	#if defined( USE_CLEARCOAT )
		clearcoatSpecularIndirect *= ambientOcclusion;
	#endif

	#if defined( USE_SHEEN )
		sheenSpecularIndirect *= ambientOcclusion;
	#endif

	#if defined( USE_ENVMAP ) && defined( STANDARD )

		float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );

		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );

	#endif
";