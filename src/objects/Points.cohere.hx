import js.Browser.window;
import js.three.BufferGeometry;
import js.three.Geometry;
import js.three.Material;
import js.three.Matrix4;
import js.three.Object3D;
import js.three.Points;
import js.three.PointsMaterial;
import js.three.Ray;
import js.three.Sphere;
import js.three.Vector3;

class Points extends Object3D {
    public var isPoints:Bool = true;
    public var type:String = "Points";
    public var geometry:BufferGeometry;
    public var material:Material;

    public function new(?geometry:BufferGeometry, ?material:Material) {
        super();
        this.geometry = geometry ?? new BufferGeometry();
        this.material = material ?? new PointsMaterial();
        this.updateMorphTargets();
    }

    public function copy(source:Points, recursive:Bool) {
        super.copy(source, recursive);
        this.material = if (source.material is Array) source.material.slice() else source.material;
        this.geometry = source.geometry;
        return this;
    }

    public function raycast(raycaster:Dynamic, intersects:Dynamic) {
        var geometry = this.geometry;
        var matrixWorld = this.matrixWorld;
        var threshold = raycaster.params.Points.threshold;
        var drawRange = geometry.drawRange;

        // Checking boundingSphere distance to ray
        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

        var sphere = geometry.boundingSphere.clone();
        sphere.applyMatrix4(matrixWorld);
        sphere.radius += threshold;

        if (!raycaster.ray.intersectsSphere(sphere)) return;

        var inverseMatrix = matrixWorld.clone().invert();
        var ray = raycaster.ray.clone().applyMatrix4(inverseMatrix);

        var localThreshold = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
        var localThresholdSq = localThreshold * localThreshold;

        var index = geometry.index;
        var attributes = geometry.attributes;
        var positionAttribute = attributes.position;

        if (index != null) {
            var start = max(0, drawRange.start);
            var end = min(index.count, (drawRange.start + drawRange.count));

            for (i in start...end) {
                var a = index.getX(i);
                var position = new Vector3().fromBufferAttribute(positionAttribute, a);
                testPoint(position, a, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        } else {
            var start = max(0, drawRange.start);
            var end = min(positionAttribute.count, (drawRange.start + drawRange.count));

            for (i in start...end) {
                var position = new Vector3().fromBufferAttribute(positionAttribute, i);
                testPoint(position, i, localThresholdSq, matrixWorld, raycaster, intersects, this);
            }
        }
    }

    public function updateMorphTargets() {
        var geometry = this.geometry;
        var morphAttributes = geometry.morphAttributes;
        var keys = Reflect.fields(morphAttributes);

        if (keys.length > 0) {
            var morphAttribute = morphAttributes[keys[0]];
            if (morphAttribute != null) {
                this.morphTargetInfluences = [];
                this.morphTargetDictionary = { };

                for (m in 0...morphAttribute.length) {
                    var name = morphAttribute[m].name ?? $m;
                    this.morphTargetInfluences.push(0);
                    this.morphTargetDictionary[name] = m;
                }
            }
        }
    }
}

function testPoint(point:Vector3, index:Int, localThresholdSq:Float, matrixWorld:Matrix4, raycaster:Dynamic, intersects:Dynamic, object:Dynamic) {
    var rayPointDistanceSq = ray.distanceSqToPoint(point);

    if (rayPointDistanceSq < localThresholdSq) {
        var intersectPoint = new Vector3();
        ray.closestPointToPoint(point, intersectPoint);
        intersectPoint.applyMatrix4(matrixWorld);

        var distance = ray.origin.distanceTo(intersectPoint);

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