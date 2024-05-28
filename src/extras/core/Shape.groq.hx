package three.js.src.extras.core;

import three.js.src.extras.core.Path;
import three.js.src.math.MathUtils;

class Shape extends Path {
    public var uuid:String;
    public var type:String;
    public var holes:Array<Path>;

    public function new(points:Array<Dynamic>) {
        super(points);
        uuid = MathUtils.generateUUID();
        type = 'Shape';
        holes = [];
    }

    public function getPointsHoles(divisions:Int):Array<Array<Dynamic>> {
        var holesPts:Array<Array<Dynamic>> = [];
        for (i in 0...holes.length) {
            holesPts[i] = holes[i].getPoints(divisions);
        }
        return holesPts;
    }

    public function extractPoints(divisions:Int):{ shape:Array<Dynamic>, holes:Array<Array<Dynamic>> } {
        return {
            shape: getPoints(divisions),
            holes: getPointsHoles(divisions)
        };
    }

    public function copy(source:Shape):Shape {
        super.copy(source);
        holes = [];
        for (i in 0...source.holes.length) {
            var hole:Path = source.holes[i];
            holes.push(hole.clone());
        }
        return this;
    }

    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        data.uuid = uuid;
        data.holes = [];
        for (i in 0...holes.length) {
            var hole:Path = holes[i];
            data.holes.push(hole.toJSON());
        }
        return data;
    }

    public function fromJSON(json:Dynamic):Shape {
        super.fromJSON(json);
        uuid = json.uuid;
        holes = [];
        for (i in 0...json.holes.length) {
            var hole:Dynamic = json.holes[i];
            holes.push(new Path().fromJSON(hole));
        }
        return this;
    }
}