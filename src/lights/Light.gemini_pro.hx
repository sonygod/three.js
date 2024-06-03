import three.core.Object3D;
import three.math.Color;

class Light extends Object3D {

	public var isLight:Bool = true;
	public var type:String = "Light";
	public var color:Color;
	public var intensity:Float;

	public function new(color:Color, intensity:Float = 1) {
		super();
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

	public function toJSON(meta:Dynamic):Dynamic {
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

	public var groundColor:Color;
	public var distance:Float;
	public var angle:Float;
	public var decay:Float;
	public var penumbra:Float;
	public var shadow:Dynamic;
}