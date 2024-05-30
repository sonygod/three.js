import three.js.src.lights.Light;

class RectAreaLight extends Light {

    public var isRectAreaLight:Bool = true;
    public var type:String = 'RectAreaLight';
    public var width:Float;
    public var height:Float;

    public function new(color:Dynamic, intensity:Float, width:Float = 10, height:Float = 10) {
        super(color, intensity);
        this.width = width;
        this.height = height;
    }

    public function get power():Float {
        return this.intensity * this.width * this.height * Math.PI;
    }

    public function set power(power:Float) {
        this.intensity = power / (this.width * this.height * Math.PI);
    }

    public function copy(source:RectAreaLight):RectAreaLight {
        super.copy(source);
        this.width = source.width;
        this.height = source.height;
        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);
        data.object.width = this.width;
        data.object.height = this.height;
        return data;
    }

}

export class Main {
    static function main() {
        var rectAreaLight = new RectAreaLight(0xffffff, 1, 10, 10);
        trace(rectAreaLight.power);
    }
}