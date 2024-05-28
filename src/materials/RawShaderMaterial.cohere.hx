import js.ShaderMaterial;

class RawShaderMaterial extends ShaderMaterial {
	public function new(parameters:Dynamic) {
		super(parameters);
		this.isRawShaderMaterial = true;
		this.setType("RawShaderMaterial");
	}
}

@:jsRequire("RawShaderMaterial")
extern var RawShaderMaterial_proto:RawShaderMaterial;