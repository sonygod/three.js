package three.js.examples.jsm.shaders;

import js.html.webgl.RenderingContext;
import three.js.Texture;

class LuminosityShader {
    public var name:String = 'LuminosityShader';

    public var uniforms:Dynamic = {
        tDiffuse: { value: null }
    };

    public var vertexShader:String = "
        varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
        }
    ";

    public var fragmentShader:String = "
        #include <common>
        uniform sampler2D tDiffuse;
        varying vec2 vUv;
        void main() {
            vec4 texel = texture2D(tDiffuse, vUv);
            float l = luminance(texel.rgb);
            gl_FragColor = vec4(l, l, l, texel.w);
        }
    ";
}