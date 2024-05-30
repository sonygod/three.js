package three.js.examples.jsm.shaders;

import three.shader.Shader;

class ExposureShader extends Shader {
    public function new() {
        super();
        name = 'ExposureShader';

        uniforms.set('tDiffuse', { value: null });
        uniforms.set('exposure', { value: 1.0 });

        vertexShader = "
			varying vec2 vUv;

			void main() {
				vUv = uv;
				gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
			}
		";

        fragmentShader = "
			uniform float exposure;
			uniform sampler2D tDiffuse;

			varying vec2 vUv;

			void main() {
				gl_FragColor = texture2D( tDiffuse, vUv );
				gl_FragColor.rgb *= exposure;
			}
		";
    }
}