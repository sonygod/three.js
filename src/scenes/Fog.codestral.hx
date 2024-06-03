import js.Browser.document;
import three.js.math.Color;

class Fog {
    public var isFog:Bool = true;
    public var name:String = "";
    public var color:Color;
    public var near:Float;
    public var far:Float;

    public function new(color:Int, ?near:Float, ?far:Float) {
        this.color = new Color(color);
        this.near = near != null ? near : 1.0;
        this.far = far != null ? far : 1000.0;
    }

    public function clone():Fog {
        return new Fog(this.color.getHex(), this.near, this.far);
    }

    public function toJSON():Dynamic {
        return {
            "type": "Fog",
            "name": this.name,
            "color": this.color.getHex(),
            "near": this.near,
            "far": this.far
        };
    }
}