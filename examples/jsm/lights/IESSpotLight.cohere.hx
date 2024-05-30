class IESSpotLight extends SpotLight {
    public var iesMap:Null<IESLight> = null;

    public function new(color:Int, intensity:Float, distance:Float, angle:Float, penumbra:Float, decay:Float) {
        super(color, intensity, distance, angle, penumbra, decay);
    }

    public function copy(source:SpotLight, recursive:Bool):IESSpotLight {
        super.copy(source, recursive);
        iesMap = source.iesMap;
        return this;
    }
}