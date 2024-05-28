import Path from Path;
import MathUtils from MathUtils;

class Shape extends Path {
    public var uuid:String;
    public var type:String;
    public var holes:Array<Path>;

    public function new(points:Array<Float>) {
        super(points);
        this.uuid = MathUtils.generateUUID();
        this.type = 'Shape';
        this.holes = [];
    }

    public function getPointsHoles(divisions:Int):Array<Float> {
        var holesPts:Array<Float> = [];
        for (hole in holes) {
            holesPts.push(hole.getPoints(divisions));
        }
        return holesPts;
    }

    public function extractPoints(divisions:Int):Void {
        return {
            shape: this.getPoints(divisions),
            holes: this.getPointsHoles(divisions)
        };
    }

    public function copy(source:Shape):Shape {
        super.copy(source);
        this.holes = [];
        for (hole in source.holes) {
            this.holes.push(hole.clone());
        }
        return this;
    }

    public function toJSON():Object {
        var data = super.toJSON();
        data.uuid = this.uuid;
        data.holes = [];
        for (hole in this.holes) {
            data.holes.push(hole.toJSON());
        }
        return data;
    }

    public function fromJSON(json:Object):Shape {
        super.fromJSON(json);
        this.uuid = json.uuid;
        this.holes = [];
        for (hole in json.holes) {
            this.holes.push(new Path().fromJSON(hole));
        }
        return this;
    }
}

export { Shape };