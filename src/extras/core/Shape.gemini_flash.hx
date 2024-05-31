import three.extras.core.Path;
import three.math.MathUtils;

class Shape extends Path {

	public var uuid:String;
	public var holes:Array<Path> = [];

	public function new(points:Array<three.math.Vector2>) {
		super(points);
		this.uuid = MathUtils.generateUUID();
		this.type = "Shape";
	}

	public function getPointsHoles(divisions:Int):Array<Array<three.math.Vector2>> {
		var holesPts:Array<Array<three.math.Vector2>> = [];
		for (i in 0...this.holes.length) {
			holesPts[i] = this.holes[i].getPoints(divisions);
		}
		return holesPts;
	}

	public function extractPoints(divisions:Int):{shape:Array<three.math.Vector2>, holes:Array<Array<three.math.Vector2>>} {
		return {
			shape: this.getPoints(divisions),
			holes: this.getPointsHoles(divisions)
		};
	}

	public function copy(source:Shape):Shape {
		super.copy(source);
		this.holes = [];
		for (i in 0...source.holes.length) {
			this.holes.push(source.holes[i].clone());
		}
		return this;
	}

	public function toJSON():Dynamic {
		var data = super.toJSON();
		data.uuid = this.uuid;
		data.holes = [];
		for (i in 0...this.holes.length) {
			data.holes.push(this.holes[i].toJSON());
		}
		return data;
	}

	public function fromJSON(json:Dynamic):Shape {
		super.fromJSON(json);
		this.uuid = json.uuid;
		this.holes = [];
		for (i in 0...json.holes.length) {
			this.holes.push(new Path().fromJSON(json.holes[i]));
		}
		return this;
	}
}