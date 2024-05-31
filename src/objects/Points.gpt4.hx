import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.core.Object3D;
import three.math.Vector3;
import three.materials.PointsMaterial;
import three.core.BufferGeometry;

class Points extends Object3D {

    public var isPoints:Bool;
    public var type:String;
    public var geometry:BufferGeometry;
    public var material:PointsMaterial;

    static var _inverseMatrix:Matrix4 = new Matrix4();
    static var _ray:Ray = new Ray();
    static var _sphere:Sphere = new Sphere();
    static var _position:Vector3 = new Vector3();

    public function new(geometry:BufferGeometry = new BufferGeometry(), material:PointsMaterial = new PointsMaterial()) {
        super();
        this.isPoints = true;
        this.type = 'Points';
        this.geometry = geometry;
        this.material = material;
        this.updateMorphTargets();
    }

    public function copy(source:Points, recursive:Bool):Points {
        super.copy(source, recursive);
        this.material = (Std.is(source.material, Array)) ? (source.material:Dynamic).copy() : source.material;
        this.geometry = source.geometry;
        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<Dynamic>):Void {
        var geometry = this.geometry;
        var matrixWorld = this.matrixWorld;
        var threshold = raycaster.params.Points.threshold;
        var drawRange = geometry.drawRange;

        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

        _sphere.copy(geometry.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        _sphere.radius += threshold;

        if (!_ray.intersectsSphere(_sphere)) return;

        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

        var localThreshold = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
        var localThresholdSq = localThreshold * localThreshold;

        var index = geometry.index;
        var attributes = geometry.attributes;
        var positionAttribute = attributes.position;

        if (index != null) {
            var start = Math.max(0, drawRange.start);
            var end = Math.min(index.count, (drawRange.start + drawRange.count));
            for (i in start...end) {
                var a = index.getX(i);
                _position.fromBufferAttribute(positionAttribute, a);
                testPoint(_position, a, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        } else {
            var start = Math.max(0, drawRange.start);
            var end = Math.min(positionAttribute.count, (drawRange.start + drawRange.count));
            for (i in start...end) {
                _position.fromBufferAttribute(positionAttribute, i);
                testPoint(_position, i, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        }
    }

    public function updateMorphTargets():Void {
        var geometry = this.geometry;
        var morphAttributes = geometry.morphAttributes;
        var keys = Reflect.fields(morphAttributes);

        if (keys.length > 0) {
            var morphAttribute = Reflect.field(morphAttributes, keys[0]);
            if (morphAttribute != null) {
                this.morphTargetInfluences = [];
                this.morphTargetDictionary = {};

                for (m in 0...morphAttribute.length) {
                    var name = morphAttribute[m].name != null ? morphAttribute[m].name : Std.string(m);
                    this.morphTargetInfluences.push(0);
                    this.morphTargetDictionary[name] = m;
                }
            }
        }
    }

    static function testPoint(point:Vector3, index:Int, localThresholdSq:Float, matrixWorld:Matrix4, raycaster:Raycaster, intersects:Array<Dynamic>, object:Points):Void {
        var rayPointDistanceSq = _ray.distanceSqToPoint(point);
        if (rayPointDistanceSq < localThresholdSq) {
            var intersectPoint = new Vector3();
            _ray.closestPointToPoint(point, intersectPoint);
            intersectPoint.applyMatrix4(matrixWorld);
            var distance = raycaster.ray.origin.distanceTo(intersectPoint);
            if (distance < raycaster.near || distance > raycaster.far) return;
            intersects.push({
                distance: distance,
                distanceToRay: Math.sqrt(rayPointDistanceSq),
                point: intersectPoint,
                index: index,
                face: null,
                object: object
            });
        }
    }
}