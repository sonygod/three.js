import js.Browser.window;
import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.three.LineBasicMaterial;
import js.three.Matrix4;
import js.three.Object3D;
import js.three.Ray;
import js.three.Sphere;
import js.three.Vector3;

class Line extends Object3D {
    public var isLine:Bool = true;
    public var type:String = 'Line';
    public var geometry:BufferGeometry;
    public var material:LineBasicMaterial;

    public function new(geometry:BufferGeometry = new BufferGeometry(), material:LineBasicMaterial = new LineBasicMaterial()) {
        super();
        this.geometry = geometry;
        this.material = material;
        this.updateMorphTargets();
    }

    public function copy(source:Line, recursive:Bool) {
        super.copy(source, recursive);
        this.material = if (source.material is Array) source.material.slice() else source.material;
        this.geometry = source.geometry;
        return this;
    }

    public function computeLineDistances() {
        var geometry = this.geometry;
        if (geometry.index != null) {
            trace('THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
            return this;
        }

        var positionAttribute = geometry.attributes.position;
        var lineDistances = [0];

        var _vStart = new Vector3();
        var _vEnd = new Vector3();

        for (i in 1...positionAttribute.count) {
            _vStart.fromBufferAttribute(positionAttribute, i - 1);
            _vEnd.fromBufferAttribute(positionAttribute, i);

            lineDistances[i] = lineDistances[i - 1];
            lineDistances[i] += _vStart.distanceTo(_vEnd);
        }

        geometry.setAttribute('lineDistance', new BufferAttribute(lineDistances, 1));
        return this;
    }

    public function raycast(raycaster, intersects) {
        var geometry = this.geometry;
        var matrixWorld = this.matrixWorld;
        var threshold = raycaster.params.Line.threshold;
        var drawRange = geometry.drawRange;

        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

        var _sphere = new Sphere();
        _sphere.copy(geometry.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        _sphere.radius += threshold;

        if (!raycaster.ray.intersectsSphere(_sphere)) return;

        var _inverseMatrix = new Matrix4();
        var _ray = new Ray();
        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

        var localThreshold = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
        var localThresholdSq = localThreshold * localThreshold;

        var step = if (this.isLineSegments) 2 else 1;

        var index = geometry.index;
        var attributes = geometry.attributes;
        var positionAttribute = attributes.position;

        if (index != null) {
            var start = max(0, drawRange.start);
            var end = min(index.count, (drawRange.start + drawRange.count));

            for (i in start...end - 1) {
                if (i % step != 0) continue;

                var a = index.getX(i);
                var b = index.getX(i + 1);

                if (checkIntersection(this, raycaster, _ray, localThresholdSq, a, b)) {
                    intersects.push(true);
                }
            }

            if (this.isLineLoop) {
                var a = index.getX(end - 1);
                var b = index.getX(start);

                if (checkIntersection(this, raycaster, _ray, localThresholdSq, a, b)) {
                    intersects.push(true);
                }
            }
        } else {
            var start = max(0, drawRange.start);
            var end = min(positionAttribute.count, (drawRange.start + drawRange.count));

            for (i in start...end - 1) {
                if (i % step != 0) continue;

                if (checkIntersection(this, raycaster, _ray, localThresholdSq, i, i + 1)) {
                    intersects.push(true);
                }
            }

            if (this.isLineLoop) {
                if (checkIntersection(this, raycaster, _ray, localThresholdSq, end - 1, start)) {
                    intersects.push(true);
                }
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
                this.morphTargetDictionary = {};

                for (m in 0...morphAttribute.length) {
                    var name = morphAttribute[m].name ?? $m;

                    this.morphTargetInfluences.push(0);
                    this.morphTargetDictionary[name] = m;
                }
            }
        }
    }
}

function checkIntersection(object, raycaster, ray, thresholdSq, a, b) {
    var positionAttribute = object.geometry.attributes.position;

    var _vStart = new Vector3();
    var _vEnd = new Vector3();

    _vStart.fromBufferAttribute(positionAttribute, a);
    _vEnd.fromBufferAttribute(positionAttribute, b);

    var distSq = ray.distanceSqToSegment(_vStart, _vEnd, _intersectPointOnRay, _intersectPointOnSegment);

    if (distSq > thresholdSq) return false;

    _intersectPointOnRay.applyMatrix4(object.matrixWorld);
    var distance = raycaster.ray.origin.distanceTo(_intersectPointOnRay);

    if (distance < raycaster.near || distance > raycaster.far) return false;

    return {
        distance: distance,
        point: _intersectPointOnSegment.clone().applyMatrix4(object.matrixWorld),
        index: a,
        face: null,
        faceIndex: null,
        object: object
    };
}