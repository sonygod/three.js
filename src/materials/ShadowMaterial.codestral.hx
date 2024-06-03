import three.materials.Material;
import three.math.Color;

class ShadowMaterial extends Material {

    public function new(parameters:Dynamic) {
        super();

        this.isShadowMaterial = true;
        this.type = 'ShadowMaterial';
        this.color = new Color(0x000000);
        this.transparent = true;
        this.fog = true;

        this.setValues(parameters);
    }

    public function copy(source:ShadowMaterial):ShadowMaterial {
        super.copy(source);

        this.color.copy(source.color);
        this.fog = source.fog;

        return this;
    }

}

export ShadowMaterial;