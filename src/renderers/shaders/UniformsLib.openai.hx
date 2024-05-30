package three.js.src.renderers.shaders;

import three.math.Color;
import three.math.Vector2;
import three.math.Matrix3;

class UniformsLib {
    public static var common = {
        diffuse: { value: new Color(0xffffff) },
        opacity: { value: 1.0 },

        map: { value: null },
        mapTransform: { value: new Matrix3() },

        alphaMap: { value: null },
        alphaMapTransform: { value: new Matrix3() },

        alphaTest: { value: 0 }
    };

    public static var specularmap = {
        specularMap: { value: null },
        specularMapTransform: { value: new Matrix3() }
    };

    public static var envmap = {
        envMap: { value: null },
        envMapRotation: { value: new Matrix3() },
        flipEnvMap: { value: -1 },
        reflectivity: { value: 1.0 }, // basic, lambert, phong
        ior: { value: 1.5 }, // physical
        refractionRatio: { value: 0.98 }, // basic, lambert, phong
    };

    public static var aomap = {
        aoMap: { value: null },
        aoMapIntensity: { value: 1 },
        aoMapTransform: { value: new Matrix3() }
    };

    public static var lightmap = {
        lightMap: { value: null },
        lightMapIntensity: { value: 1 },
        lightMapTransform: { value: new Matrix3() }
    };

    public static var bumpmap = {
        bumpMap: { value: null },
        bumpMapTransform: { value: new Matrix3() },
        bumpScale: { value: 1 }
    };

    public static var normalmap = {
        normalMap: { value: null },
        normalMapTransform: { value: new Matrix3() },
        normalScale: { value: new Vector2(1, 1) }
    };

    public static var displacementmap = {
        displacementMap: { value: null },
        displacementMapTransform: { value: new Matrix3() },
        displacementScale: { value: 1 },
        displacementBias: { value: 0 }
    };

    public static var emissivemap = {
        emissiveMap: { value: null },
        emissiveMapTransform: { value: new Matrix3() }
    };

    public static var metalnessmap = {
        metalnessMap: { value: null },
        metalnessMapTransform: { value: new Matrix3() }
    };

    public static var roughnessmap = {
        roughnessMap: { value: null },
        roughnessMapTransform: { value: new Matrix3() }
    };

    public static var gradientmap = {
        gradientMap: { value: null }
    };

    public static var fog = {
        fogDensity: { value: 0.00025 },
        fogNear: { value: 1 },
        fogFar: { value: 2000 },
        fogColor: { value: new Color(0xffffff) }
    };

    public static var lights = {
        ambientLightColor: { value: [] },

        lightProbe: { value: [] },

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

        directionalShadowMap: { value: [] },
        directionalShadowMatrix: { value: [] },

        spotLights: { value: [], properties: {
            color: {},
            position: {},
            direction: {},
            distance: {},
            coneCos: {},
            penumbraCos: {},
            decay: {}
        }},

        spotLightShadows: { value: [], properties: {
            shadowBias: {},
            shadowNormalBias: {},
            shadowRadius: {},
            shadowMapSize: {}
        } },

        spotLightMap: { value: [] },
        spotShadowMap: { value: [] },
        spotLightMatrix: { value: [] },

        pointLights: { value: [], properties: {
            color: {},
            position: {},
            decay: {},
            distance: {}
        }},

        pointLightShadows: { value: [], properties: {
            shadowBias: {},
            shadowNormalBias: {},
            shadowRadius: {},
            shadowMapSize: {},
            shadowCameraNear: {},
            shadowCameraFar: {}
        } },

        pointShadowMap: { value: [] },
        pointShadowMatrix: { value: [] },

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

        ltc_1: { value: null },
        ltc_2: { value: null }
    };

    public static var points = {
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

    public static var sprite = {
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