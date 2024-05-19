import math.Vector3;
import core.Curve;
import math.CubicPoly;

class CatmullRomCurve3 extends Curve {
    public var points:Array<Vector3>;
    public var closed:Bool;
    public var curveType:String;
    public var tension:Float;
    
    public function new(points:Array<Vector3> = [], closed:Bool = false, curveType:String = "centripetal", tension:Float = 0.5) {
        super();
        
        this.isCatmullRomCurve3 = true;
        this.type = "CatmullRomCurve3";
        this.points = points;
        this.closed = closed;
        this.curveType = curveType;
        this.tension = tension;
    }
    
    public override function getPoint(t:Float, optionalTarget:Vector3 = null):Vector3 {
        var point:Vector3 = optionalTarget != null? optionalTarget: new Vector3();
        var l:Int = points.length;
        var p:Float = (l - (closed ? 0 : 1)) * t;
        var intPoint:Int = Math.floor(p);
        var weight:Float = p - intPoint;
        
        if (closed) {
            var offset:Int = intPoint > 0 ? 0 : (Math.floor(Math.abs(intPoint) / l) + 1) * l;
            intPoint += offset;
        } else if (weight === 0 && intPoint === l - 1) {
            intPoint = l - 2;
            weight = 1;
        }
        
        var p0:Vector3;
        var p3:Vector3;
        
        if (closed || intPoint > 0) {
            p0 = points[(intPoint - 1) % l];
        } else {
            tmp.subVectors(points[0], points[1]).add(points[0]);
            p0 = tmp;
        }
        
        var p1:Vector3 = points[intPoint % l];
        var p2:Vector3 = points[(intPoint + 1) % l];
        
        if (closed || intPoint + 2 < l) {
            p3 = points[(intPoint + 2) % l];
        } else {
            tmp.subVectors(points[l - 1], points[l - 2]).add(points[l - 1]);
            p3 = tmp;
        }
        
        var px:CubicPoly = new CubicPoly();
        var py:CubicPoly = new CubicPoly();
        var pz:CubicPoly = new CubicPoly();
        
        if (curveType === "centripetal" || curveType === "chordal") {
            var pow:Float = (curveType === "chordal") ? 0.5 : 0.25;
            var dt0:Float = Math.pow(p0.distanceToSquared(p1), pow);
            var dt1:Float = Math.pow(p1.distanceToSquared(p2), pow);
            var dt2:Float = Math.pow(p2.distanceToSquared(p3), pow);
            
            if (dt1 < 1e-4) dt1 = 1.0;
            if (dt0 < 1e-4) dt0 = dt1;
            if (dt2 < 1e-4) dt2 = dt1;
            
            px.initNonuniformCatmullRom(p0.x, p1.x, p2.x, p3.x, dt0, dt1, dt2);
            py.initNonuniformCatmullRom(p0.y, p1.y, p2.y, p3.y, dt0, dt1, dt2);
            pz.initNonuniformCatmullRom(p0.z, p1.z, p2.z, p3.z, dt0, dt1, dt2);
        } else if (curveType === "catmullrom") {
            px.initCatmullRom(p0.x, p1.x, p2.x, p3.x, tension);
            py.initCatmullRom(p0.y, p1.y, p2.y, p3.y, tension);
            pz.initCatmullRom(p0.z, p1.z, p2.z, p3.z, tension);
        }
        
        point.set(px.calc(weight), py.calc(weight), pz.calc(weight));
        return point;
    }
    
    public function copy(source:CatmullRomCurve3):CatmullRomCurve3 {
        super.copy(source);
        this.points = [];
        
        for (point in source.points) {
            this.points.push(point.clone());
        }
        
        this.closed = source.closed;
        this.curveType = source.curveType;
        this.tension = source.tension;
        return this;
    }
    
    public function toJSON():Dynamic {
        var data:Dynamic = super.toJSON();
        data.points = [];
        
        for (point in this.points) {
            data.points.push(point.toArray());
        }
        
        data.closed = this.closed;
        data.curveType = this.curveType;
        data.tension = this.tension;
        return data;
    }
    
    public function fromJSON(json:Dynamic):CatmullRomCurve3 {
        super.fromJSON(json);
        this.points = [];
        
        for (point in json.points) {
            this.points.push(new Vector3().fromArray(point));
        }
        
        this.closed = json.closed;
        this.curveType = json.curveType;
        this.tension = json.tension;
        return this;
    }
}