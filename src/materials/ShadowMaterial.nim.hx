import three.js.src.materials.Material;
import three.js.src.math.Color;

class ShadowMaterial extends Material {

    public var isShadowMaterial:Bool = true;

    public var type:String = 'ShadowMaterial';

    public var color:Color = new Color(0x000000);
    public var transparent:Bool = true;

    public var fog:Bool = true;

    public function new(parameters:Dynamic) {
        super();
        this.setValues(parameters);
    }

    public function copy(source:ShadowMaterial):ShadowMaterial {
        super.copy(source);
        this.color.copy(source.color);
        this.fog = source.fog;
        return this;
    }

}

export(ShadowMaterial);