package openfl.display3D;

import openfl.geom.Color3D;
import openfl.display3D.core.Object3D;

class Light extends Object3D {

	public var isLight:Bool = true;
	public var type:String = 'Light';
	public var color:Color3D;
	public var intensity:Float;

	public function new(color:Color3D, intensity:Float = 1) {
		super();
		this.color = color;
		this.intensity = intensity;
	}

	public function dispose():Void {
		// Empty here in base class; some subclasses override.
	}

	public function copy(source:Light, recursive:Bool):Light {
		super.copy(source, recursive);
		this.color = source.color;
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

}