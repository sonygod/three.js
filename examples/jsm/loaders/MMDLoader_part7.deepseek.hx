class MMDToonMaterial extends ShaderMaterial {

	public function new(parameters:Dynamic) {

		super();

		this.isMMDToonMaterial = true;

		this.type = 'MMDToonMaterial';

		this._matcapCombine = AddOperation;
		this.emissiveIntensity = 1.0;
		this.normalMapType = TangentSpaceNormalMap;

		this.combine = MultiplyOperation;

		this.wireframeLinecap = 'round';
		this.wireframeLinejoin = 'round';

		this.flatShading = false;

		this.lights = true;

		this.vertexShader = MMDToonShader.vertexShader;
		this.fragmentShader = MMDToonShader.fragmentShader;

		this.defines = Std.clone(MMDToonShader.defines);
		this.matcapCombine = this._matcapCombine;

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

			this[propertyName] = this.uniforms[propertyName].value;

		}

		this._shininess = 30;
		this.shininess = this._shininess;

		this.color = this.diffuse;

		this.setValues(parameters);

	}

	public function copy(source:MMDToonMaterial) {

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