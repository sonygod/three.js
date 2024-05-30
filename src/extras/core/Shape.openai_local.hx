import threejs.extras.core.Path;
import threejs.math.MathUtils;

class Shape extends Path {
    
    public var uuid:String;
    public var holes:Array<Path>;
    
    public function new(points:Array<Dynamic>) {
        super(points);
        this.uuid = MathUtils.generateUUID();
        this.type = 'Shape';
        this.holes = [];
    }
    
    public function getPointsHoles(divisions:Int):Array<Array<Dynamic>> {
        var holesPts:Array<Array<Dynamic>> = [];
        for (i in 0...this.holes.length) {
            holesPts.push(this.holes[i].getPoints(divisions));
        }
        return holesPts;
    }
    
    public function extractPoints(divisions:Int):Dynamic {
        return {
            shape: this.getPoints(divisions),
            holes: this.getPointsHoles(divisions)
        };
    }
    
    public function copy(source:Shape):Shape {
        super.copy(source);
        this.holes = [];
        for (i in 0...source.holes.length) {
            var hole = source.holes[i];
            this.holes.push(hole.clone());
        }
        return this;
    }
    
    public function toJSON():Dynamic {
        var data = super.toJSON();
        data.uuid = this.uuid;
        data.holes = [];
        for (i in 0...this.holes.length) {
            var hole = this.holes[i];
            data.holes.push(hole.toJSON());
        }
        return data;
    }
    
    public function fromJSON(json:Dynamic):Shape {
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