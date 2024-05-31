import three.lights.Light;

class RectAreaLight extends Light {

    public var isRectAreaLight:Bool = true;
    public var width:Float;
    public var height:Float;

    public function new(color:Int, intensity:Float, ?width:Float = 10, ?height:Float = 10) {
        super(color, intensity);
        this.width = width;
        this.height = height;
        this.type = 'RectAreaLight';
    }

    public function get_power():Float {
        // compute the light's luminous power (in lumens) from its intensity (in nits)
        return this.intensity * this.width * this.height * Math.PI;
    }

    public function set_power(power:Float):Float {
        // set the light's intensity (in nits) from the desired luminous power (in lumens)
        this.intensity = power / (this.width * this.height * Math.PI);
        return power;
    }

    public override function copy(source:Light):Light {
        super.copy(source);
        if (Std.is(source, RectAreaLight)) {
            var rectAreaLightSource:RectAreaLight = cast(source, RectAreaLight);
            this.width = rectAreaLightSource.width;
            this.height = rectAreaLightSource.height;
        }
        return this;
    }

    public override function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);
        data.object.width = this.width;
        data.object.height = this.height;
        return data;
    }

}