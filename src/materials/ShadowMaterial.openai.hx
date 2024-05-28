package three.materials;

import three.math.Color;
import three.materials.Material;

class ShadowMaterial extends Material {
    public var isShadowMaterial:Bool = true;
    public var type:String = 'ShadowMaterial';
    public var color:Color;
    public var transparent:Bool = true;
    public var fog:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        color = new Color(0x000000);
        if (parameters != null) setValues(parameters);
    }

    override public function copy(source:ShadowMaterial):ShadowMaterial {
        super.copy(source);
        color.copy(source.color);
        fog = source.fog;
        return this;
    }
}