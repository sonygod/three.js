import js.html.WebGLRenderingContext;
import three.materials.ShaderMaterial;
import three.materials.Material;
import three.materials.uniforms.UniformsUtils;
import three.constants.Constants;
import three.shaders.MMDToonShader;

class MMDToonMaterial extends ShaderMaterial {

    public var isMMDToonMaterial:Bool = true;
    public var _matcapCombine:Int = Constants.AddOperation;
    public var emissiveIntensity:Float = 1.0;
    public var normalMapType:Int = Constants.TangentSpaceNormalMap;
    public var combine:Int = Constants.MultiplyOperation;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';
    public var flatShading:Bool = false;
    public var lights:Bool = true;
    public var _shininess:Float = 30;

    public function new(parameters:Dynamic = null) {
        super();
        this.type = 'MMDToonMaterial';
        this.vertexShader = MMDToonShader.vertexShader;
        this.fragmentShader = MMDToonShader.fragmentShader;
        this.defines = js.Boot.clone(MMDToonShader.defines);
        this.uniforms = UniformsUtils.clone(MMDToonShader.uniforms);

        var exposePropertyNames = [
            'specular',
            'opacity',
            'diffuse',
            'map',
            'matcap',
            'gradientMap',
            'lightMap',
            'lightMapIntensity',
            'aoMap',
            'aoMapIntensity',
            'emissive',
            'emissiveMap',
            'bumpMap',
            'bumpScale',
            'normalMap',
            'normalScale',
            'displacemantBias',
            'displacemantMap',
            'displacemantScale',
            'specularMap',
            'alphaMap',
            'reflectivity',
            'refractionRatio',
        ];

        for (propertyName in exposePropertyNames) {
            var property = propertyName;
            Object.defineProperty(this, property, {
                get: function() {
                    return this.uniforms[property].value;
                },
                set: function(value) {
                    this.uniforms[property].value = value;
                },
            });
        }

        Object.defineProperty(this, 'shininess', {
            get: function() {
                return this._shininess;
            },
            set: function(value) {
                this._shininess = value;
                this.uniforms.shininess.value = Math.max(this._shininess, 1e-4);
            },
        });

        Object.defineProperty(this, 'color', Object.getOwnPropertyDescriptor(this, 'diffuse'));

        if (parameters != null) this.setValues(parameters);
    }

    public function get matcapCombine():Int {
        return this._matcapCombine;
    }

    public function set matcapCombine(value:Int) {
        this._matcapCombine = value;
        switch (value) {
            case Constants.MultiplyOperation:
                this.defines.MATCAP_BLENDING_MULTIPLY = true;
                delete this.defines.MATCAP_BLENDING_ADD;
                break;
            default:
            case Constants.AddOperation:
                this.defines.MATCAP_BLENDING_ADD = true;
                delete this.defines.MATCAP_BLENDING_MULTIPLY;
                break;
        }
    }

    public function copy(source:MMDToonMaterial):Material {
        super.copy(source);
        this.matcapCombine = source.matcapCombine;
        this.emissiveIntensity = source.emissiveIntensity;
        this.normalMapType = source.normalMapType;
        this.combine = source.combine;
        this.wireframeLinecap = source.wireframeLinecap;
        this.wireframeLinejoin = source.wireframeLinejoin;
        this.flatShading = source.flatShading;
        return this;
    }
}