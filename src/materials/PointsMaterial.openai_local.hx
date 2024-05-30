package three.materials;

import three.math.Color;

class PointsMaterial extends Material {

    public var isPointsMaterial:Bool;
    public var type:String;
    public var color:Color;
    public var map:Dynamic; // Assuming a generic type for map, replace with appropriate type if known
    public var alphaMap:Dynamic; // Assuming a generic type for alphaMap, replace with appropriate type if known
    public var size:Float;
    public var sizeAttenuation:Bool;
    public var fog:Bool;

    public function new(parameters:Dynamic) {
        super();
        this.isPointsMaterial = true;
        this.type = 'PointsMaterial';
        this.color = new Color(0xffffff);
        this.map = null;
        this.alphaMap = null;
        this.size = 1;
        this.sizeAttenuation = true;
        this.fog = true;
        this.setValues(parameters);
    }

    public function copy(source:PointsMaterial):PointsMaterial {
        super.copy(source);
        this.color.copy(source.color);
        this.map = source.map;
        this.alphaMap = source.alphaMap;
        this.size = source.size;
        this.sizeAttenuation = source.sizeAttenuation;
        this.fog = source.fog;
        return this;
    }
}