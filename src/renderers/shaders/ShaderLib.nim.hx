import ShaderChunk.ShaderChunk;
import UniformsUtils.mergeUniforms;
import Vector2.Vector2;
import Vector3.Vector3;
import UniformsLib.UniformsLib;
import Color.Color;
import Matrix3.Matrix3;

class ShaderLib {

	static var basic = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.specularmap,
			UniformsLib.envmap,
			UniformsLib.aomap,
			UniformsLib.lightmap,
			UniformsLib.fog
		]),

		vertexShader: ShaderChunk.meshbasic_vert,
		fragmentShader: ShaderChunk.meshbasic_frag

	};

	static var lambert = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.specularmap,
			UniformsLib.envmap,
			UniformsLib.aomap,
			UniformsLib.lightmap,
			UniformsLib.emissivemap,
			UniformsLib.bumpmap,
			UniformsLib.normalmap,
			UniformsLib.displacementmap,
			UniformsLib.fog,
			UniformsLib.lights,
			{
				emissive: new Color(0x000000)
			}
		]),

		vertexShader: ShaderChunk.meshlambert_vert,
		fragmentShader: ShaderChunk.meshlambert_frag

	};

	static var phong = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.specularmap,
			UniformsLib.envmap,
			UniformsLib.aomap,
			UniformsLib.lightmap,
			UniformsLib.emissivemap,
			UniformsLib.bumpmap,
			UniformsLib.normalmap,
			UniformsLib.displacementmap,
			UniformsLib.fog,
			UniformsLib.lights,
			{
				emissive: new Color(0x000000),
				specular: new Color(0x111111),
				shininess: 30
			}
		]),

		vertexShader: ShaderChunk.meshphong_vert,
		fragmentShader: ShaderChunk.meshphong_frag

	};

	static var standard = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.envmap,
			UniformsLib.aomap,
			UniformsLib.lightmap,
			UniformsLib.emissivemap,
			UniformsLib.bumpmap,
			UniformsLib.normalmap,
			UniformsLib.displacementmap,
			UniformsLib.roughnessmap,
			UniformsLib.metalnessmap,
			UniformsLib.fog,
			UniformsLib.lights,
			{
				emissive: new Color(0x000000),
				roughness: 1.0,
				metalness: 0.0,
				envMapIntensity: 1
			}
		]),

		vertexShader: ShaderChunk.meshphysical_vert,
		fragmentShader: ShaderChunk.meshphysical_frag

	};

	static var toon = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.aomap,
			UniformsLib.lightmap,
			UniformsLib.emissivemap,
			UniformsLib.bumpmap,
			UniformsLib.normalmap,
			UniformsLib.displacementmap,
			UniformsLib.gradientmap,
			UniformsLib.fog,
			UniformsLib.lights,
			{
				emissive: new Color(0x000000)
			}
		]),

		vertexShader: ShaderChunk.meshtoon_vert,
		fragmentShader: ShaderChunk.meshtoon_frag

	};

	static var matcap = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.bumpmap,
			UniformsLib.normalmap,
			UniformsLib.displacementmap,
			UniformsLib.fog,
			{
				matcap: null
			}
		]),

		vertexShader: ShaderChunk.meshmatcap_vert,
		fragmentShader: ShaderChunk.meshmatcap_frag

	};

	static var points = {

		uniforms: mergeUniforms([
			UniformsLib.points,
			UniformsLib.fog
		]),

		vertexShader: ShaderChunk.points_vert,
		fragmentShader: ShaderChunk.points_frag

	};

	static var dashed = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.fog,
			{
				scale: 1,
				dashSize: 1,
				totalSize: 2
			}
		]),

		vertexShader: ShaderChunk.linedashed_vert,
		fragmentShader: ShaderChunk.linedashed_frag

	};

	static var depth = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.displacementmap
		]),

		vertexShader: ShaderChunk.depth_vert,
		fragmentShader: ShaderChunk.depth_frag

	};

	static var normal = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.bumpmap,
			UniformsLib.normalmap,
			UniformsLib.displacementmap,
			{
				opacity: 1.0
			}
		]),

		vertexShader: ShaderChunk.meshnormal_vert,
		fragmentShader: ShaderChunk.meshnormal_frag

	};

	static var sprite = {

		uniforms: mergeUniforms([
			UniformsLib.sprite,
			UniformsLib.fog
		]),

		vertexShader: ShaderChunk.sprite_vert,
		fragmentShader: ShaderChunk.sprite_frag

	};

	static var background = {

		uniforms: {
			uvTransform: new Matrix3(),
			t2D: null,
			backgroundIntensity: 1
		},

		vertexShader: ShaderChunk.background_vert,
		fragmentShader: ShaderChunk.background_frag

	};

	static var backgroundCube = {

		uniforms: {
			envMap: null,
			flipEnvMap: -1,
			backgroundBlurriness: 0,
			backgroundIntensity: 1,
			backgroundRotation: new Matrix3()
		},

		vertexShader: ShaderChunk.backgroundCube_vert,
		fragmentShader: ShaderChunk.backgroundCube_frag

	};

	static var cube = {

		uniforms: {
			tCube: null,
			tFlip: -1,
			opacity: 1.0
		},

		vertexShader: ShaderChunk.cube_vert,
		fragmentShader: ShaderChunk.cube_frag

	};

	static var equirect = {

		uniforms: {
			tEquirect: null,
		},

		vertexShader: ShaderChunk.equirect_vert,
		fragmentShader: ShaderChunk.equirect_frag

	};

	static var distanceRGBA = {

		uniforms: mergeUniforms([
			UniformsLib.common,
			UniformsLib.displacementmap,
			{
				referencePosition: new Vector3(),
				nearDistance: 1,
				farDistance: 1000
			}
		]),

		vertexShader: ShaderChunk.distanceRGBA_vert,
		fragmentShader: ShaderChunk.distanceRGBA_frag

	};

	static var shadow = {

		uniforms: mergeUniforms([
			UniformsLib.lights,
			UniformsLib.fog,
			{
				color: new Color(0x00000),
				opacity: 1.0
			},
		]),

		vertexShader: ShaderChunk.shadow_vert,
		fragmentShader: ShaderChunk.shadow_frag

	};

	static var physical = {

		uniforms: mergeUniforms([
			ShaderLib.standard.uniforms,
			{
				clearcoat: 0,
				clearcoatMap: null,
				clearcoatMapTransform: new Matrix3(),
				clearcoatNormalMap: null,
				clearcoatNormalMapTransform: new Matrix3(),
				clearcoatNormalScale: new Vector2(1, 1),
				clearcoatRoughness: 0,
				clearcoatRoughnessMap: null,
				clearcoatRoughnessMapTransform: new Matrix3(),
				dispersion: 0,
				iridescence: 0,
				iridescenceMap: null,
				iridescenceMapTransform: new Matrix3(),
				iridescenceIOR: 1.3,
				iridescenceThicknessMinimum: 100,
				iridescenceThicknessMaximum: 400,
				iridescenceThicknessMap: null,
				iridescenceThicknessMapTransform: new Matrix3(),
				sheen: 0,
				sheenColor: new Color(0x000000),
				sheenColorMap: null,
				sheenColorMapTransform: new Matrix3(),
				sheenRoughness: 1,
				sheenRoughnessMap: null,
				sheenRoughnessMapTransform: new Matrix3(),
				transmission: 0,
				transmissionMap: null,
				transmissionMapTransform: new Matrix3(),
				transmissionSamplerSize: new Vector2(),
				transmissionSamplerMap: null,
				thickness: 0,
				thicknessMap: null,
				thicknessMapTransform: new Matrix3(),
				attenuationDistance: 0,
				attenuationColor: new Color(0x000000),
				specularColor: new Color(1, 1, 1),
				specularColorMap: null,
				specularColorMapTransform: new Matrix3(),
				specularIntensity: 1,
				specularIntensityMap: null,
				specularIntensityMapTransform: new Matrix3(),
				anisotropyVector: new Vector2(),
				anisotropyMap: null,
				anisotropyMapTransform: new Matrix3(),
			}
		]),

		vertexShader: ShaderChunk.meshphysical_vert,
		fragmentShader: ShaderChunk.meshphysical_frag

	};

}