package three.objects;

import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.core.Object3D;
import three.math.Vector3;
import three.materials.PointsMaterial;
import three.core.BufferGeometry;

class Points extends Object3D {

    public var isPoints:Bool = true;
    public var type:String = 'Points';

    public var geometry:BufferGeometry;
    public var material:PointsMaterial;

    public function new(?geometry:BufferGeometry, ?material:PointsMaterial) {
        super();
        this.geometry = geometry != null ? geometry : new BufferGeometry();
        this.material = material != null ? material : new PointsMaterial();
        updateMorphTargets();
    }

    override public function copy(source:Object3D, recursive:Bool):Object3D {
        super.copy(source, recursive);
        material = (source.material is Array) ? cast(source.material, Array<Dynamic>).copy() : source.material;
        geometry = source.geometry;
        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<RaycasterIntersection>) {
        var geometry:BufferGeometry = this.geometry;
        var matrixWorld:Matrix4 = this.matrixWorld;
        var threshold:Float = raycaster.params.Points.threshold;
        var drawRange:Dynamic = geometry.drawRange;

        // Checking boundingSphere distance to ray

        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

        _sphere.copy(geometry.boundingSphere).applyMatrix4(matrixWorld);
        _sphere.radius += threshold;

        if (!_ray.intersectsSphere(_sphere)) return;

        //

        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

        var localThreshold:Float = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
        var localThresholdSq:Float = localThreshold * localThreshold;

        var index:Array<Int> = geometry.index;
        var attributes:Dynamic = geometry.attributes;
        var positionAttribute:Dynamic = attributes.position;

        if (index != null) {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(index.length, drawRange.start + drawRange.count);

            for (i in start...end) {
                var a:Int = index[i];

                _position.fromBufferAttribute(positionAttribute, a);

                testPoint(_position, a, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }

        } else {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(positionAttribute.count, drawRange.start + drawRange.count);

            for (i in start...end) {
                _position.fromBufferAttribute(positionAttribute, i);

                testPoint(_position, i, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        }
    }

    public function updateMorphTargets() {
        var geometry:BufferGeometry = this.geometry;

        var morphAttributes:Dynamic = geometry.morphAttributes;
        var keys:Array<String> = Reflect.fields(morphAttributes);

        if (keys.length > 0) {
            var morphAttribute:Dynamic = morphAttributes[keys[0]];

            if (morphAttribute != null) {
                morphTargetInfluences = [];
                morphTargetDictionary = {};

                for (m in 0...morphAttribute.length) {
                    var name:String = morphAttribute[m].name != null ? morphAttribute[m].name : Std.string(m);

                    morphTargetInfluences.push(0);
                    morphTargetDictionary[name] = m;
                }
            }
        }
    }

    static var _inverseMatrix:Matrix4 = new Matrix4();
    static var _ray:Ray = new Ray();
    static var _sphere:Sphere = new Sphere();
    static var _position:Vector3 = new Vector3();

    static function testPoint(point:Vector3, index:Int, localThresholdSq:Float, matrixWorld:Matrix4, raycaster:Raycaster, intersects:Array<RaycasterIntersection>, object:Object3D) {
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