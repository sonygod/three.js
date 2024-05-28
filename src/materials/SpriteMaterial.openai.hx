package three.materials;

import three.materials.Material;
import three.math.Color;

class SpriteMaterial extends Material {
    public var isSpriteMaterial:Bool = true;
    public var type:String = 'SpriteMaterial';
    public var color:Color;
    public var map:Null<Texture>;
    public var alphaMap:Null<Texture>;
    public var rotation:Float = 0;
    public var sizeAttenuation:Bool = true;
    public var transparent:Bool = true;
    public var fog:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        color = new Color(0xffffff);
        setValues(parameters);
    }

    public function copy(source:SpriteMaterial):SpriteMaterial {
        super.copy(source);
        color.copy(source.color);
        map = source.map;
        alphaMap = source.alphaMap;
        rotation = source.rotation;
        sizeAttenuation = source.sizeAttenuation;
        fog = source.fog;
        return this;
    }
}