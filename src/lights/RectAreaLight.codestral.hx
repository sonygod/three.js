import three.lights.Light;

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

    public function get_power():Float {
        return this.intensity * this.width * this.height * Math.PI;
    }

    public function set_power(power:Float):Void {
        this.intensity = power / ( this.width * this.height * Math.PI );
    }

    override public function copy(source:RectAreaLight):RectAreaLight {

        super.copy(source);

        this.width = source.width;
        this.height = source.height;

        return this;

    }

    override public function toJSON(meta:Dynamic):Dynamic {

        var data = super.toJSON(meta);

        data.object.width = this.width;
        data.object.height = this.height;

        return data;

    }

}