package three.js.examples.jm.shaders;

import three.js.renderers.shaders.Shader;

class TechnicolorShader extends Shader {
    public function new() {
        super();
        this.name = 'TechnicolorShader';
        this.uniforms = {
            'tDiffuse': { value: null }
        };
        this.vertexShader = '
            varying vec2 vUv;

            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ';
        this.fragmentShader = '
            uniform sampler2D tDiffuse;
            varying vec2 vUv;

            void main() {
                vec4 tex = texture2D( tDiffuse, vec2( vUv.x, vUv.y ) );
                vec4 newTex = vec4(tex.r, (tex.g + tex.b) * .5, (tex.g + tex.b) * .5, 1.0);

                gl_FragColor = newTex;
            }
        ';
    }
}