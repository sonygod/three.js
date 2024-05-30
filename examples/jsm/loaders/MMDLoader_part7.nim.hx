import three.js.extras.core.UniformsUtils;
import three.js.extras.shaders.MMDToonShader;
import three.js.materials.ShaderMaterial;
import three.js.math.Color;
import three.js.math.Vector2;
import three.js.textures.Texture;

class MMDToonMaterial extends ShaderMaterial {
    public var isMMDToonMaterial:Bool = true;
    public var type:String = 'MMDToonMaterial';
    private var _matcapCombine:Dynamic;
    public var emissiveIntensity:Float = 1.0;
    public var normalMapType:Dynamic;
    public var combine:Dynamic;
    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';
    public var flatShading:Bool = false;
    public var lights:Bool = true;
    public var vertexShader:String = MMDToonShader.vertexShader;
    public var fragmentShader:String = MMDToonShader.fragmentShader;
    public var defines:Dynamic;
    public var uniforms:Dynamic;

    public function new(parameters:Dynamic) {
        super();
        this._matcapCombine = AddOperation;
        this.defines = Std.object(MMDToonShader.defines);
        this.uniforms = UniformsUtils.clone(MMDToonShader.uniforms);

        var exposePropertyNames:Array<String> = [
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
            'refractionRatio'
        ];

        for (propertyName in exposePropertyNames) {
            Object.defineProperty(this, propertyName, {
                get: function() {
                    return this.uniforms[propertyName].value;
                },
                set: function(value) {
                    this.uniforms[propertyName].value = value;
                }
            });
        }

        this._shininess = 30;
        Object.defineProperty(this, 'shininess', {
            get: function() {
                return this._shininess;
            },
            set: function(value) {
                this._shininess = value;
                this.uniforms.shininess.value = Math.max(this._shininess, 1e-4);
            }
        });

        Object.defineProperty(this, 'color', Object.getOwnPropertyDescriptor(this, 'diffuse'));

        this.setValues(parameters);

        Object.defineProperty(this, 'matcapCombine', {
            get: function() {
                return this._matcapCombine;
            },
            set: function(value) {
                this._matcapCombine = value;
                switch (value) {
                    case MultiplyOperation:
                        this.defines.MATCAP_BLENDING_MULTIPLY = true;
                        delete this.defines.MATCAP_BLENDING_ADD;
                        break;
                    default:
                    case AddOperation:
                        this.defines.MATCAP_BLENDING_ADD = true;
                        delete this.defines.MATCAP_BLENDING_MULTIPLY;
                        break;
                }
            }
        });
    }

    public function copy(source:MMDToonMaterial):MMDToonMaterial {
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