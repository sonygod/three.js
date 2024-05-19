package three.js.examples.jm.loaders;

import js.html.WebGLRenderingContext;
import three.js.loaders.ShaderMaterial;

class MMDToonMaterial extends ShaderMaterial {
    public var isMMDToonMaterial:Bool = true;
    public var type:String = 'MMDToonMaterial';

    private var _matcapCombine:Int;
    public var emissiveIntensity:Float = 1.0;
    public var normalMapType:Int = TangentSpaceNormalMap;

    public var combine:Int = MultiplyOperation;

    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';

    public var flatShading:Bool = false;

    public var lights:Bool = true;

    public var vertexShader:String = MMDToonShader.vertexShader;
    public var fragmentShader:String = MMDToonShader.fragmentShader;

    public var defines:Dynamic = Object.assign({}, MMDToonShader.defines);

    public function new(parameters:Dynamic) {
        super();

        this.uniforms = UniformsUtils.clone(MMDToonShader.uniforms);

        exposeProperties();

        setValues(parameters);
    }

    private function exposeProperties():Void {
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
            Reflect.setProperty(this, propertyName, {
                get: function() {
                    return uniforms[propertyName].value;
                },
                set: function(value) {
                    uniforms[propertyName].value = value;
                }
            });
        }

        // Special path for shininess to handle zero shininess properly
        var _shininess:Float = 30;
        Reflect.setProperty(this, 'shininess', {
            get: function() {
                return _shininess;
            },
            set: function(value) {
                _shininess = value;
                uniforms.shininess.value = Math.max(_shininess, 1e-4); // To prevent pow( 0.0, 0.0 )
            }
        });

        Reflect.setProperty(this, 'color', Reflect.getProperty(this, 'diffuse'));

        Reflect.defineProperty(this, 'matcapCombine', {
            get: function() {
                return _matcapCombine;
            },
            set: function(value) {
                _matcapCombine = value;
                switch (_matcapCombine) {
                    case MultiplyOperation:
                        defines.MATCAP_BLENDING_MULTIPLY = true;
                        delete defines.MATCAP_BLENDING_ADD;
                    default:
                    case AddOperation:
                        defines.MATCAP_BLENDING_ADD = true;
                        delete defines.MATCAP_BLENDING_MULTIPLY;
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