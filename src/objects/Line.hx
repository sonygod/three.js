package three.objects;

import three.math.Sphere;
import three.math.Ray;
import three.math.Matrix4;
import three.core.Object3D;
import three.math.Vector3;
import three.materials.LineBasicMaterial;
import three.core.BufferGeometry;
import three.core.BufferAttribute;

class Line extends Object3D {
    public var isLine:Bool;
    public var type:String;
    public var geometry:BufferGeometry;
    public var material:LineBasicMaterial;
    public var morphTargetInfluences:Array<Float>;
    public var morphTargetDictionary:Map<String, Int>;

    private var _vStart:Vector3;
    private var _vEnd:Vector3;
    private var _inverseMatrix:Matrix4;
    private var _ray:Ray;
    private var _sphere:Sphere;
    private var _intersectPointOnRay:Vector3;
    private var _intersectPointOnSegment:Vector3;

    public function new(geometry:BufferGeometry = null, material:LineBasicMaterial = null) {
        super();
        this.isLine = true;
        this.type = 'Line';
        this.geometry = geometry != null ? geometry : new BufferGeometry();
        this.material = material != null ? material : new LineBasicMaterial();
        this.updateMorphTargets();
    }

    public function copy(source:Object3D, recursive:Bool):Line {
        super.copy(source, recursive);
        this.material = source.material.clone();
        this.geometry = source.geometry;
        return this;
    }

    public function computeLineDistances():Line {
        var geometry:BufferGeometry = this.geometry;
        if (geometry.index == null) {
            var positionAttribute:BufferAttribute = geometry.attributes.position;
            var lineDistances:Array<Float> = [0];
            for (i in 1...positionAttribute.count) {
                _vStart.fromBufferAttribute(positionAttribute, i - 1);
                _vEnd.fromBufferAttribute(positionAttribute, i);
                lineDistances[i] = lineDistances[i - 1] + _vStart.distanceTo(_vEnd);
            }
            geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));
        } else {
            trace('THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
        }
        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<RaycastHit>):Void {
        var geometry:BufferGeometry = this.geometry;
        var matrixWorld:Matrix4 = this.matrixWorld;
        var threshold:Float = raycaster.params.Line.threshold;
        var drawRange:DrawRange = geometry.drawRange;

        // Checking boundingSphere distance to ray
        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();
        _sphere.copy(geometry.boundingSphere);
        _sphere.applyMatrix4(matrixWorld);
        _sphere.radius += threshold;

        if (!_sphere.intersectsRay(raycaster.ray)) return;

        _inverseMatrix.copy(matrixWorld).invert();
        _ray.copy(raycaster.ray).applyMatrix4(_inverseMatrix);

        var localThreshold:Float = threshold / ((this.scale.x + this.scale.y + this.scale.z) / 3);
        var localThresholdSq:Float = localThreshold * localThreshold;

        var step:Int = this.isLineSegments ? 2 : 1;

        var index:BufferAttribute = geometry.index;
        var attributes:Attributes = geometry.attributes;
        var positionAttribute:BufferAttribute = attributes.position;

        if (index != null) {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(index.count, drawRange.start + drawRange.count);

            for (i in start...(end - 1)) {
                var a:Int = index.getX(i);
                var b:Int = index.getX(i + 1);

                var intersect:RaycastHit = checkIntersection(this, raycaster, _ray, localThresholdSq, a, b);

                if (intersect != null) {
                    intersects.push(intersect);
                }
            }

            if (this.isLineLoop) {
                var a:Int = index.getX(end - 1);
                var b:Int = index.getX(start);

                var intersect:RaycastHit = checkIntersection(this, raycaster, _ray, localThresholdSq, a, b);

                if (intersect != null) {
                    intersects.push(intersect);
                }
            }
        } else {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(positionAttribute.count, drawRange.start + drawRange.count);

            for (i in start...(end - 1)) {
                var intersect:RaycastHit = checkIntersection(this, raycaster, _ray, localThresholdSq, i, i + 1);

                if (intersect != null) {
                    intersects.push(intersect);
                }
            }

            if (this.isLineLoop) {
                var intersect:RaycastHit = checkIntersection(this, raycaster, _ray, localThresholdSq, end - 1, start);

                if (intersect != null) {
                    intersects.push(intersect);
                }
            }
        }
    }

    public function updateMorphTargets():Void {
        var geometry:BufferGeometry = this.geometry;
        var morphAttributes:MorphAttributes = geometry.morphAttributes;
        var keys:Array<String> = Object.keys(morphAttributes);

        if (keys.length > 0) {
            var morphAttribute:MorphAttribute = morphAttributes[keys[0]];

            if (morphAttribute != null) {
                this.morphTargetInfluences = [];
                this.morphTargetDictionary = {};

                for (m in 0...morphAttribute.length) {
                    var name:String = morphAttribute[m].name != null ? morphAttribute[m].name : Std.string(m);

                    this.morphTargetInfluences.push(0);
                    this.morphTargetDictionary[name] = m;
                }
            }
        }
    }

    private function checkIntersection(object:Object3D, raycaster:Raycaster, ray:Ray, thresholdSq:Float, a:Int, b:Int):RaycastHit {
        var positionAttribute:BufferAttribute = object.geometry.attributes.position;

        _vStart.fromBufferAttribute(positionAttribute, a);
        _vEnd.fromBufferAttribute(positionAttribute, b);

        var distSq:Float = ray.distanceSqToSegment(_vStart, _vEnd, _intersectPointOnRay, _intersectPointOnSegment);

        if (distSq > thresholdSq) return null;

        _intersectPointOnRay.applyMatrix4(object.matrixWorld); // Move back to world space for distance calculation

        var distance:Float = raycaster.ray.origin.distanceTo(_intersectPointOnRay);

        if (distance < raycaster.near || distance > raycaster.far) return null;

        return {
            distance: distance,
            point: _intersectPointOnSegment.clone().applyMatrix4(object.matrixWorld),
            index: a,
            face: null,
            faceIndex: null,
            object: object
        };
    }
}