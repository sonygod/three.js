package three.examples.jsm.shaders;

import js.lib.three.UniformsUtils;
import js.lib.three.ShaderLib;
import js.lib.three.ShaderMaterial;
import js.lib.three.Vector2;
import js.lib.three.Texture;

class BlendShader {

    public static var name:String = 'BlendShader';

    public static var uniforms:Dynamic = UniformsUtils.merge([
        ShaderLib.basic.uniforms,
        {
            tDiffuse1: { value: null },
            tDiffuse2: { value: null },
            mixRatio: { value: 0.5 },
            opacity: { value: 1.0 }
        }
    ]);

    public static var vertexShader:String = [
        "varying vec2 vUv;",
        "",
        "void main() {",
        "   vUv = uv;",
        "   gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );",
        "}"
    ].join("\n");

    public static var fragmentShader:String = [
        "uniform float opacity;",
        "uniform float mixRatio;",
        "",
        "uniform sampler2D tDiffuse1;",
        "uniform sampler2D tDiffuse2;",
        "",
        "varying vec2 vUv;",
        "",
        "void main() {",
        "   vec4 texel1 = texture2D( tDiffuse1, vUv );",
        "   vec4 texel2 = texture2D( tDiffuse2, vUv );",
        "   gl_FragColor = opacity * mix( texel1, texel2, mixRatio );",
        "}"
    ].join("\n");

    public static function create(diffuse1:Texture, diffuse2:Texture):ShaderMaterial {
        var material = new ShaderMaterial({
            uniforms: uniforms,
            vertexShader: vertexShader,
            fragmentShader: fragmentShader
        });

        material.uniforms.tDiffuse1.value = diffuse1;
        material.uniforms.tDiffuse2.value = diffuse2;

        return material;
    }
}