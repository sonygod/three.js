import three.lights.SpotLight;

class IESSpotLight extends SpotLight {
    public var iesMap: Null<Texture> = null;

    public function new(color: Int, intensity: Float, distance: Float, angle: Float, penumbra: Float, decay: Float) {
        super(color, intensity, distance, angle, penumbra, decay);
    }

    public override function copy(source: SpotLight, recursive: Bool): SpotLight {
        super.copy(source, recursive);

        this.iesMap = (source as IESSpotLight).iesMap;

        return this;
    }
}

// In Haxe, the equivalent of the default export is to have the class definition in a public package
// or to manually instantiate and use the class in your main entry point.