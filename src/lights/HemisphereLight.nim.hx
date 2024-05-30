import Light.Light;
import Color.Color;
import Object3D.Object3D;

class HemisphereLight extends Light {

    public var isHemisphereLight:Bool = true;
    public var type:String = 'HemisphereLight';
    public var groundColor:Color;

    public function new(skyColor:Color, groundColor:Color, intensity:Float) {
        super(skyColor, intensity);

        this.position.copy(Object3D.DEFAULT_UP);
        this.updateMatrix();

        this.groundColor = new Color(groundColor);
    }

    public function copy(source:Light, recursive:Bool):HemisphereLight {
        super.copy(source, recursive);

        this.groundColor.copy(source.groundColor);

        return this;
    }

}