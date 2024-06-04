import three.UniformsLib;
import three.UniformsUtils;
import three.ShaderMaterial;
import three.Color;
import three.MultiplyOperation;

class GouraudShader {
	public static var name:String = "GouraudShader";
	public static var uniforms:Dynamic = UniformsUtils.merge([
		UniformsLib.common,
		UniformsLib.specularmap,
		UniformsLib.envmap,
		UniformsLib.aomap,
		UniformsLib.lightmap,
		UniformsLib.emissivemap,
		UniformsLib.fog,
		UniformsLib.lights,
		{
			emissive: { value: new Color(0x000000) }
		}
	]);
	public static var vertexShader:String = `

		#define GOURAUD

		varying vec3 vLightFront;
		varying vec3 vIndirectFront;

		#ifdef DOUBLE_SIDED
			varying vec3 vLightBack;
			varying vec3 vIndirectBack;
		#endif

		#include <common>
		#include <uv_pars_vertex>
		#include <envmap_pars_vertex>
		#include <bsdfs>
		#include <lights_pars_begin>
		#include <color_pars_vertex>
		#include <fog_pars_vertex>
		#include <morphtarget_pars_vertex>
		#include <skinning_pars_vertex>
		#include <shadowmap_pars_vertex>
		#include <logdepthbuf_pars_vertex>
		#include <clipping_planes_pars_vertex>

		void main() {

			#include <uv_vertex>
			#include <color_vertex>
			#include <morphcolor_vertex>

			#include <beginnormal_vertex>
			#include <morphnormal_vertex>
			#include <skinbase_vertex>
			#include <skinnormal_vertex>
			#include <defaultnormal_vertex>

			#include <begin_vertex>
			#include <morphtarget_vertex>
			#include <skinning_vertex>
			#include <project_vertex>
			#include <logdepthbuf_vertex>
			#include <clipping_planes_vertex>

			#include <worldpos_vertex>
			#include <envmap_vertex>

			// inlining legacy <lights_lambert_vertex>

			vec3 diffuse = vec3( 1.0 );

			vec3 geometryPosition = mvPosition.xyz;
			vec3 geometryNormal = normalize( transformedNormal );
			vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( -mvPosition.xyz );

			vec3 backGeometryNormal = - geometryNormal;

			vLightFront = vec3( 0.0 );
			vIndirectFront = vec3( 0.0 );
			#ifdef DOUBLE_SIDED
				vLightBack = vec3( 0.0 );
				vIndirectBack = vec3( 0.0 );
			#endif

			IncidentLight directLight;
			float dotNL;
			vec3 directLightColor_Diffuse;

			vIndirectFront += getAmbientLightIrradiance( ambientLightColor );

			#if defined( USE_LIGHT_PROBES )

				vIndirectFront += getLightProbeIrradiance( lightProbe, geometryNormal );

			#endif

			#ifdef DOUBLE_SIDED

				vIndirectBack += getAmbientLightIrradiance( ambientLightColor );

				#if defined( USE_LIGHT_PROBES )

					vIndirectBack += getLightProbeIrradiance( lightProbe, backGeometryNormal );

				#endif

			#endif

			#if NUM_POINT_LIGHTS > 0

				#pragma unroll_loop_start
				for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {

					getPointLightInfo( pointLights[ i ], geometryPosition, directLight );

					dotNL = dot( geometryNormal, directLight.direction );
					directLightColor_Diffuse = directLight.color;

					vLightFront += saturate( dotNL ) * directLightColor_Diffuse;

					#ifdef DOUBLE_SIDED

						vLightBack += saturate( - dotNL ) * directLightColor_Diffuse;

					#endif

				}
				#pragma unroll_loop_end

			#endif

			#if NUM_SPOT_LIGHTS > 0

				#pragma unroll_loop_start
				for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {

					getSpotLightInfo( spotLights[ i ], geometryPosition, directLight );

					dotNL = dot( geometryNormal, directLight.direction );
					directLightColor_Diffuse = directLight.color;

					vLightFront += saturate( dotNL ) * directLightColor_Diffuse;

					#ifdef DOUBLE_SIDED

						vLightBack += saturate( - dotNL ) * directLightColor_Diffuse;

					#endif
				}
				#pragma unroll_loop_end

			#endif

			#if NUM_DIR_LIGHTS > 0

				#pragma unroll_loop_start
				for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {

					getDirectionalLightInfo( directionalLights[ i ], directLight );

					dotNL = dot( geometryNormal, directLight.direction );
					directLightColor_Diffuse = directLight.color;

					vLightFront += saturate( dotNL ) * directLightColor_Diffuse;

					#ifdef DOUBLE_SIDED

						vLightBack += saturate( - dotNL ) * directLightColor_Diffuse;

					#endif

				}
				#pragma unroll_loop_end

			#endif

			#if NUM_HEMI_LIGHTS > 0

				#pragma unroll_loop_start
				for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {

					vIndirectFront += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );

					#ifdef DOUBLE_SIDED

						vIndirectBack += getHemisphereLightIrradiance( hemisphereLights[ i ], backGeometryNormal );

					#endif

				}
				#pragma unroll_loop_end

			#endif

			#include <shadowmap_vertex>
			#include <fog_vertex>

		}`;
	public static var fragmentShader:String = `

		#define GOURAUD

		uniform vec3 diffuse;
		uniform vec3 emissive;
		uniform float opacity;

		varying vec3 vLightFront;
		varying vec3 vIndirectFront;

		#ifdef DOUBLE_SIDED
			varying vec3 vLightBack;
			varying vec3 vIndirectBack;
		#endif

		#include <common>
		#include <packing>
		#include <dithering_pars_fragment>
		#include <color_pars_fragment>
		#include <uv_pars_fragment>
		#include <map_pars_fragment>
		#include <alphamap_pars_fragment>
		#include <alphatest_pars_fragment>
		#include <aomap_pars_fragment>
		#include <lightmap_pars_fragment>
		#include <emissivemap_pars_fragment>
		#include <envmap_common_pars_fragment>
		#include <envmap_pars_fragment>
		#include <bsdfs>
		#include <lights_pars_begin>
		#include <fog_pars_fragment>
		#include <shadowmap_pars_fragment>
		#include <shadowmask_pars_fragment>
		#include <specularmap_pars_fragment>
		#include <logdepthbuf_pars_fragment>
		#include <clipping_planes_pars_fragment>

		void main() {

			#include <clipping_planes_fragment>

			vec4 diffuseColor = vec4( diffuse, opacity );
			ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
			vec3 totalEmissiveRadiance = emissive;

			#include <logdepthbuf_fragment>
			#include <map_fragment>
			#include <color_fragment>
			#include <alphamap_fragment>
			#include <alphatest_fragment>
			#include <specularmap_fragment>
			#include <emissivemap_fragment>

			// accumulation

			#ifdef DOUBLE_SIDED

				reflectedLight.indirectDiffuse += ( gl_FrontFacing ) ? vIndirectFront : vIndirectBack;

			#else

				reflectedLight.indirectDiffuse += vIndirectFront;

			#endif

			#ifdef USE_LIGHTMAP

				vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
				vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
				reflectedLight.indirectDiffuse += lightMapIrradiance;

			#endif

			reflectedLight.indirectDiffuse *= BRDF_Lambert( diffuseColor.rgb );

			#ifdef DOUBLE_SIDED

				reflectedLight.directDiffuse = ( gl_FrontFacing ) ? vLightFront : vLightBack;

			#else

				reflectedLight.directDiffuse = vLightFront;

			#endif

			reflectedLight.directDiffuse *= BRDF_Lambert( diffuseColor.rgb ) * getShadowMask();

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

		}`
}

