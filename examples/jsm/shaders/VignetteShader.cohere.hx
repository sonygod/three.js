package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLRenderingContext;

class VignetteShader {
    public var name: String = "VignetteShader";
    public var uniforms: { [key: String]: { value: Dynamic } } = {
        "tDiffuse": { value: null },
        "offset": { value: 1.0 },
        "darkness": { value: 1.0 }
    };

    public var vertexShader: String = "
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ";

    public var fragmentShader: String = "
        uniform float offset;
        uniform float darkness;
        uniform sampler2D tDiffuse;
        varying vec2 vUv;
        void main() {
            vec4 texel = texture2D(tDiffuse, vUv);
            vec2 uv = (vUv - vec2(0.5)) * vec2(offset);
            gl_FragColor = vec4(mix(texel.rgb, vec3(1.0 - darkness), dot(uv, uv)), texel.a);
        }
    ";

    public function new(): Void {
        // Empty constructor
    }
}

class VignetteShaderFactory {
    public static function create(): VignetteShader {
        return new VignetteShader();
    }
}

class VignetteShaderModule {
    public static var VignetteShader: VignetteShaderFactory = VignetteShaderFactory;
}