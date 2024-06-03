import js.Browser.document;
import js.lib.WebGLRenderingContext;

class LUTShader {
    public var name:String = "LUTShader";
    public var uniforms:haxe.ds.StringMap<Dynamic> = new haxe.ds.StringMap();
    public var vertexShader:String;
    public var fragmentShader:String;

    public function new() {
        this.uniforms = {
            "lut": { value: null },
            "lutSize": { value: 0 },
            "tDiffuse": { value: null },
            "intensity": { value: 1.0 },
        };

        this.vertexShader = `
            varying vec2 vUv;
            void main() {
                vUv = uv;
                gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
            }
        `;

        this.fragmentShader = `
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
        `;
    }
}

class LUTPass extends ShaderPass {
    private var _lut:Dynamic;

    public function get_lut():Dynamic {
        return this._lut;
    }

    public function set_lut(v:Dynamic) {
        if (v !== this._lut) {
            this.material.uniforms.lut.value = null;

            if (v != null) {
                this.material.uniforms.lutSize.value = v.image.width;
                this.material.uniforms.lut.value = v;
            }
        }

        this._lut = v;
    }

    private var _intensity:Float;

    public function get_intensity():Float {
        return this._intensity;
    }

    public function set_intensity(v:Float) {
        this.material.uniforms.intensity.value = v;
        this._intensity = v;
    }

    public function new(options:haxe.ds.StringMap<Dynamic> = null) {
        super(new LUTShader());

        if (options != null) {
            this.lut = options.exists("lut") ? options.get("lut") : null;
            this.intensity = options.exists("intensity") ? options.get("intensity") : 1;
        } else {
            this.lut = null;
            this.intensity = 1;
        }
    }
}