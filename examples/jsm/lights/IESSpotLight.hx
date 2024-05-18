package three.js.examples.javascript.lights;

import three.js.lights.SpotLight;

class IESSpotLight extends SpotLight {
    public var iesMap:Null<haxe.ds.Bytes>; // or haxe.ui.core.Image, depending on what iesMap should be

    public function new(color:UInt, intensity:Float, distance:Float, angle:Float, penumbra:Float, decay:Float) {
        super(color, intensity, distance, angle, penumbra, decay);
        this.iesMap = null;
    }

    public function copy(source:IESSpotLight, recursive:Bool = false):IESSpotLight {
        super.copy(source, recursive);
        this.iesMap = source.iesMap;
        return this;
    }
}