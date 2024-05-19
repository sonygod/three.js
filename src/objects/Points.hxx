import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.core.Object3D;
import three.math.Vector3;
import three.materials.PointsMaterial;
import three.core.BufferGeometry;

class Points extends Object3D {

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

        this.material = if (Std.is(source.material, Array)) Std.arrayCopy(source.material) else source.material;
        this.geometry = source.geometry;

        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<Intersection>) {
        var geometry:BufferGeometry = this.geometry;
        var matrixWorld:Matrix4 = this.matrixWorld;
        var threshold:Float = raycaster.params.Points.threshold;
        var drawRange:DrawRange = geometry.drawRange;

        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

        _sphere.copy(geometry.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        _sphere.radius += threshold;

        if (!raycaster.ray.intersectsSphere(_sphere)) return;

        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

        var localThreshold:Float = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
        var localThresholdSq:Float = localThreshold * localThreshold;

        var index:BufferAttribute = geometry.index;
        var attributes:Attributes = geometry.attributes;
        var positionAttribute:BufferAttribute = attributes.position;

        if (index != null) {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(index.count, (drawRange.start + drawRange.count));

            for (i in start...end) {
                var a:Int = index.getX(i);

                _position.fromBufferAttribute(positionAttribute, a);

                testPoint(_position, a, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        } else {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(positionAttribute.count, (drawRange.start + drawRange.count));

            for (i in start...end) {
                _position.fromBufferAttribute(positionAttribute, i);

                testPoint(_position, i, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        }
    }

    public function updateMorphTargets() {
        var geometry:BufferGeometry = this.geometry;

        var morphAttributes:MorphAttributes = geometry.morphAttributes;
        var keys:Array<String> = Reflect.fields(morphAttributes);

        if (keys.length > 0) {
            var morphAttribute:Array<MorphAttribute> = morphAttributes[keys[0]];

            if (morphAttribute != null) {
                this.morphTargetInfluences = [];
                this.morphTargetDictionary = {};

                for (m in 0...morphAttribute.length) {
                    var name:String = morphAttribute[m].name || String(m);

                    this.morphTargetInfluences.push(0);
                    this.morphTargetDictionary[name] = m;
                }
            }
        }
    }

    static function testPoint(point:Vector3, index:Int, localThresholdSq:Float, matrixWorld:Matrix4, raycaster:Raycaster, intersects:Array<Intersection>, object:Points) {
        var rayPointDistanceSq:Float = _ray.distanceSqToPoint(point);

        if (rayPointDistanceSq < localThresholdSq) {
            var intersectPoint:Vector3 = new Vector3();

            _ray.closestPointToPoint(point, intersectPoint);
            intersectPoint.applyMatrix4(matrixWorld);

            var distance:Float = raycaster.ray.origin.distanceTo(intersectPoint);

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