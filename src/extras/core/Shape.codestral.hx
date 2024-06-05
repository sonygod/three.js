import three.math.MathUtils;
import three.extras.core.Path;

class Shape extends Path {
  public var uuid: String;
  public var type: String = "Shape";
  public var holes: Array<Path> = [];

  public function new(points: Array<Float>) {
    super(points);
    this.uuid = MathUtils.generateUUID();
  }

  public function getPointsHoles(divisions: Int): Array<Array<Float>> {
    var holesPts: Array<Array<Float>> = [];
    for (i in 0...this.holes.length) {
      holesPts[i] = this.holes[i].getPoints(divisions);
    }
    return holesPts;
  }

  public function extractPoints(divisions: Int): Dynamic {
    return {
      shape: this.getPoints(divisions),
      holes: this.getPointsHoles(divisions)
    };
  }

  public function copy(source: Shape): Shape {
    super.copy(source);
    this.holes = [];
    for (i in 0...source.holes.length) {
      var hole = source.holes[i];
      this.holes.push(hole.clone());
    }
    return this;
  }

  public function toJSON(): Dynamic {
    var data = super.toJSON();
    data.uuid = this.uuid;
    data.holes = [];
    for (i in 0...this.holes.length) {
      var hole = this.holes[i];
      data.holes.push(hole.toJSON());
    }
    return data;
  }

  public function fromJSON(json: Dynamic): Shape {
    super.fromJSON(json);
    this.uuid = json.uuid;
    this.holes = [];
    for (i in 0...json.holes.length) {
      var hole = json.holes[i];
      this.holes.push(new Path().fromJSON(hole));
    }
    return this;
  }
}