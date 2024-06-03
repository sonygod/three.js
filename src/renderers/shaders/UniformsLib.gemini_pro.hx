import Color from "../../math/Color";
import Vector2 from "../../math/Vector2";
import Matrix3 from "../../math/Matrix3";

/**
 * Uniforms library for shared webgl shaders
 */
class UniformsLib {

	static common: {
		diffuse: { value: Color },
		opacity: { value: Float },
		map: { value: Dynamic },
		mapTransform: { value: Matrix3 },
		alphaMap: { value: Dynamic },
		alphaMapTransform: { value: Matrix3 },
		alphaTest: { value: Float }
	} = {
		diffuse: { value: new Color(0xffffff) },
		opacity: { value: 1.0 },
		map: { value: null },
		mapTransform: { value: new Matrix3() },
		alphaMap: { value: null },
		alphaMapTransform: { value: new Matrix3() },
		alphaTest: { value: 0 }
	};

	static specularmap: {
		specularMap: { value: Dynamic },
		specularMapTransform: { value: Matrix3 }
	} = {
		specularMap: { value: null },
		specularMapTransform: { value: new Matrix3() }
	};

	static envmap: {
		envMap: { value: Dynamic },
		envMapRotation: { value: Matrix3 },
		flipEnvMap: { value: Float },
		reflectivity: { value: Float },
		ior: { value: Float },
		refractionRatio: { value: Float }
	} = {
		envMap: { value: null },
		envMapRotation: { value: new Matrix3() },
		flipEnvMap: { value: -1 },
		reflectivity: { value: 1.0 },
		ior: { value: 1.5 },
		refractionRatio: { value: 0.98 }
	};

	static aomap: {
		aoMap: { value: Dynamic },
		aoMapIntensity: { value: Float },
		aoMapTransform: { value: Matrix3 }
	} = {
		aoMap: { value: null },
		aoMapIntensity: { value: 1 },
		aoMapTransform: { value: new Matrix3() }
	};

	static lightmap: {
		lightMap: { value: Dynamic },
		lightMapIntensity: { value: Float },
		lightMapTransform: { value: Matrix3 }
	} = {
		lightMap: { value: null },
		lightMapIntensity: { value: 1 },
		lightMapTransform: { value: new Matrix3() }
	};

	static bumpmap: {
		bumpMap: { value: Dynamic },
		bumpMapTransform: { value: Matrix3 },
		bumpScale: { value: Float }
	} = {
		bumpMap: { value: null },
		bumpMapTransform: { value: new Matrix3() },
		bumpScale: { value: 1 }
	};

	static normalmap: {
		normalMap: { value: Dynamic },
		normalMapTransform: { value: Matrix3 },
		normalScale: { value: Vector2 }
	} = {
		normalMap: { value: null },
		normalMapTransform: { value: new Matrix3() },
		normalScale: { value: new Vector2(1, 1) }
	};

	static displacementmap: {
		displacementMap: { value: Dynamic },
		displacementMapTransform: { value: Matrix3 },
		displacementScale: { value: Float },
		displacementBias: { value: Float }
	} = {
		displacementMap: { value: null },
		displacementMapTransform: { value: new Matrix3() },
		displacementScale: { value: 1 },
		displacementBias: { value: 0 }
	};

	static emissivemap: {
		emissiveMap: { value: Dynamic },
		emissiveMapTransform: { value: Matrix3 }
	} = {
		emissiveMap: { value: null },
		emissiveMapTransform: { value: new Matrix3() }
	};

	static metalnessmap: {
		metalnessMap: { value: Dynamic },
		metalnessMapTransform: { value: Matrix3 }
	} = {
		metalnessMap: { value: null },
		metalnessMapTransform: { value: new Matrix3() }
	};

	static roughnessmap: {
		roughnessMap: { value: Dynamic },
		roughnessMapTransform: { value: Matrix3 }
	} = {
		roughnessMap: { value: null },
		roughnessMapTransform: { value: new Matrix3() }
	};

	static gradientmap: {
		gradientMap: { value: Dynamic }
	} = {
		gradientMap: { value: null }
	};

	static fog: {
		fogDensity: { value: Float },
		fogNear: { value: Float },
		fogFar: { value: Float },
		fogColor: { value: Color }
	} = {
		fogDensity: { value: 0.00025 },
		fogNear: { value: 1 },
		fogFar: { value: 2000 },
		fogColor: { value: new Color(0xffffff) }
	};

