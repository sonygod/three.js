package three.js.src.renderers.shaders;

import haxe.ds.StringMap;
import Math.Vector2;
import Math.Vector3;
import Math.Matrix3;
import Math.Color;

class ShaderLib {
    public static var basic:Shader = {
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

    public static var lambert:Shader = {
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
                emissive: { value: new Color(0x000000) }
            }
        ]),
        vertexShader: ShaderChunk.meshlambert_vert,
        fragmentShader: ShaderChunk.meshlambert_frag
    };

    public static var phong:Shader = {
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
                emissive: { value: new Color(0x000000) },
                specular: { value: new Color(0x111111) },
                shininess: { value: 30 }
            }
        ]),
        vertexShader: ShaderChunk.meshphong_vert,
        fragmentShader: ShaderChunk.meshphong_frag
    };

    public static var standard:Shader = {
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
                emissive: { value: new Color(0x000000) },
                roughness: { value: 1.0 },
                metalness: { value: 0.0 },
                envMapIntensity: { value: 1 }
            }
        ]),
        vertexShader: ShaderChunk.meshphysical_vert,
        fragmentShader: ShaderChunk.meshphysical_frag
    };

    public static var toon:Shader = {
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
                emissive: { value: new Color(0x000000) }
            }
        ]),
        vertexShader: ShaderChunk.meshtoon_vert,
        fragmentShader: ShaderChunk.meshtoon_frag
    };

    public static var matcap:Shader = {
        uniforms: mergeUniforms([
            UniformsLib.common,
            UniformsLib.bumpmap,
            UniformsLib.normalmap,
            UniformsLib.displacementmap,
            UniformsLib.fog,
            {
                matcap: { value: null }
            }
        ]),
        vertexShader: ShaderChunk.meshmatcap_vert,
        fragmentShader: ShaderChunk.meshmatcap_frag
    };

    public static var points:Shader = {
        uniforms: mergeUniforms([
            UniformsLib.points,
            UniformsLib.fog
        ]),
        vertexShader: ShaderChunk.points_vert,
        fragmentShader: ShaderChunk.points_frag
    };

    public static var dashed:Shader = {
        uniforms: mergeUniforms([
            UniformsLib.common,
            UniformsLib.fog,
            {
                scale: { value: 1 },
                dashSize: { value: 1 },
                totalSize: { value: 2 }
            }
        ]),
        vertexShader: ShaderChunk.linedashed_vert,
        fragmentShader: ShaderChunk.linedashed_frag
    };

    public static var depth:Shader = {
        uniforms: mergeUniforms([
            UniformsLib.common,
            UniformsLib.displacementmap
        ]),
        vertexShader: ShaderChunk.depth_vert,
        fragmentShader: ShaderChunk.depth_frag
    };

    public static var normal:Shader = {
        uniforms: mergeUniforms([
            UniformsLib.common,
            UniformsLib.bumpmap,
            UniformsLib.normalmap,
            UniformsLib.displacementmap,
            {
                opacity: { value: 1.0 }
            }
        ]),
        vertexShader: ShaderChunk.meshnormal_vert,
        fragmentShader: ShaderChunk.meshnormal_frag
    };

    public static var sprite:Shader = {
        uniforms: mergeUniforms([
            UniformsLib.sprite,
            UniformsLib.fog
        ]),
        vertexShader: ShaderChunk.sprite_vert,
        fragmentShader: ShaderChunk.sprite_frag
    };

    public static var background:Shader = {
        uniforms: {
            uvTransform: { value: new Matrix3() },
            t2D: { value: null },
            backgroundIntensity: { value: 1 }
        },
        vertexShader: ShaderChunk.background_vert,
        fragmentShader: ShaderChunk.background_frag
    };

    public static var backgroundCube:Shader = {
        uniforms: {
            envMap: { value: null },
            flipEnvMap: { value: -1 },
            backgroundBlurriness: { value: 0 },
            backgroundIntensity: { value: 1 },
            backgroundRotation: { value: new Matrix3() }
        },
        vertexShader: ShaderChunk.backgroundCube_vert,
        fragmentShader: ShaderChunk.backgroundCube_frag
    };

    public static var cube:Shader = {
        uniforms: {
            tCube: { value: null },
            tFlip: { value: -1 },
            opacity: { value: 1.0 }
        },
        vertexShader: ShaderChunk.cube_vert,
        fragmentShader: ShaderChunk.cube_frag
    };

    public static var equirect:Shader = {
        uniforms: {
            tEquirect: { value: null }
        },
        vertexShader: ShaderChunk.equirect_vert,
        fragmentShader: ShaderChunk.equirect_frag
    };

    public static var distanceRGBA:Shader = {
        uniforms: mergeUniforms([
            UniformsLib.common,
            UniformsLib.displacementmap,
            {
                referencePosition: { value: new Vector3() },
                nearDistance: { value: 1 },
                farDistance: { value: 1000 }
            }
        ]),
        vertexShader: ShaderChunk.distanceRGBA_vert,
        fragmentShader: ShaderChunk.distanceRGBA_frag
    };

    public static var shadow:Shader = {
        uniforms: mergeUniforms([
            UniformsLib.lights,
            UniformsLib.fog,
            {
                color: { value: new Color(0x00000) },
                opacity: { value: 1.0 }
            }
        ]),
        vertexShader: ShaderChunk.shadow_vert,
        fragmentShader: ShaderChunk.shadow_frag
    };

    public static var physical:Shader = {
        uniforms: mergeUniforms([
            standard.uniforms,
            {
                clearcoat: { value: 0 },
                clearcoatMap: { value: null },
                clearcoatMapTransform: { value: new Matrix3() },
                clearcoatNormalMap: { value: null },
                clearcoatNormalMapTransform: { value: new Matrix3() },
                clearcoatNormalScale: { value: new Vector2(1, 1) },
                clearcoatRoughness: { value: 0 },
                clearcoatRoughnessMap: { value: null },
                clearcoatRoughnessMapTransform: { value: new Matrix3() },
                dispersion: { value: 0 },
                iridescence: { value: 0 },
                iridescenceMap: { value: null },
                iridescenceMapTransform: { value: new Matrix3() },
                iridescenceIOR: { value: 1.3 },
                iridescenceThicknessMinimum: { value: 100 },
                iridescenceThicknessMaximum: { value: 400 },
                iridescenceThicknessMap: { value: null },
                iridescenceThicknessMapTransform: { value: new Matrix3() },
                sheen: { value: 0 },
                sheenColor: { value: new Color(0x000000) },
                sheenColorMap: { value: null },
                sheenColorMapTransform: { value: new Matrix3() },
                sheenRoughness: { value: 1 },
                sheenRoughnessMap: { value: null },
                sheenRoughnessMapTransform: { value: new Matrix3() },
                transmission: { value: 0 },
                transmissionMap: { value: null },
                transmissionMapTransform: { value: new Matrix3() },
                transmissionSamplerSize: { value: new Vector2() },
                transmissionSamplerMap: { value: null },
                thickness: { value: 0 },
                thicknessMap: { value: null },
                thicknessMapTransform: { value: new Matrix3() },
                attenuationDistance: { value: 0 },
                attenuationColor: { value: new Color(0x000000) },
                specularColor: { value: new Color(1, 1, 1) },
                specularColorMap: { value: null },
                specularColorMapTransform: { value: new Matrix3() },
                specularIntensity: { value: 1 },
                specularIntensityMap: { value: null },
                specularIntensityMapTransform: { value: new Matrix3() },
                anisotropyVector: { value: new Vector2() },
                anisotropyMap: { value: null },
                anisotropyMapTransform: { value: new Matrix3() },
            }
        ]),
        vertexShader: ShaderChunk.meshphysical_vert,
        fragmentShader: ShaderChunk.meshphysical_frag
    };
}