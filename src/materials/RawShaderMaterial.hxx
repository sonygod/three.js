import three.js.src.materials.ShaderMaterial;

class RawShaderMaterial extends ShaderMaterial {

    public function new(parameters:Dynamic) {
        super(parameters);

        this.isRawShaderMaterial = true;

        this.type = 'RawShaderMaterial';
    }

}

typedef RawShaderMaterial = three.js.src.materials.RawShaderMaterial;