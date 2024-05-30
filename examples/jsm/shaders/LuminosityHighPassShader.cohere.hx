package;

import js.WebGL.WebGLProgram;
import js.WebGL.WebGLUniforms;
import js.WebGL.WebGLUtils;

class LuminosityHighPassShader {
    public static inline var name: String = "LuminosityHighPassShader";
    public static inline var shaderID: String = "luminosityHighPass";

    public var tDiffuse: Int;
    public var luminosityThreshold: Float;
    public var smoothWidth: Float;
    public var defaultColor: Float;
    public var defaultOpacity: Float;

    public function new() {
        tDiffuse = 0;
        luminosityThreshold = 1.0;
        smoothWidth = 1.0;
        defaultColor = 0;
        defaultOpacity = 0.0;
    }

    public static function getVertexShader(): String {
        return """
            varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        """;
    }

    public static function getFragmentShader(): String {
        return """
            uniform sampler2D tDiffuse;
            uniform vec3 defaultColor;
            uniform float defaultOpacity;
            uniform float luminosityThreshold;
            uniform float smoothWidth;
            varying vec2 vUv;

            void main() {
                vec4 texel = texture2D( tDiffuse, vUv );
                vec3 luma = vec3( 0.299, 0.587, 0.114 );
                float v = dot( texel.xyz, luma );
                vec4 outputColor = vec4( defaultColor.rgb, defaultOpacity );
                float alpha = smoothstep( luminosityThreshold, luminosityThreshold + smoothWidth, v );
                gl_FragColor = mix( outputColor, texel, alpha );
            }
        """;
    }

    public function init(gl: WebGLRenderingContext, program: WebGLProgram): Void {
        tDiffuse = WebGLUtils.getUniformLocation(gl, program, "tDiffuse");
        luminosityThreshold = WebGLUtils.getUniformLocation(gl, program, "luminosityThreshold");
        smoothWidth = WebGLUtils.getUniformLocation(gl, program, "smoothWidth");
        defaultColor = WebGLUtils.getUniformLocation(gl, program, "defaultColor");
        defaultOpacity = WebGLUtils.getUniformLocation(gl, program, "defaultOpacity");
    }

    public function update(gl: WebGLRenderingContext, uniforms: WebGLUniforms, width: Int, height: Int): Void {
        gl.uniform1i(tDiffuse, 0);
        gl.uniform1f(luminosityThreshold, this.luminosityThreshold);
        gl.uniform1f(smoothWidth, this.smoothWidth);
        gl.uniform3f(defaultColor, this.defaultColor, this.defaultColor, this.defaultColor);
        gl.uniform1f(defaultOpacity, this.defaultOpacity);
    }
}