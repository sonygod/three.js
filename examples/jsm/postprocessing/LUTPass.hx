package three.js.examples.javascript.postprocessing;

import three.js.renderers.shaders.ShaderPass;

class LUTShader {
    public static var NAME:String = 'LUTShader';

    public static var uniforms = {
        lut: { value: null },
        lutSize: { value: 0.0 },
        tDiffuse: { value: null },
        intensity: { value: 1.0 }
    };

    public static var vertexShader:String = 
        "varying vec2 vUv;
        void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
        }";

    public static var fragmentShader:String = 
        "uniform float lutSize;
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
        }";
}

class LUTPass extends ShaderPass {
    private var _lut:Dynamic;
    private var _intensity:Float;

    public function new(?options:Dynamic) {
        super(LUTShader);
        _lut = options.lut != null ? options.lut : null;
        _intensity = Reflect.hasField(options, 'intensity') ? options.intensity : 1.0;
    }

    public function set_lut(v:Dynamic) {
        var material:Dynamic = this.material;
        if (v != _lut) {
            material.uniforms.lut.value = null;
            if (v != null) {
                material.uniforms.lutSize.value = v.image.width;
                material.uniforms.lut.value = v;
            }
            _lut = v;
        }
    }

    public function get_lut():Dynamic {
        return this.material.uniforms.lut.value;
    }

    public function set_intensity(v:Float) {
        this.material.uniforms.intensity.value = v;
        _intensity = v;
    }

    public function get_intensity():Float {
        return this.material.uniforms.intensity.value;
    }
}