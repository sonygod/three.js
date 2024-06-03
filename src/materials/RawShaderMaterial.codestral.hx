import three.materials.ShaderMaterial;

class RawShaderMaterial {
    public var isRawShaderMaterial:Bool = true;
    public var type:String = 'RawShaderMaterial';
    public var shaderMaterial:ShaderMaterial;

    public function new(parameters:Dynamic) {
        this.shaderMaterial = new ShaderMaterial(parameters);
    }
}

export RawShaderMaterial;