package three;

import three.lights.Light;
import three.math.Color;
import three.core.Object3D;

class HemisphereLight extends Light {

    public var isHemisphereLight:Bool = true;
    public var type:String = 'HemisphereLight';
    public var groundColor:Color;

    public function new(skyColor:Color, groundColor:Color, intensity:Float) {
        super(skyColor, intensity);
        this.groundColor = new Color(groundColor);
        this.position.copy(Object3D.DEFAULT_UP);
        this.updateMatrix();
    }

    override public function copy(source:HemisphereLight, recursive:Bool):HemisphereLight {
        super.copy(source, recursive);
        this.groundColor.copy(source.groundColor);
        return this;
    }
}