package three.js.examples.jsm.loaders;

import js.html.WebGLRenderingContext;
import three.js.materials.ShaderMaterial;

class MMDToonMaterial extends ShaderMaterial {
    public var isMMDToonMaterial:Bool = true;

    public var type:String = 'MMDToonMaterial';

    private var _matcapCombine:Dynamic;
    public var matcapCombine(get, set):Dynamic;

    public var emissiveIntensity:Float = 1.0;
    public var normalMapType:Int = TangentSpaceNormalMap;

    public var combine:Dynamic = MultiplyOperation;

    public var wireframeLinecap:String = 'round';
    public var wireframeLinejoin:String = 'round';

    public var flatShading:Bool = false;

    public var lights:Bool = true;

    public var vertexShader:String = MMDToonShader.vertexShader;
    public var fragmentShader:String = MMDToonShader.fragmentShader;

    public var defines:Dynamic = MMDToonShader.defines.copy();

    public var uniforms:Dynamic = UniformsUtils.clone(MMDToonShader.uniforms);

    private var _shininess:Float = 30.0;
    public var shininess(get, set):Float;

    public function new(parameters:Dynamic) {
        super();

        this.setValues(parameters);

        Reflect.setProperty(this, "matcapCombine", {
            get: function() {
                return _matcapCombine;
            },
            set: function(value:Dynamic) {
                _matcapCombine = value;
                switch (value) {
                    case MultiplyOperation:
                        defines.MATCAP_BLENDING_MULTIPLY = true;
                        Reflect.deleteField(defines, "MATCAP_BLENDING_ADD");
                    default:
                    case AddOperation:
                        defines.MATCAP_BLENDING_ADD = true;
                        Reflect.deleteField(defines, "MATCAP_BLENDING_MULTIPLY");
                }
            }
        });

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
                set: function(value:Dynamic) {
                    uniforms[propertyName].value = value;
                }
            });
        }

        Reflect.setProperty(this, "shininess", {
            get: function() {
                return _shininess;
            },
            set: function(value:Float) {
                _shininess = value;
                uniforms.shininess.value = Math.max(_shininess, 1e-4);
            }
        });

        Reflect.setProperty(this, "color", Reflect.getProperty(this, "diffuse"));
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