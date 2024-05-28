package three.js.src.scenes;

import three.js.math.Color;

class FogExp2 {
    public var isFogExp2:Bool = true;
    public var name:String = '';
    public var color:Color;
    public var density:Float;

    public function new(color:Color, ?density:Float = 0.00025) {
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