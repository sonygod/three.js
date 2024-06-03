import ShaderMaterial from "./ShaderMaterial";

class RawShaderMaterial extends ShaderMaterial {

    public var isRawShaderMaterial:Bool = true;
    public var type:String = "RawShaderMaterial";

    public function new(parameters:Dynamic) {
        super(parameters);
    }
}

export class RawShaderMaterial {
    static var RawShaderMaterial:RawShaderMaterial = new RawShaderMaterial();
}