package three.js.src.lights;

import three.js.src.lights.Light;

class AmbientLight extends Light {
    public var isAmbientLight:Bool = true;
    public var type:String = 'AmbientLight';

    public function new(color:Int, intensity:Float) {
        super(color, intensity);
    }
}