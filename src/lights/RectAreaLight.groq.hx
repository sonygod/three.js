package three.js.src.lights;

import three.js.src.lights.Light;

class RectAreaLight extends Light {
    public var isRectAreaLight:Bool = true;
    public var type:String = 'RectAreaLight';
    public var width:Float;
    public var height:Float;

    public function new(color:Int, intensity:Float, width:Float = 10, height:Float = 10) {
        super(color, intensity);
        this.width = width;
        this.height = height;
    }

    private var _power:Float;
    public var power(get, set):Float;

    private function get_power():Float {
        return intensity * width * height * Math.PI;
    }

    private function set_power(power:Float):Float {
        intensity = power / (width * height * Math.PI);
        return power;
    }

    public function copy(source:RectAreaLight):RectAreaLight {
        super.copy(source);
        width = source.width;
        height = source.height;
        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);
        data.object.width = width;
        data.object.height = height;
        return data;
    }
}