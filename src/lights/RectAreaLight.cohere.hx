import Light from Light;

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

    public function get_power():Float {
        return this.intensity * this.width * this.height * Math.PI;
    }

    public function set_power(power:Float) {
        this.intensity = power / (this.width * this.height * Math.PI);
    }

    public function copy(source:RectAreaLight):Void {
        super.copy(source);
        this.width = source.width;
        this.height = source.height;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);
        data.object.width = this.width;
        data.object.height = this.height;
        return data;
    }
}