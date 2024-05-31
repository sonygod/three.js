package three.examples.jsm.shaders;

import js.html.webgl.WebGLUniformLocation;
import three.js.UniformsUtils;
import three.js.ShaderLib;
import three.js.ShaderMaterial;
import three.js.UniformsLib;
import three.js.ShaderChunk;

class DOFMipMapShader {

    public static var name: String = 'DOFMipMapShader';

    public static var uniforms: js.Dynamic = {
        'tColor': { value: null },
        'tDepth': { value: null },
        'focus': { value: 1.0 },
        'maxblur': { value: 1.0 }
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
        "uniform float focus;\n" +
        "uniform float maxblur;\n" +
        "\n" +
        "uniform sampler2D tColor;\n" +
        "uniform sampler2D tDepth;\n" +
        "\n" +
        "varying vec2 vUv;\n" +
        "\n" +
        "void main() {\n" +
        "\n" +
        "	vec4 depth = texture2D( tDepth, vUv );\n" +
        "\n" +
        "	float factor = depth.x - focus;\n" +
        "\n" +
        "	vec4 col = texture2D( tColor, vUv, 2.0 * maxblur * abs( focus - depth.x ) );\n" +
        "\n" +
        "	gl_FragColor = col;\n" +
        "	gl_FragColor.a = 1.0;\n" +
        "\n" +
        "}";

    public static function getShader(): ShaderMaterial {
        var shader = new ShaderMaterial({
            uniforms: UniformsUtils.merge([
                UniformsLib['common'],
                UniformsLib['fog'],
                UniformsLib['lights'],
                uniforms
            ]),
            vertexShader: ShaderChunk['meshphysical_vert'] + '\n' + vertexShader,
            fragmentShader: fragmentShader,
            lights: true,
            fog: true
        });

        return shader;
    }

}