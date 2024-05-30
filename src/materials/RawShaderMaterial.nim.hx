import ShaderMaterial from './ShaderMaterial.js';

class RawShaderMaterial extends ShaderMaterial {

    public function new(parameters: Dynamic) {

        super(parameters);

        this.isRawShaderMaterial = true;

        this.type = 'RawShaderMaterial';

    }

}

export RawShaderMaterial;