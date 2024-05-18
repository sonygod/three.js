package three.scenes;

import three.math.Color;

class FogExp2 {
    public var isFogExp2:Bool;
    public var name:String;
    public var color:Color;
    public var density:Float;

    public function new(color:Color, density:Float = 0.00025) {
        isFogExp2 = true;
        name = '';
        this.color = new Color(color);
        this.density = density;
    }

    public function clone():FogExp2 {
        return new FogExp2(color, density);
    }

    public function toJSON(?meta:Any):Dynamic {
        return {
            type: 'FogExp2',
            name: name,
            color: color.getHex(),
            density: density
        };
    }
}