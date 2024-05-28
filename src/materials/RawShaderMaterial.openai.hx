package three.materials;

import three.materials.ShaderMaterial;

class RawShaderMaterial extends ShaderMaterial {
    public var isRawShaderMaterial:Bool = true;
    public var type:String = 'RawShaderMaterial';

    public function new(parameters: Dynamic) {
        super(parameters);
    }
}