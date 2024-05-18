package three.lights;;

import three.core.Object3D;
import three.math.Color;
import three.lights.Light;

class HemisphereLight extends Light {

    public var isHemisphereLight:Bool = true;
    public var type:String = 'HemisphereLight';
    public var groundColor:Color;

    public function new(skyColor:Color, groundColor:Color, intensity:Float) {
        super(skyColor, intensity);

        this.position.copyFrom(Object3D.DEFAULT_UP);
        updateMatrix();

        this.groundColor = new Color(groundColor);
    }

    override public function copy(source:HemisphereLight, recursive:Bool = false):HemisphereLight {
        super.copy(source, recursive);

        groundColor.copyFrom(source.groundColor);

        return this;
    }
}