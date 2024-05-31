package three.examples.jsm.shaders;

import js.html.WebGLUniformLocation;
import three.UniformsLib;
import three.UniformsUtils;
import three.WebGLProgram;
import three.WebGLShader;

class VignetteShader {

    public static var name: String = 'VignetteShader';

    public static var uniforms: js.Dynamic = {
        'tDiffuse': { value: null },
        'offset': { value: 1.0 },
        'darkness': { value: 1.0 }
    };

    public static var vertexShader: String =
        "varying vec2 vUv;\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	vUv = uv;\n" +
        "	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
        "\n" +
        "}";

    public static var fragmentShader: String =
        "uniform float offset;\n" +
        "uniform float darkness;\n" +
        "\n" +
        "uniform sampler2D tDiffuse;\n" +
        "\n" +
        "varying vec2 vUv;\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	// Eskil's vignette\n" +
        "\n" +
        "	vec4 texel = texture2D( tDiffuse, vUv );\n" +
        "	vec2 uv = ( vUv - vec2( 0.5 ) ) * vec2( offset );\n" +
        "	gl_FragColor = vec4( mix( texel.rgb, vec3( 1.0 - darkness ), dot( uv, uv ) ), texel.a );\n" +
        "\n" +
        "}";

    public static function build(renderer: three.WebGLRenderer, inputBuffer: three.WebGLRenderTarget, outputBuffer: three.WebGLRenderTarget, clearColor: three.Color, clearAlpha: Bool): three.WebGLShader {
        var material = new three.ShaderMaterial({
            uniforms: UniformsUtils.clone(uniforms),
            vertexShader: vertexShader,
            fragmentShader: fragmentShader
        });

        var program = new three.WebGLProgram(renderer.context, material.vertexShader, material.fragmentShader, material.uniforms);

        var shader = new three.WebGLShader(renderer, program, material);

        shader.uniforms['tDiffuse'].value = inputBuffer.texture;
        shader.uniforms['offset'].value = 1.0;
        shader.uniforms['darkness'].value = 1.0;

        return shader;
    }
}