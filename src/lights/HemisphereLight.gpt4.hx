import three.lights.Light;
import three.math.Color;
import three.core.Object3D;

class HemisphereLight extends Light {

    public var isHemisphereLight:Bool;
    public var groundColor:Color;

    public function new(skyColor:Dynamic, groundColor:Dynamic, intensity:Float = 1) {
        super(skyColor, intensity);

        this.isHemisphereLight = true;
        this.type = "HemisphereLight";
        this.position.copy(Object3D.DEFAULT_UP);
        this.updateMatrix();

        this.groundColor = new Color(groundColor);
    }

    public function copy(source:HemisphereLight, recursive:Bool = true):HemisphereLight {
        super.copy(source, recursive);
        this.groundColor.copy(source.groundColor);

        return this;
    }

    // Override the type field to provide type safety
    override public var type(get, never):String;
    private function get_type():String {
        return "HemisphereLight";
    }
}