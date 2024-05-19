import three.js.src.core.Object3D;
import three.js.src.math.Color;

class Light extends Object3D {

	public var isLight:Bool;
	public var type:String;
	public var color:Color;
	public var intensity:Float;

	public function new(color:Dynamic, intensity:Float = 1) {
		super();

		this.isLight = true;
		this.type = 'Light';
		this.color = new Color(color);
		this.intensity = intensity;
	}

	public function dispose():Void {
		// Empty here in base class; some subclasses override.
	}

	public function copy(source:Dynamic, recursive:Bool):Light {
		super.copy(source, recursive);

		this.color.copy(source.color);
		this.intensity = source.intensity;

		return this;
	}

	public function toJSON(meta:Dynamic):Dynamic {
		var data = super.toJSON(meta);

		data.object.color = this.color.getHex();
		data.object.intensity = this.intensity;

		if (this.groundColor !== undefined) data.object.groundColor = this.groundColor.getHex();

		if (this.distance !== undefined) data.object.distance = this.distance;
		if (this.angle !== undefined) data.object.angle = this.angle;
		if (this.decay !== undefined) data.object.decay = this.decay;
		if (this.penumbra !== undefined) data.object.penumbra = this.penumbra;

		if (this.shadow !== undefined) data.object.shadow = this.shadow.toJSON();

		return data;
	}
}