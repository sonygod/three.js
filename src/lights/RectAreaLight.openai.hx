package three.js.src.lights;

import three.js.src.lights.Light;

class RectAreaLight extends Light {
    public var width:Float;
    public var height:Float;

    public function new(color:Int, intensity:Float, width:Float = 10, height:Float = 10) {
        super(color, intensity);

        this.isRectAreaLight = true;
        this.type = 'RectAreaLight';

        this.width = width;
        this.height = height;
    }

    private var _power:Float;
    public var power(get, set):Float;

    private function get_power():Float {
        return this.intensity * this.width * this.height * Math.PI;
    }

    private function set_power(power:Float):Float {
        this.intensity = power / (this.width * this.height * Math.PI);
        return power;
    }

    override public function copy(source:RectAreaLight):RectAreaLight {
        super.copy(source);

        this.width = source.width;
        this.height = source.height;

        return this;
    }

    override public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);

        data.object.width = this.width;
        data.object.height = this.height;

        return data;
    }
}