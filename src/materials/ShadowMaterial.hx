package three.materials;

import three.materials.Material;
import three.math.Color;

class ShadowMaterial extends Material {

    public var isShadowMaterial:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();

        type = 'ShadowMaterial';

        color = new Color(0x000000);
        transparent = true;

        fog = true;

        setValues(parameters);
    }

    public function copy(source:ShadowMaterial):ShadowMaterial {
        super.copy(source);

        color.copy(source.color);

        fog = source.fog;

        return this;
    }
}