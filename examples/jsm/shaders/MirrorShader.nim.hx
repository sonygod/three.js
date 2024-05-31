// File path: three.js/examples/jsm/shaders/MirrorShader.hx

package three.examples.jsm.shaders;

import three.Shader;
import three.UniformsUtils;
import three.WebGLUniforms;

class MirrorShader extends Shader {

    public static var name: String = 'MirrorShader';

    public static var uniforms: WebGLUniforms = UniformsUtils.merge([
        {
            'tDiffuse': { value: null },
            'side': { value: 1 }
        }
    ]);

    public static var vertexShader: String = 'varying vec2 vUv;\n\nvoid main() {\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n\n}';

    public static var fragmentShader: String = 'uniform sampler2D tDiffuse;\nuniform int side;\n\nvarying vec2 vUv;\n\nvoid main() {\n\tvec2 p = vUv;\n\tif (side == 0) {\n\t\tif (p.x > 0.5) p.x = 1.0 - p.x;\n\t}\n\telse if (side == 1) {\n\t\tif (p.x < 0.5) p.x = 1.0 - p.x;\n\t}\n\telse if (side == 2) {\n\t\tif (p.y < 0.5) p.y = 1.0 - p.y;\n\t}\n\telse if (side == 3) {\n\t\tif (p.y > 0.5) p.y = 1.0 - p.y;\n\t}\n\tvec4 color = texture2D(tDiffuse, p);\n\tgl_FragColor = color;\n\n}';

}

export { MirrorShader };