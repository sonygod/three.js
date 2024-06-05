import three.math.Vector3;
import three.math.MathUtils;

class Line3 {
    var start:Vector3;
    var end:Vector3;

    public function new(start:Vector3 = null, end:Vector3 = null) {
        this.start = start != null ? start : new Vector3();
        this.end = end != null ? end : new Vector3();
    }

    public function set(start:Vector3, end:Vector3):Line3 {
        this.start.copy(start);
        this.end.copy(end);
        return this;
    }

    public function copy(line:Line3):Line3 {
        this.start.copy(line.start);
        this.end.copy(line.end);
        return this;
    }

    public function getCenter(target:Vector3):Vector3 {
        return target.addVectors(this.start, this.end).multiplyScalar(0.5);
    }

    public function delta(target:Vector3):Vector3 {
        return target.subVectors(this.end, this.start);
    }

    public function distanceSq():Float {
        return this.start.distanceToSquared(this.end);
    }

    public function distance():Float {
        return this.start.distanceTo(this.end);
    }

    public function at(t:Float, target:Vector3):Vector3 {
        return this.delta(target).multiplyScalar(t).add(this.start);
    }

    public function closestPointToPointParameter(point:Vector3, clampToLine:Bool):Float {
        var _startP = new Vector3().subVectors(point, this.start);
        var _startEnd = new Vector3().subVectors(this.end, this.start);

        var startEnd2 = _startEnd.dot(_startEnd);
        var startEnd_startP = _startEnd.dot(_startP);

        var t = startEnd_startP / startEnd2;

        if (clampToLine) {
            t = MathUtils.clamp(t, 0, 1);
        }

        return t;
    }

    public function closestPointToPoint(point:Vector3, clampToLine:Bool, target:Vector3):Vector3 {
        var t = this.closestPointToPointParameter(point, clampToLine);

        return this.delta(target).multiplyScalar(t).add(this.start);
    }

    public function applyMatrix4(matrix:Matrix4):Line3 {
        this.start.applyMatrix4(matrix);
        this.end.applyMatrix4(matrix);

        return this;
    }

    public function equals(line:Line3):Bool {
        return line.start.equals(this.start) && line.end.equals(this.end);
    }

    public function clone():Line3 {
        return new Line3().copy(this);
    }
}