class MeshGouraudMaterial extends ShaderMaterial {
	public var isMeshGouraudMaterial:Bool = true;
	public var type:String = "MeshGouraudMaterial";
	public var map:Dynamic = null;
	public var lightMap:Dynamic = null;
	public var lightMapIntensity:Float = 1.0;
	public var aoMap:Dynamic = null;
	public var aoMapIntensity:Float = 1.0;
	public var emissive:Color = new Color(0x000000);
	public var emissiveIntensity:Float = 1.0;
	public var emissiveMap:Dynamic = null;
	public var specularMap:Dynamic = null;
	public var alphaMap:Dynamic = null;
	public var envMap:Dynamic = null;
	public var combine:MultiplyOperation = MultiplyOperation.multiply;
	public var reflectivity:Float = 1;
	public var refractionRatio:Float = 0.98;
	public var fog:Bool = false;
	public var lights:Bool = true;
	public var clipping:Bool = false;

	public function new(parameters:Dynamic) {
		super();
		this.defines = {
			__ : GouraudShader.defines
		};
		this.uniforms = UniformsUtils.clone(GouraudShader.uniforms);
		this.vertexShader = GouraudShader.vertexShader;
		this.fragmentShader = GouraudShader.fragmentShader;

		var exposePropertyNames = [
			'map', 'lightMap', 'lightMapIntensity', 'aoMap', 'aoMapIntensity',
			'emissive', 'emissiveIntensity', 'emissiveMap', 'specularMap', 'alphaMap',
			'envMap', 'reflectivity', 'refractionRatio', 'opacity', 'diffuse'
		];

		for (propertyName in exposePropertyNames) {
			this.__defineGetter__(propertyName, function() {
				return this.uniforms[propertyName].value;
			});
			this.__defineSetter__(propertyName, function(value) {
				this.uniforms[propertyName].value = value;
			});
		}

		this.__defineGetter__('color', function() {
			return this.uniforms['diffuse'].value;
		});

		this.__defineSetter__('color', function(value) {
			this.uniforms['diffuse'].value = value;
		});

		this.setValues(parameters);
	}

	public function copy(source:MeshGouraudMaterial):MeshGouraudMaterial {
		super.copy(source);
		this.color.copy(source.color);
		this.map = source.map;
		this.lightMap = source.lightMap;
		this.lightMapIntensity = source.lightMapIntensity;
		this.aoMap = source.aoMap;
		this.aoMapIntensity = source.aoMapIntensity;
		this.emissive.copy(source.emissive);
		this.emissiveMap = source.emissiveMap;
		this.emissiveIntensity = source.emissiveIntensity;
		this.specularMap = source.specularMap;
		this.alphaMap = source.alphaMap;
		this.envMap = source.envMap;
		this.combine = source.combine;
		this.reflectivity = source.reflectivity;
		this.refractionRatio = source.refractionRatio;
		this.wireframe = source.wireframe;
		this.wireframeLinewidth = source.wireframeLinewidth;
		this.wireframeLinecap = source.wireframeLinecap;
		this.wireframeLinejoin = source.wireframeLinejoin;
		this.fog = source.fog;
		return this;
	}
}