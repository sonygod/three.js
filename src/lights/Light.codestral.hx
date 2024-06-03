import three.core.Object3D;
import three.math.Color;

class Light extends Object3D {

    public var color: Color;
    public var intensity: Float;
    public var groundColor: Null<Color>;
    public var distance: Null<Float>;
    public var angle: Null<Float>;
    public var decay: Null<Float>;
    public var penumbra: Null<Float>;
    public var shadow: Null<Object>; // assuming the 'shadow' object has a 'toJSON' method

    public function new(color: Int, intensity: Float = 1) {
        super();

        this.isLight = true;

        this.type = 'Light';

        this.color = new Color(color);
        this.intensity = intensity;

        this.groundColor = null;
        this.distance = null;
        this.angle = null;
        this.decay = null;
        this.penumbra = null;
        this.shadow = null;
    }

    public function dispose() {
        // Empty here in base class; some subclasses override.
    }

    @Override
    public function copy(source: Light, recursive: Bool): Light {
        super.copy(source, recursive);

        this.color.copy(source.color);
        this.intensity = source.intensity;

        return this;
    }

    @Override
    public function toJSON(meta: Object): Object {
        var data = super.toJSON(meta);

        data.object.color = this.color.getHex();
        data.object.intensity = this.intensity;

        if (this.groundColor != null) data.object.groundColor = this.groundColor.getHex();

        if (this.distance != null) data.object.distance = this.distance;
        if (this.angle != null) data.object.angle = this.angle;
        if (this.decay != null) data.object.decay = this.decay;
        if (this.penumbra != null) data.object.penumbra = this.penumbra;

        if (this.shadow != null) data.object.shadow = this.shadow.toJSON();

        return data;
    }
}