import three.lights.SpotLight;

class IESSpotLight extends SpotLight {

    public var iesMap:Null<Dynamic>;

    public function new(color:Dynamic, intensity:Dynamic, distance:Dynamic, angle:Dynamic, penumbra:Dynamic, decay:Dynamic) {
        super(color, intensity, distance, angle, penumbra, decay);
        iesMap = null;
    }

    public function copy(source:IESSpotLight, recursive:Bool):IESSpotLight {
        super.copy(source, recursive);
        iesMap = source.iesMap;
        return this;
    }

}