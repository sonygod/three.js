package three.examples.jsm.shaders;

import three.Shader;
import three.UniformsUtils;
import three.UniformsLib;

class TechnicolorShader extends Shader {

    public function new() {
        super( {
            name: 'TechnicolorShader',
            uniforms: UniformsUtils.merge( [
                UniformsLib.common,
                UniformsLib.diffuse,
                {
                    'tDiffuse': { value: null }
                }
            ] ),
            vertexShader: 'varying vec2 vUv;\n\
                void main() {\n\
                    vUv = uv;\n\
                    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n\
                }',
            fragmentShader: 'uniform sampler2D tDiffuse;\n\
                varying vec2 vUv;\n\
                void main() {\n\
                    vec4 tex = texture2D( tDiffuse, vec2( vUv.x, vUv.y ) );\n\
                    vec4 newTex = vec4(tex.r, (tex.g + tex.b) * .5, (tex.g + tex.b) * .5, 1.0);\n\
                    gl_FragColor = newTex;\n\
                }'
        } );
    }

}