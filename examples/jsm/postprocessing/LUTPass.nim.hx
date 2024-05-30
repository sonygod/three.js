import three.examples.jsm.postprocessing.ShaderPass;

class LUTShader {
    public static var name:String = 'LUTShader';
    public static var uniforms:Dynamic = {
        lut: { value: null },
        lutSize: { value: 0 },
        tDiffuse: { value: null },
        intensity: { value: 1.0 },
    };
    public static var vertexShader:String =
        "varying vec2 vUv;\n" +
        "void main() {\n" +
        "   vUv = uv;\n" +
        "   gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );\n" +
        "}\n";
    public static var fragmentShader:String =
        "uniform float lutSize;\n" +
        "uniform sampler3D lut;\n" +
        "varying vec2 vUv;\n" +
        "uniform float intensity;\n" +
        "uniform sampler2D tDiffuse;\n" +
        "void main() {\n" +
        "   vec4 val = texture2D( tDiffuse, vUv );\n" +
        "   vec4 lutVal;\n" +
        "   float pixelWidth = 1.0 / lutSize;\n" +
        "   float halfPixelWidth = 0.5 / lutSize;\n" +
        "   vec3 uvw = vec3( halfPixelWidth ) + val.rgb * ( 1.0 - pixelWidth );\n" +
        "   lutVal = vec4( texture( lut, uvw ).rgb, val.a );\n" +
        "   gl_FragColor = vec4( mix( val, lutVal, intensity ) );\n" +
        "}\n";
}

class LUTPass extends ShaderPass {
    public var _lut:Dynamic;
    public function set lut(v:Dynamic) {
        var material = this.material;
        if (v !== this._lut) {
            material.uniforms.lut.value = null;
            if (v) {
                material.uniforms.lutSize.value = v.image.width;
                material.uniforms.lut.value = v;
            }
        }
        this._lut = v;
    }
    public function get lut():Dynamic {
        return this.material.uniforms.lut.value;
    }
    public function set intensity(v:Float) {
        this.material.uniforms.intensity.value = v;
    }
    public function get intensity():Float {
        return this.material.uniforms.intensity.value;
    }
    public function new(options:Dynamic) {
        super(LUTShader);
        this.lut = options.lut || null;
        this.intensity = 'intensity' in options ? options.intensity : 1;
    }
}

export class LUTPass;