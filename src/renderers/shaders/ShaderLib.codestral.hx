import three.math.Vector2;
import three.math.Vector3;
import three.math.Color;
import three.math.Matrix3;
import three.renderers.shaders.ShaderChunk;
import three.renderers.shaders.UniformsUtils;
import three.renderers.shaders.UniformsLib;

class ShaderLib {
    public static var basic:Dynamic = {
        uniforms: UniformsUtils.mergeUniforms([
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

    public static var lambert:Dynamic = {
        uniforms: UniformsUtils.mergeUniforms([
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

    // the rest of the code...

    public static var physical:Dynamic = {
        uniforms: UniformsUtils.mergeUniforms([
            ShaderLib.standard.uniforms,
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
                anisotropyMapTransform: { value: new Matrix3() }
            }
        ]),
        vertexShader: ShaderChunk.meshphysical_vert,
        fragmentShader: ShaderChunk.meshphysical_frag
    };
}