import js.html.WebGLRenderingContext;

class VignetteShader {
    public var name: String = "VignetteShader";

    public var uniforms: js.html.WebGLUniformLocation = {
        "tDiffuse": { value: null },
        "offset": { value: 1.0 },
        "darkness": { value: 1.0 }
    };

    public var vertexShader: String = "varying vec2 vUv;\n\nvoid main() {\n\tvUv = uv;\n\tgl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n}";

    public var fragmentShader: String = "uniform float offset;\nuniform float darkness;\n\nuniform sampler2D tDiffuse;\n\nvarying vec2 vUv;\n\nvoid main() {\n\tvec4 texel = texture2D( tDiffuse, vUv );\n\tvec2 uv = ( vUv - vec2( 0.5 ) ) * vec2( offset );\n\tgl_FragColor = vec4( mix( texel.rgb, vec3( 1.0 - darkness ), dot( uv, uv ) ), texel.a );\n}";
}

// Export the class
@:expose
class VignetteShaderExport {
    public static var VignetteShader = VignetteShader;
}


This Haxe code defines a `VignetteShader` class with the same properties and values as the JavaScript object literal. It also includes a wrapper class `VignetteShaderExport` to expose the `VignetteShader` class to JavaScript. This is necessary because Haxe compiles to JavaScript, and JavaScript modules can't directly export classes.

The `@:expose` metadata is used to mark the `VignetteShaderExport` class for exposure to JavaScript. When the Haxe code is compiled, it will generate a JavaScript file that includes the `VignetteShader` class and the `VignetteShaderExport` wrapper class. The `VignetteShader` class can then be imported and used in JavaScript code like this:

javascript
import { VignetteShaderExport as VignetteShader } from './VignetteShader.js';

const shader = new VignetteShader.VignetteShader();