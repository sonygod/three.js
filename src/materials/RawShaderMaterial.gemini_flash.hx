import three.materials.ShaderMaterial;

class RawShaderMaterial extends ShaderMaterial {

	public function new(parameters:Dynamic) {
		super(parameters);

		this.isRawShaderMaterial = true;
		this.type = "RawShaderMaterial";
	}

	public var isRawShaderMaterial:Bool;
	public var type:String;

}