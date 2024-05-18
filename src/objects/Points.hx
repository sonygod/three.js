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
        material = (source.material is Array) ? cast source.material.copy() : source.material;
        geometry = source.geometry;
        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<Intersection>) {
        var geometry:BufferGeometry = this.geometry;
        var matrixWorld:Matrix4 = this.matrixWorld;
        var threshold:Float = raycaster.params.Points.threshold;
        var drawRange:DrawRange = geometry.drawRange;

        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

        var sphere:Sphere = geometry.boundingSphere.clone();
        sphere.applyMatrix4(matrixWorld);
        sphere.radius += threshold;

        if (!raycaster.ray.intersectsSphere(sphere)) return;

        var inverseMatrix:Matrix4 = matrixWorld.clone().invert();
        var ray:Ray = raycaster.ray.clone().applyMatrix4(inverseMatrix);

        var localThreshold:Float = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
        var localThresholdSq:Float = localThreshold * localThreshold;

        var index:Array<Int> = geometry.index;
        var attributes:Array<BufferAttribute> = geometry.attributes;
        var positionAttribute:BufferAttribute = attributes.get('position');

        if (index != null) {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(index.length, drawRange.start + drawRange.count);

            for (i in start...end) {
                var a:Int = index[i];
                var position:Vector3 = positionAttribute.getX(a);
                testPoint(position, a, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        } else {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(positionAttribute.count, drawRange.start + drawRange.count);

            for (i in start...end) {
                var position:Vector3 = positionAttribute.getX(i);
                testPoint(position, i, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        }
    }

    private function updateMorphTargets() {
        var geometry:BufferGeometry = this.geometry;
        var morphAttributes:Array<MorphAttribute> = geometry.morphAttributes;
        var keys:Array<String> = [for (key in morphAttributes.keys()) key];

        if (keys.length > 0) {
            var morphAttribute:MorphAttribute = morphAttributes.get(keys[0]);

            if (morphAttribute != null) {
                morphTargetInfluences = [];
                morphTargetDictionary = {};

                for (m in 0...morphAttribute.length) {
                    var name:String = morphAttribute[m].name != null ? morphAttribute[m].name : Std.string(m);
                    morphTargetInfluences.push(0);
                    morphTargetDictionary.set(name, m);
                }
            }
        }
    }

    private function testPoint(point:Vector3, index:Int, localThresholdSq:Float, matrixWorld:Matrix4, raycaster:Raycaster, intersects:Array<Intersection>, object:Object3D) {
        var rayPointDistanceSq:Float = _ray.distanceSqToPoint(point);

        if (rayPointDistanceSq < localThresholdSq) {
            var intersectPoint:Vector3 = _ray.closestPointToPoint(point);
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

    static var _inverseMatrix:Matrix4 = new Matrix4();
    static var _ray:Ray = new Ray();
    static var _sphere:Sphere = new Sphere();
    static var _position:Vector3 = new Vector3();
}