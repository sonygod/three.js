package three.examples.shaders;

import js.html.webgl.WebGLUniformLocation;
import three.js.UniformsUtils;
import three.js.ShaderLib;
import three.js.ShaderMaterial;
import three.js.UniformsLib;
import three.js.ShaderChunk;

class KaleidoShader {

    public static var name: String = 'KaleidoShader';

    public static var uniforms: Dynamic = {
        'tDiffuse': { value: null },
        'sides': { value: 6.0 },
        'angle': { value: 0.0 }
    };

    public static var vertexShader: String =
        'varying vec2 vUv;\n' +
        'void main() {\n' +
        '	vUv = uv;\n' +
        '	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n' +
        '}';

    public static var fragmentShader: String =
        'uniform sampler2D tDiffuse;\n' +
        'uniform float sides;\n' +
        'uniform float angle;\n' +
        'varying vec2 vUv;\n' +
        'void main() {\n' +
        '	vec2 p = vUv - 0.5;\n' +
        '	float r = length(p);\n' +
        '	float a = atan(p.y, p.x) + angle;\n' +
        '	float tau = 2. * 3.1416 ;\n' +
        '	a = mod(a, tau/sides);\n' +
        '	a = abs(a - tau/sides/2.);\n' +
        '	p = r * vec2(cos(a), sin(a));\n' +
        '	vec4 color = texture2D(tDiffuse, p + 0.5);\n' +
        '	gl_FragColor = color;\n' +
        '}';

    public static function build(): ShaderMaterial {
        var uniforms = UniformsUtils.clone(ShaderLib.kaleido.uniforms);
        uniforms['tDiffuse'].value = null;
        uniforms['sides'].value = 6.0;
        uniforms['angle'].value = 0.0;

        var material = new ShaderMaterial({
            uniforms: uniforms,
            vertexShader: ShaderLib.kaleido.vertexShader,
            fragmentShader: ShaderLib.kaleido.fragmentShader
        });

        return material;
    }
}