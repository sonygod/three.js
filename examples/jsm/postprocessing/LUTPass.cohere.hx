import js.Browser.WebGL.WebGLProgram;
import js.Browser.WebGL.WebGLRenderingContext;
import js.Browser.WebGL.WebGLShader;
import js.Browser.WebGL.WebGLTexture;

class LUTShader {
    static var name: String = 'LUTShader';
    static var uniforms: { [key: String]: { value: Dynamic; } } = {
        'lut': { value: null },
        'lutSize': { value: 0 },
        'tDiffuse': { value: null },
        'intensity': { value: 1.0 }
    };
    static var vertexShader: String = "
            varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        ";
    static var fragmentShader: String = "
            uniform float lutSize;
            uniform sampler3D lut;
            varying vec2 vUv;
            uniform float intensity;
            uniform sampler2D tDiffuse;
            void main() {
                vec4 val = texture2D( tDiffuse, vUv );
                vec4 lutVal;
                float pixelWidth = 1.0 / lutSize;
                float halfPixelWidth = 0.5 / lutSize;
                vec3 uvw = vec3( halfPixelWidth ) + val.rgb * ( 1.0 - pixelWidth );
                lutVal = vec4( texture( lut, uvw ).rgb, val.a );
                gl_FragColor = vec4( mix( val, lutVal, intensity ) );
            }
        ";
}

class LUTPass extends ShaderPass {
    public function set_lut(v: WebGLTexture): Void {
        var material = this.material;
        if (v != this.lut) {
            material.uniforms.lut.value = null;
            if (v != null) {
                material.uniforms.lutSize.value = v.image.width;
                material.uniforms.lut.value = v;
            }
        }
    }
    public function get_lut(): WebGLTexture {
        return this.material.uniforms.lut.value;
    }
    public function set_intensity(v: Float): Void {
        this.material.uniforms.intensity.value = v;
    }
    public function get_intensity(): Float {
        return this.material.uniforms.intensity.value;
    }
    public function new(options: { lut: WebGLTexture, intensity: Float } = { lut: null, intensity: 1 }) {
        super(LUTShader);
        this.lut = options.lut || null;
        this.intensity = if (options.hasOwnProperty('intensity')) options.intensity else 1;
    }
}

extern class ShaderPass {
    public function new(shader: { [key: String]: String }) {
        // ...
    }
    public var material: { uniforms: { [key: String]: { value: Dynamic } } }
    // ...
}