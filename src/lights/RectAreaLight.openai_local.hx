import three.lights.Light;

class RectAreaLight extends Light {

    public var isRectAreaLight:Bool = true;
    public var type:String = "RectAreaLight";
    public var width:Float;
    public var height:Float;

    public function new(color:Int, intensity:Float, width:Float = 10, height:Float = 10) {
        super(color, intensity);
        this.width = width;
        this.height = height;
    }

    public function get power():Float {
        // compute the light's luminous power (in lumens) from its intensity (in nits)
        return this.intensity * this.width * this.height * Math.PI;
    }

    public function set power(value:Float):Void {
        // set the light's intensity (in nits) from the desired luminous power (in lumens)
        this.intensity = value / (this.width * this.height * Math.PI);
    }

    public function copy(source:RectAreaLight):RectAreaLight {
        super.copy(source);
        this.width = source.width;
        this.height = source.height;
        return this;
    }

    public function toJSON(meta:Dynamic = null):Dynamic {
        var data = super.toJSON(meta);
        data.object.width = this.width;
        data.object.height = this.height;
        return data;
    }

}