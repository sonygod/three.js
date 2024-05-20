import three.math.Color;
import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.renderers.shaders.UniformsLib;

class UniformsCache {

	var lights = {};

	public function new() {}

	public function get(light:Dynamic):Dynamic {

		if (lights[light.id] !== undefined) {

			return lights[light.id];

		}

		var uniforms;

		switch (light.type) {

			case 'DirectionalLight':
				uniforms = {
					direction: new Vector3(),
					color: new Color()
				};
				break;

			case 'SpotLight':
				uniforms = {
					position: new Vector3(),
					direction: new Vector3(),
					color: new Color(),
					distance: 0,
					coneCos: 0,
					penumbraCos: 0,
					decay: 0
				};
				break;

			case 'PointLight':
				uniforms = {
					position: new Vector3(),
					color: new Color(),
					distance: 0,
					decay: 0
				};
				break;

			case 'HemisphereLight':
				uniforms = {
					direction: new Vector3(),
					skyColor: new Color(),
					groundColor: new Color()
				};
				break;

			case 'RectAreaLight':
				uniforms = {
					color: new Color(),
					position: new Vector3(),
					halfWidth: new Vector3(),
					halfHeight: new Vector3()
				};
				break;

		}

		lights[light.id] = uniforms;

		return uniforms;

	}

}

class ShadowUniformsCache {

	var lights = {};

	public function new() {}

	public function get(light:Dynamic):Dynamic {

		if (lights[light.id] !== undefined) {

			return lights[light.id];

		}

		var uniforms;

		switch (light.type) {

			case 'DirectionalLight':
				uniforms = {
					shadowBias: 0,
					shadowNormalBias: 0,
					shadowRadius: 1,
					shadowMapSize: new Vector2()
				};
				break;

			case 'SpotLight':
				uniforms = {
					shadowBias: 0,
					shadowNormalBias: 0,
					shadowRadius: 1,
					shadowMapSize: new Vector2()
				};
				break;

			case 'PointLight':
				uniforms = {
					shadowBias: 0,
					shadowNormalBias: 0,
					shadowRadius: 1,
					shadowMapSize: new Vector2(),
					shadowCameraNear: 1,
					shadowCameraFar: 1000
				};
				break;

			// TODO (abelnation): set RectAreaLight shadow uniforms

		}

		lights[light.id] = uniforms;

		return uniforms;

	}

}

static var nextVersion = 0;

static function shadowCastingAndTexturingLightsFirst(lightA:Dynamic, lightB:Dynamic):Int {

	return (lightB.castShadow ? 2 : 0) - (lightA.castShadow ? 2 : 0) + (lightB.map ? 1 : 0) - (lightA.map ? 1 : 0);

}

class WebGLLights {

	var cache = new UniformsCache();

	var shadowCache = new ShadowUniformsCache();

	var state = {

		version: 0,

		hash: {
			directionalLength: -1,
			pointLength: -1,
			spotLength: -1,
			rectAreaLength: -1,
			hemiLength: -1,

			numDirectionalShadows: -1,
			numPointShadows: -1,
			numSpotShadows: -1,
			numSpotMaps: -1,

			numLightProbes: -1
		},

		ambient: [0, 0, 0],
		probe: [],
		directional: [],
		directionalShadow: [],
		directionalShadowMap: [],
		directionalShadowMatrix: [],
		spot: [],
		spotLightMap: [],
		spotShadow: [],
		spotShadowMap: [],
		spotLightMatrix: [],
		rectArea: [],
		rectAreaLTC1: null,
		rectAreaLTC2: null,
		point: [],
		pointShadow: [],
		pointShadowMap: [],
		pointShadowMatrix: [],
		hemi: [],
		numSpotLightShadowsWithMaps: 0,
		numLightProbes: 0

	};

	public function new(extensions:Dynamic) {

		for (i in 0...9) state.probe.push(new Vector3());

	}

	public function setup(lights:Array<Dynamic>, useLegacyLights:Bool):Void {

		// ... 省略 setup 函数的实现 ...

	}

	public function setupView(lights:Array<Dynamic>, camera:Dynamic):Void {

		// ... 省略 setupView 函数的实现 ...

	}

}