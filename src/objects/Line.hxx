package three.js.src.objects;

import three.js.src.math.Sphere;
import three.js.src.math.Ray;
import three.js.src.math.Matrix4;
import three.js.src.core.Object3D;
import three.js.src.math.Vector3;
import three.js.src.materials.LineBasicMaterial;
import three.js.src.core.BufferGeometry;
import three.js.src.core.Float32BufferAttribute;

class Line extends Object3D {

    static var _vStart:Vector3 = new Vector3();
    static var _vEnd:Vector3 = new Vector3();

    static var _inverseMatrix:Matrix4 = new Matrix4();
    static var _ray:Ray = new Ray();
    static var _sphere:Sphere = new Sphere();

    static var _intersectPointOnRay:Vector3 = new Vector3();
    static var _intersectPointOnSegment:Vector3 = new Vector3();

    public function new(geometry:BufferGeometry = new BufferGeometry(), material:LineBasicMaterial = new LineBasicMaterial()) {
        super();

        this.isLine = true;
        this.type = 'Line';
        this.geometry = geometry;
        this.material = material;

        this.updateMorphTargets();
    }

    public function copy(source:Line, recursive:Bool):Line {
        super.copy(source, recursive);

        this.material = if (Array.isArray(source.material)) source.material.slice() else source.material;
        this.geometry = source.geometry;

        return this;
    }

    public function computeLineDistances():Line {
        var geometry:BufferGeometry = this.geometry;

        if (geometry.index == null) {
            var positionAttribute = geometry.attributes.position;
            var lineDistances = [0];

            for (i in 1...positionAttribute.count) {
                _vStart.fromBufferAttribute(positionAttribute, i - 1);
                _vEnd.fromBufferAttribute(positionAttribute, i);

                lineDistances[i] = lineDistances[i - 1];
                lineDistances[i] += _vStart.distanceTo(_vEnd);
            }

            geometry.setAttribute('lineDistance', new Float32BufferAttribute(lineDistances, 1));
        } else {
            trace('THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.');
        }

        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<Intersection>):Void {
        var geometry:BufferGeometry = this.geometry;
        var matrixWorld:Matrix4 = this.matrixWorld;
        var threshold:Float = raycaster.params.Line.threshold;
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

        var step:Int = this.isLineSegments ? 2 : 1;

        var index:BufferAttribute = geometry.index;
        var attributes:Attributes = geometry.attributes;
        var positionAttribute:BufferAttribute = attributes.position;

        if (index != null) {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(index.count, (drawRange.start + drawRange.count));

            for (i in start...end - 1 by step) {
                var a:Int = index.getX(i);
                var b:Int = index.getX(i + 1);

                var intersect:Intersection = checkIntersection(this, raycaster, _ray, localThresholdSq, a, b);

                if (intersect != null) {
                    intersects.push(intersect);
                }
            }

            if (this.isLineLoop) {
                var a:Int = index.getX(end - 1);
                var b:Int = index.getX(start);

                var intersect:Intersection = checkIntersection(this, raycaster, _ray, localThresholdSq, a, b);

                if (intersect != null) {
                    intersects.push(intersect);
                }
            }
        } else {
            var start:Int = Math.max(0, drawRange.start);
            var end:Int = Math.min(positionAttribute.count, (drawRange.start + drawRange.count));

            for (i in start...end - 1 by step) {
                var intersect:Intersection = checkIntersection(this, raycaster, _ray, localThresholdSq, i, i + 1);

                if (intersect != null) {
                    intersects.push(intersect);
                }
            }

            if (this.isLineLoop) {
                var intersect:Intersection = checkIntersection(this, raycaster, _ray, localThresholdSq, end - 1, start);

                if (intersect != null) {
                    intersects.push(intersect);
                }
            }
        }
    }

    public function updateMorphTargets():Void {
        var geometry:BufferGeometry = this.geometry;

        var morphAttributes:MorphAttributes = geometry.morphAttributes;
        var keys:Array<String> = Reflect.fields(morphAttributes);

        if (keys.length > 0) {
            var morphAttribute:Array<BufferAttribute> = morphAttributes[keys[0]];

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

    static function checkIntersection(object:Line, raycaster:Raycaster, ray:Ray, thresholdSq:Float, a:Int, b:Int):Intersection {
        var positionAttribute:BufferAttribute = object.geometry.attributes.position;

        _vStart.fromBufferAttribute(positionAttribute, a);
        _vEnd.fromBufferAttribute(positionAttribute, b);

        var distSq:Float = ray.distanceSqToSegment(_vStart, _vEnd, _intersectPointOnRay, _intersectPointOnSegment);

        if (distSq > thresholdSq) return null;

        _intersectPointOnRay.applyMatrix4(object.matrixWorld);

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