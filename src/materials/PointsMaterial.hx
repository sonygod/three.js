package three.materials;

import three.materials.Material;
import three.math.Color;

class PointsMaterial extends Material {

    public var isPointsMaterial:Bool = true;

    public var type:String = 'PointsMaterial';

    public var color:Color;

    public var map:Dynamic;

    public var alphaMap:Dynamic;

    public var size:Float = 1;

    public var sizeAttenuation:Bool = true;

    public var fog:Bool = true;

    public function new(parameters:Dynamic = null) {
        super();
        color = new Color(0xffffff);
        if (parameters != null) setValues(parameters);
    }

    public function copy(source:PointsMaterial):PointsMaterial {
        super.copy(source);
        color.copy(source.color);
        map = source.map;
        alphaMap = source.alphaMap;
        size = source.size;
        sizeAttenuation = source.sizeAttenuation;
        fog = source.fog;
        return this;
    }
}