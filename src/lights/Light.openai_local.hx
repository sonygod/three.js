package three.lights;

import three.core.Object3D;
import three.math.Color;

class Light extends Object3D {
    public var isLight:Bool;
    public var type:String;
    public var color:Color;
    public var intensity:Float;

    public function new(color:Dynamic, intensity:Float = 1) {
        super();
        this.isLight = true;
        this.type = "Light";
        this.color = new Color(color);
        this.intensity = intensity;
    }

    public function dispose():Void {
        // Empty here in base class; some subclasses override.
    }

    public function copy(source:Light, recursive:Bool):Light {
        super.copy(source, recursive);
        this.color.copy(source.color);
        this.intensity = source.intensity;
        return this;
    }

    public function toJSON(meta:Dynamic = null):Dynamic {
        var data = super.toJSON(meta);
        data.object.color = this.color.getHex();
        data.object.intensity = this.intensity;

        if (Reflect.hasField(this, "groundColor")) {
            data.object.groundColor = Reflect.field(this, "groundColor").getHex();
        }
        if (Reflect.hasField(this, "distance")) {
            data.object.distance = Reflect.field(this, "distance");
        }
        if (Reflect.hasField(this, "angle")) {
            data.object.angle = Reflect.field(this, "angle");
        }
        if (Reflect.hasField(this, "decay")) {
            data.object.decay = Reflect.field(this, "decay");
        }
        if (Reflect.hasField(this, "penumbra")) {
            data.object.penumbra = Reflect.field(this, "penumbra");
        }
        if (Reflect.hasField(this, "shadow")) {
            data.object.shadow = Reflect.field(this, "shadow").toJSON();
        }

        return data;
    }
}