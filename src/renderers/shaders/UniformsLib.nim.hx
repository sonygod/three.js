import Color.{fromInt, fromFloat}
import Matrix3.{fromFloat, fromInt}
import Vector2.{fromFloat, fromInt}

class UniformsLib {

	public static var common(get, set) : Dynamic;
	static {
		common = {
			diffuse: fromInt(0xffffff),
			opacity: 1.0,
			map: null,
			mapTransform: fromInt(0),
			alphaMap: null,
			alphaMapTransform: fromInt(0),
			alphaTest: 0
		};
	}

	public static var specularmap(get, set) : Dynamic;
	static {
		specularmap = {
			specularMap: null,
			specularMapTransform: fromInt(0)
		};
	}

	public static var envmap(get, set) : Dynamic;
	static {
		envmap = {
			envMap: null,
			envMapRotation: fromInt(0),
			flipEnvMap: -1,
			reflectivity: 1.0,
			ior: 1.5,
			refractionRatio: 0.98
		};
	}

	public static var aomap(get, set) : Dynamic;
	static {
		aomap = {
			aoMap: null,
			aoMapIntensity: 1,
			aoMapTransform: fromInt(0)
		};
	}

	public static var lightmap(get, set) : Dynamic;
	static {
		lightmap = {
			lightMap: null,
			lightMapIntensity: 1,
			lightMapTransform: fromInt(0)
		};
	}

	public static var bumpmap(get, set) : Dynamic;
	static {
		bumpmap = {
			bumpMap: null,
			bumpMapTransform: fromInt(0),
			bumpScale: 1
		};
	}

	public static var normalmap(get, set) : Dynamic;
	static {
		normalmap = {
			normalMap: null,
			normalMapTransform: fromInt(0),
			normalScale: fromFloat([1, 1])
		};
	}

	public static var displacementmap(get, set) : Dynamic;
	static {
		displacementmap = {
			displacementMap: null,
			displacementMapTransform: fromInt(0),
			displacementScale: 1,
			displacementBias: 0
		};
	}

	public static var emissivemap(get, set) : Dynamic;
	static {
		emissivemap = {
			emissiveMap: null,
			emissiveMapTransform: fromInt(0)
		};
	}

	public static var metalnessmap(get, set) : Dynamic;
	static {
		metalnessmap = {
			metalnessMap: null,
			metalnessMapTransform: fromInt(0)
		};
	}

	public static var roughnessmap(get, set) : Dynamic;
	static {
		roughnessmap = {
			roughnessMap: null,
			roughnessMapTransform: fromInt(0)
		};
	}

	public static var gradientmap(get, set) : Dynamic;
	static {
		gradientmap = {
			gradientMap: null
		};
	}

	public static var fog(get, set) : Dynamic;
	static {
		fog = {
			fogDensity: 0.00025,
			fogNear: 1,
			fogFar: 2000,
			fogColor: fromInt(0xffffff)
		};
	}

	public static var lights(get, set) : Dynamic;
	static {
		lights = {
			ambientLightColor: [],
			lightProbe: [],
			directionalLights: { value: [], properties: {
				direction: {},
				color: {}
			} },
			directionalLightShadows: { value: [], properties: {
				shadowBias: {},
				shadowNormalBias: {},
				shadowRadius: {},
				shadowMapSize: {}
			} },
			directionalShadowMap: [],
			directionalShadowMatrix: [],
			spotLights: { value: [], properties: {
				color: {},
				position: {},
				direction: {},
				distance: {},
				coneCos: {},
				penumbraCos: {},
				decay: {}
			} },
			spotLightShadows: { value: [], properties: {
				shadowBias: {},
				shadowNormalBias: {},
				shadowRadius: {},
				shadowMapSize: {}
			} },
			spotLightMap: [],
			spotShadowMap: [],
			spotLightMatrix: [],
			pointLights: { value: [], properties: {
				color: {},
				position: {},
				decay: {},
				distance: {}
			} },
			pointLightShadows: { value: [], properties: {
				shadowBias: {},
				shadowNormalBias: {},
				shadowRadius: {},
				shadowMapSize: {},
				shadowCameraNear: {},
				shadowCameraFar: {}
			} },
			pointShadowMap: [],
			pointShadowMatrix: [],
			hemisphereLights: { value: [], properties: {
				direction: {},
				skyColor: {},
				groundColor: {}
			} },
			rectAreaLights: { value: [], properties: {
				color: {},
				position: {},
				width: {},
				height: {}
			} },
			ltc_1: null,
			ltc_2: null
		};
	}

	public static var points(get, set) : Dynamic;
	static {
		points = {
			diffuse: fromInt(0xffffff),
			opacity: 1.0,
			size: 1.0,
			scale: 1.0,
			map: null,
			alphaMap: null,
			alphaMapTransform: fromInt(0),
			alphaTest: 0,
			uvTransform: fromInt(0)
		};
	}

	public static var sprite(get, set) : Dynamic;
	static {
		sprite = {
			diffuse: fromInt(0xffffff),
			opacity: 1.0,
			center: fromFloat([0.5, 0.5]),
			rotation: 0.0,
			map: null,
			mapTransform: fromInt(0),
			alphaMap: null,
			alphaMapTransform: fromInt(0),
			alphaTest: 0
		};
	}

}