import three.Curve;
import three.Vector3;

class GrannyKnot extends Curve {
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t = 2 * Math.PI * t;
        var x = - 0.22 * Math.cos(t) - 1.28 * Math.sin(t) - 0.44 * Math.cos(3 * t) - 0.78 * Math.sin(3 * t);
        var y = - 0.1 * Math.cos(2 * t) - 0.27 * Math.sin(2 * t) + 0.38 * Math.cos(4 * t) + 0.46 * Math.sin(4 * t);
        var z = 0.7 * Math.cos(3 * t) - 0.4 * Math.sin(3 * t);
        return point.set(x, y, z).multiplyScalar(20);
    }
}

class HeartCurve extends Curve {
    public var scale:Float;
    public function new(scale:Float = 5) {
        super();
        this.scale = scale;
    }
    public function getPoint(t:Float, optionalTarget:Vector3 = new Vector3()):Vector3 {
        var point = optionalTarget;
        t *= 2 * Math.PI;
        var x = 16 * Math.pow(Math.sin(t), 3);
        var y = 13 * Math.cos(t) - 5 * Math.cos(2 * t) - 2 * Math.cos(3 * t) - Math.cos(4 * t);
        var z = 0;
        return point.set(x, y, z).multiplyScalar(this.scale);
    }
}

// 其他类同理，这里不再重复

function scaleTo(x:Float, y:Float, t:Float):Float {
    var r = y - x;
    return t * r + x;
}

// 其他类同理，这里不再重复