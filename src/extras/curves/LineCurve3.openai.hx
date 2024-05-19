import three.math.Vector3;
import three.core.Curve;

class LineCurve3 extends Curve {

    public var v1:Vector3;
    public var v2:Vector3;

    public function new(v1:Vector3 = null, v2:Vector3 = null) {
        
        super();
        
        if (v1 == null) v1 = new Vector3();
        if (v2 == null) v2 = new Vector3();
        
        this.isLineCurve3 = true;
        this.type = "LineCurve3";
        
        this.v1 = v1;
        this.v2 = v2;
        
    }
    
    public override function getPoint(t:Float, ?optionalTarget:Vector3 = null):Vector3 {
        
        var point:Vector3 = (optionalTarget == null) ? new Vector3() : optionalTarget;
        
        if (t == 1) {
            
            point.copy(this.v2);
            
        } else {
            
            point.copy(this.v2).sub(this.v1);
            point.multiplyScalar(t).add(this.v1);
            
        }
        
        return point;
        
    }
    
    override public function getPointAt(u:Float, ?optionalTarget:Vector3 = null):Vector3 {
        
        return getPoint(u, optionalTarget);
        
    }
    
    public override function getTangent(t:Float, ?optionalTarget:Vector3 = null):Vector3 {
        
        var tangent:Vector3 = (optionalTarget == null) ? new Vector3() : optionalTarget;
        
        return tangent.subVectors(this.v2, this.v1).normalize();
        
    }
    
    override public function getTangentAt(u:Float, ?optionalTarget:Vector3 = null):Vector3 {
        
        return getTangent(u, optionalTarget);
        
    }
    
    public override function copy(source:LineCurve3):LineCurve3 {
        
        super.copy(source);
        
        this.v1.copy(source.v1);
        this.v2.copy(source.v2);
        
        return this;
        
    }
    
    public override function toJSON():Dynamic {
        
        var data:Dynamic = super.toJSON();
        
        data.v1 = this.v1.toArray();
        data.v2 = this.v2.toArray();
        
        return data;
        
    }
    
    public override function fromJSON(json:Dynamic):LineCurve3 {
        
        super.fromJSON(json);
        
        this.v1.fromArray(json.v1);
        this.v2.fromArray(json.v2);
        
        return this;
        
    }
    
}