	static lights: {
		ambientLightColor: { value: Array<Color> },
		lightProbe: { value: Array<Float> },
		directionalLights: { value: Array<{ direction: Vector3, color: Color }>, properties: { direction: { value: Vector3 }, color: { value: Color } } },
		directionalLightShadows: { value: Array<{ shadowBias: Float, shadowNormalBias: Float, shadowRadius: Float, shadowMapSize: Int }>, properties: { shadowBias: { value: Float }, shadowNormalBias: { value: Float }, shadowRadius: { value: Float }, shadowMapSize: { value: Int } } },
		directionalShadowMap: { value: Array<Dynamic> },
		directionalShadowMatrix: { value: Array<Matrix4> },
		spotLights: { value: Array<{ color: Color, position: Vector3, direction: Vector3, distance: Float, coneCos: Float, penumbraCos: Float, decay: Float }>, properties: { color: { value: Color }, position: { value: Vector3 }, direction: { value: Vector3 }, distance: { value: Float }, coneCos: { value: Float }, penumbraCos: { value: Float }, decay: { value: Float } } },
		spotLightShadows: { value: Array<{ shadowBias: Float, shadowNormalBias: Float, shadowRadius: Float, shadowMapSize: Int }>, properties: { shadowBias: { value: Float }, shadowNormalBias: { value: Float }, shadowRadius: { value: Float }, shadowMapSize: { value: Int } } },
		spotLightMap: { value: Array<Dynamic> },
		spotShadowMap: { value: Array<Dynamic> },
		spotLightMatrix: { value: Array<Matrix4> },
		pointLights: { value: Array<{ color: Color, position: Vector3, decay: Float, distance: Float }>, properties: { color: { value: Color }, position: { value: Vector3 }, decay: { value: Float }, distance: { value: Float } } },
		pointLightShadows: { value: Array<{ shadowBias: Float, shadowNormalBias: Float, shadowRadius: Float, shadowMapSize: Int, shadowCameraNear: Float, shadowCameraFar: Float }>, properties: { shadowBias: { value: Float }, shadowNormalBias: { value: Float }, shadowRadius: { value: Float }, shadowMapSize: { value: Int }, shadowCameraNear: { value: Float }, shadowCameraFar: { value: Float } } },
		pointShadowMap: { value: Array<Dynamic> },
		pointShadowMatrix: { value: Array<Matrix4> },
		hemisphereLights: { value: Array<{ direction: Vector3, skyColor: Color, groundColor: Color }>, properties: { direction: { value: Vector3 }, skyColor: { value: Color }, groundColor: { value: Color } } },
		rectAreaLights: { value: Array<{ color: Color, position: Vector3, width: Float, height: Float }>, properties: { color: { value: Color }, position: { value: Vector3 }, width: { value: Float }, height: { value: Float } } },
		ltc_1: { value: Dynamic },
		ltc_2: { value: Dynamic }
	} = {
		ambientLightColor: { value: [] },
		lightProbe: { value: [] },
		directionalLights: { value: [], properties: {
			direction: { value: new Vector3() },
			color: { value: new Color() }
		} },
		directionalLightShadows: { value: [], properties: {
			shadowBias: { value: 0 },
			shadowNormalBias: { value: 0 },
			shadowRadius: { value: 0 },
			shadowMapSize: { value: 0 }
		} },
		directionalShadowMap: { value: [] },
		directionalShadowMatrix: { value: [] },
		spotLights: { value: [], properties: {
			color: { value: new Color() },
			position: { value: new Vector3() },
			direction: { value: new Vector3() },
			distance: { value: 0 },
			coneCos: { value: 0 },
			penumbraCos: { value: 0 },
			decay: { value: 0 }
		} },
		spotLightShadows: { value: [], properties: {
			shadowBias: { value: 0 },
			shadowNormalBias: { value: 0 },
			shadowRadius: { value: 0 },
			shadowMapSize: { value: 0 }
		} },
		spotLightMap: { value: [] },
		spotShadowMap: { value: [] },
		spotLightMatrix: { value: [] },
		pointLights: { value: [], properties: {
			color: { value: new Color() },
			position: { value: new Vector3() },
			decay: { value: 0 },
			distance: { value: 0 }
		} },
		pointLightShadows: { value: [], properties: {
			shadowBias: { value: 0 },
			shadowNormalBias: { value: 0 },
			shadowRadius: { value: 0 },
			shadowMapSize: { value: 0 },
			shadowCameraNear: { value: 0 },
			shadowCameraFar: { value: 0 }
		} },
		pointShadowMap: { value: [] },
		pointShadowMatrix: { value: [] },
		hemisphereLights: { value: [], properties: {
			direction: { value: new Vector3() },
			skyColor: { value: new Color() },
			groundColor: { value: new Color() }
		} },
		rectAreaLights: { value: [], properties: {
			color: { value: new Color() },
			position: { value: new Vector3() },
			width: { value: 0 },
			height: { value: 0 }
		} },
		ltc_1: { value: null },
		ltc_2: { value: null }
	};

	static points: {
		diffuse: { value: Color },
		opacity: { value: Float },
		size: { value: Float },
		scale: { value: Float },
		map: { value: Dynamic },
		alphaMap: { value: Dynamic },
		alphaMapTransform: { value: Matrix3 },
		alphaTest: { value: Float },
		uvTransform: { value: Matrix3 }
	} = {
		diffuse: { value: new Color(0xffffff) },
		opacity: { value: 1.0 },
		size: { value: 1.0 },
		scale: { value: 1.0 },
		map: { value: null },
		alphaMap: { value: null },
		alphaMapTransform: { value: new Matrix3() },
		alphaTest: { value: 0 },
		uvTransform: { value: new Matrix3() }
	};

	static sprite: {
		diffuse: { value: Color },
		opacity: { value: Float },
		center: { value: Vector2 },
		rotation: { value: Float },
		map: { value: Dynamic },
		mapTransform: { value: Matrix3 },
		alphaMap: { value: Dynamic },
		alphaMapTransform: { value: Matrix3 },
		alphaTest: { value: Float }
	} = {
		diffuse: { value: new Color(0xffffff) },
		opacity: { value: 1.0 },
		center: { value: new Vector2(0.5, 0.5) },
		rotation: { value: 0.0 },
		map: { value: null },
		mapTransform: { value: new Matrix3() },
		alphaMap: { value: null },
		alphaMapTransform: { value: new Matrix3() },
		alphaTest: { value: 0 }
	};

}

export default UniformsLib;