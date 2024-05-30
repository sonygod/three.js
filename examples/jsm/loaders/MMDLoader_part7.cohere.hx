class MMDToonMaterial extends ShaderMaterial {
    public var _matcapCombine:Int;
    public var emissiveIntensity:Float;
    public var normalMapType:Int;
    public var combine:Int;
    public var wireframeLinecap:String;
    public var wireframeLinejoin:String;
    public var flatShading:Bool;

    public function new(parameters:Dynamic) {
        super();

        isMMDToonMaterial = true;
        type = 'MMDToonMaterial';
        _matcapCombine = AddOperation;
        emissiveIntensity = 1.0;
        normalMapType = TangentSpaceNormalMap;
        combine = MultiplyOperation;
        wireframeLinecap = 'round';
        wireframeLinejoin = 'round';
        flatShading = false;
        lights = true;

        vertexShader = MMDToonShader.vertexShader;
        fragmentShader = MMDToonShader.fragmentShader;

        defines = Object.assign({}, MMDToonShader.defines);
        setMatcapCombine(value) {
            _matcapCombine = value;
            switch (value) {
                case MultiplyOperation:
                    defines.MATCAP_BLENDING_MULTIPLY = true;
                    delete defines.MATCAP_BLENDING_ADD;
                    break;
                default:
                case AddOperation:
                    defines.MATCAP_BLENDING_ADD = true;
                    delete defines.MATCAP_BLENDING_MULTIPLY;
                    break;
            }
        }

        uniforms = UniformsUtils.clone(MMDToonShader.uniforms);

        // merged from MeshToon/Phong/MatcapMaterial
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
            var propertyName = exposePropertyNames[i];
            Object.defineProperty(this, propertyName, {
                get: function () {
                    return uniforms[propertyName].value;
                },
                set: function (value) {
                    uniforms[propertyName].value = value;
                }
            });
        }

        // Special path for shininess to handle zero shininess properly
        _shininess = 30;
        Object.defineProperty(this, 'shininess', {
            get: function () {
                return _shininess;
            },
            set: function (value) {
                _shininess = value;
                uniforms.shininess.value = Math.max(_shininess, 1e-4); // To prevent pow(0.0, 0.0)
            }
        });

        Object.defineProperty(
            this,
            'color',
            Object.getOwnPropertyDescriptor(this, 'diffuse')
        );

        setValues(parameters);
    }

    public function copy(source:MMDToonMaterial) {
        super.copy(source);
        matcapCombine = source.matcapCombine;
        emissiveIntensity = source.emissiveIntensity;
        normalMapType = source.normalMapType;
        combine = source.combine;
        wireframeLinecap = source.wireframeLinecap;
        wireframeLinejoin = source.wireframeLinejoin;
        flatShading = source.flatShading;
        return this;
    }
}