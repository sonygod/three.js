package extras.core;

import path.Path;
import math.MathUtils;

class Shape extends Path {

	public var uuid:String;
	public var holes:Array<Path>;

	public function new(points:Array<Float>) {
		super(points);

		this.uuid = MathUtils.generateUUID();
		this.type = "Shape";
		this.holes = new Array<Path>();
	}

	public function getPointsHoles(divisions:Int):Array<Array<Float>> {
		var holesPts:Array<Array<Float>> = [];

		for (i in 0...this.holes.length) {
			holesPts[i] = this.holes[i].getPoints(divisions);
		}

		return holesPts;
	}

	public function extractPoints(divisions:Int):{shape:Array<Float>, holes:Array<Array<Float>>} {
		return {
			shape: this.getPoints(divisions),
			holes: this.getPointsHoles(divisions)
		};
	}

	public function copy(source:Shape):Shape {
		super.copy(source);

		this.holes = [];

		for (i in 0...source.holes.length) {
			var hole:Path = source.holes[i];
			this.holes.push(hole.clone());
		}

		return this;
	}

	public function toJSON():Dynamic {
		var data:Dynamic = super.toJSON();

		data.uuid = this.uuid;
		data.holes = [];

		for (i in 0...this.holes.length) {
			var hole:Path = this.holes[i];
			data.holes.push(hole.toJSON());
		}

		return data;
	}

	public function fromJSON(json:Dynamic):Shape {
		super.fromJSON(json);

		this.uuid = json.uuid;
		this.holes = [];

		for (i in 0...json.holes.length) {
			var hole:Dynamic = json.holes[i];
			this.holes.push(new Path().fromJSON(hole));
		}

		return this;
	}

}

class MathUtils {
	public static function generateUUID():String {
		// implementation goes here
	}
}

class Path {
	// implementation goes here
}