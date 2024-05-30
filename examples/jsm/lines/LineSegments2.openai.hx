package three.js.examples.jsm.lines;

import three.js.Lib;
import three.js.math.Box3;
import three.js.math.InterleavedBuffer;
import three.js.math.InterleavedBufferAttribute;
import three.js.math.Line3;
import three.js.math.MathUtils;
import three.js.math.Matrix4;
import three.js.math.Mesh;
import three.js.math.Sphere;
import three.js.math.Vector3;
import three.js.math.Vector4;

class LineSegments2 extends Mesh {
    public var isLineSegments2:Bool = true;
    public var type:String = 'LineSegments2';

    private var _viewport:Vector4;
    private var _start:Vector3;
    private var _end:Vector3;
    private var _start4:Vector4;
    private var _end4:Vector4;
    private var _ssOrigin:Vector4;
    private var _ssOrigin3:Vector3;
    private var _mvMatrix:Matrix4;
    private var _line:Line3;
    private var _closestPoint:Vector3;
    private var _box:Box3;
    private var _sphere:Sphere;
    private var _clipToWorldVector:Vector4;
    private var _ray:Raycaster;
    private var _lineWidth:Float;

    public function new(geometry:LineSegmentsGeometry = null, material:LineMaterial = null) {
        super(geometry, material);
        if (geometry == null) geometry = new LineSegmentsGeometry();
        if (material == null) material = new LineMaterial({ color: Math.random() * 0xFFFFFF });
    }

    // for backwards-compatibility, but could be a method of LineSegmentsGeometry...
    public function computeLineDistances():LineSegments2 {
        var geometry:LineSegmentsGeometry = this.geometry;
        var instanceStart:InterleavedBufferAttribute = geometry.attributes.instanceStart;
        var instanceEnd:InterleavedBufferAttribute = geometry.attributes.instanceEnd;
        var lineDistances:Float32Array = new Float32Array(2 * instanceStart.count);

        for (i in 0...instanceStart.count) {
            _start.fromBufferAttribute(instanceStart, i);
            _end.fromBufferAttribute(instanceEnd, i);

            lineDistances[i*2] = (i == 0) ? 0 : lineDistances[i*2-1];
            lineDistances[i*2+1] = lineDistances[i*2] + _start.distanceTo(_end);
        }

        var instanceDistanceBuffer:InterleavedBuffer = new InterleavedBuffer(lineDistances, 2, 1); // d0, d1
        geometry.setAttribute('instanceDistanceStart', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 0)); // d0
        geometry.setAttribute('instanceDistanceEnd', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 1)); // d1

        return this;
    }

    public function raycast(raycaster:Raycaster, intersects:Array<Intersection>) {
        var worldUnits:Bool = this.material.worldUnits;
        var camera:Camera = raycaster.camera;

        if (camera == null && !worldUnits) {
            trace('LineSegments2: "Raycaster.camera" needs to be set in order to raycast against LineSegments2 while worldUnits is set to false.');
        }

        var threshold:Float = (raycaster.params.Line2 != null) ? raycaster.params.Line2.threshold || 0 : 0;

        _ray = raycaster.ray;

        var matrixWorld:Matrix4 = this.matrixWorld;
        var geometry:LineSegmentsGeometry = this.geometry;
        var material:LineMaterial = this.material;

        _lineWidth = material.linewidth + threshold;

        // check if we intersect the sphere bounds
        if (geometry.boundingSphere == null) geometry.computeBoundingSphere();

        _sphere.copy(geometry.boundingSphere).applyMatrix4(matrixWorld);

        // increase the sphere bounds by the worst case line screen space width
        var sphereMargin:Float;
        if (worldUnits) {
            sphereMargin = _lineWidth * 0.5;
        } else {
            var distanceToSphere:Float = Math.max(camera.near, _sphere.distanceToPoint(_ray.origin));
            sphereMargin = getWorldSpaceHalfWidth(camera, distanceToSphere, material.resolution);
        }

        _sphere.radius += sphereMargin;

        if (!_ray.intersectsSphere(_sphere)) return;

        // check if we intersect the box bounds
        if (geometry.boundingBox == null) geometry.computeBoundingBox();

        _box.copy(geometry.boundingBox).applyMatrix4(matrixWorld);

        // increase the box bounds by the worst case line width
        var boxMargin:Float;
        if (worldUnits) {
            boxMargin = _lineWidth * 0.5;
        } else {
            var distanceToBox:Float = Math.max(camera.near, _box.distanceToPoint(_ray.origin));
            boxMargin = getWorldSpaceHalfWidth(camera, distanceToBox, material.resolution);
        }

        _box.expandByScalar(boxMargin);

        if (!_ray.intersectsBox(_box)) return;

        if (worldUnits) {
            raycastWorldUnits(this, intersects);
        } else {
            raycastScreenSpace(this, camera, intersects);
        }
    }

    public function onBeforeRender(renderer:WebGLRenderer) {
        var uniforms:Uniforms = this.material.uniforms;

        if (uniforms != null && uniforms.resolution != null) {
            renderer.getViewport(_viewport);
            this.material.uniforms.resolution.value.set(_viewport.z, _viewport.w);
        }
    }

    private function getWorldSpaceHalfWidth(camera:Camera, distance:Float, resolution:Vector2):Float {
        _clipToWorldVector.set(0, 0, -distance, 1.0).applyMatrix4(camera.projectionMatrix);
        _clipToWorldVector.multiplyScalar(1.0 / _clipToWorldVector.w);
        _clipToWorldVector.x = _lineWidth / resolution.x;
        _clipToWorldVector.y = _lineWidth / resolution.y;
        _clipToWorldVector.applyMatrix4(camera.projectionMatrixInverse);
        _clipToWorldVector.multiplyScalar(1.0 / _clipToWorldVector.w);

        return Math.abs(Math.max(_clipToWorldVector.x, _clipToWorldVector.y));
    }

    private function raycastWorldUnits(lineSegments:LineSegments2, intersects:Array<Intersection>) {
        var matrixWorld:Matrix4 = lineSegments.matrixWorld;
        var geometry:LineSegmentsGeometry = lineSegments.geometry;
        var instanceStart:InterleavedBufferAttribute = geometry.attributes.instanceStart;
        var instanceEnd:InterleavedBufferAttribute = geometry.attributes.instanceEnd;
        var segmentCount:Int = Math.min(geometry.instanceCount, instanceStart.count);

        for (i in 0...segmentCount) {
            _line.start.fromBufferAttribute(instanceStart, i);
            _line.end.fromBufferAttribute(instanceEnd, i);

            _line.applyMatrix4(matrixWorld);

            var pointOnLine:Vector3 = new Vector3();
            var point:Vector3 = new Vector3();

            _ray.distanceSqToSegment(_line.start, _line.end, point, pointOnLine);
            var isInside:Bool = point.distanceTo(pointOnLine) < _lineWidth * 0.5;

            if (isInside) {
                intersects.push({
                    point: point,
                    pointOnLine: pointOnLine,
                    distance: _ray.origin.distanceTo(point),
                    object: lineSegments,
                    face: null,
                    faceIndex: i,
                    uv: null,
                    uv1: null
                });
            }
        }
    }

    private function raycastScreenSpace(lineSegments:LineSegments2, camera:Camera, intersects:Array<Intersection>) {
        var projectionMatrix:Matrix4 = camera.projectionMatrix;
        var material:LineMaterial = lineSegments.material;
        var resolution:Vector2 = material.resolution;
        var matrixWorld:Matrix4 = lineSegments.matrixWorld;

        var geometry:LineSegmentsGeometry = lineSegments.geometry;
        var instanceStart:InterleavedBufferAttribute = geometry.attributes.instanceStart;
        var instanceEnd:InterleavedBufferAttribute = geometry.attributes.instanceEnd;
        var segmentCount:Int = Math.min(geometry.instanceCount, instanceStart.count);

        var near:Float = -camera.near;

        _ray.at(1, _ssOrigin);

        _ssOrigin.w = 1;
        _ssOrigin.applyMatrix4(camera.matrixWorldInverse);
        _ssOrigin.applyMatrix4(projectionMatrix);
        _ssOrigin.multiplyScalar(1.0 / _ssOrigin.w);

        _ssOrigin.x *= resolution.x / 2;
        _ssOrigin.y *= resolution.y / 2;
        _ssOrigin.z = 0;

        _ssOrigin3.copy(_ssOrigin);

        _mvMatrix.multiplyMatrices(camera.matrixWorldInverse, matrixWorld);

        for (i in 0...segmentCount) {
            _start4.fromBufferAttribute(instanceStart, i);
            _end4.fromBufferAttribute(instanceEnd, i);

            _start4.w = 1;
            _end4.w = 1;

            _start4.applyMatrix4(_mvMatrix);
            _end4.applyMatrix4(_mvMatrix);

            var isBehindCameraNear:Bool = _start4.z > near && _end4.z > near;
            if (isBehindCameraNear) continue;

            if (_start4.z > near) {
                var deltaDist:Float = _start4.z - _end4.z;
                var t:Float = (_start4.z - near) / deltaDist;
                _start4.lerp(_end4, t);
            } else if (_end4.z > near) {
                var deltaDist:Float = _end4.z - _start4.z;
                var t:Float = (_end4.z - near) / deltaDist;
                _end4.lerp(_start4, t);
            }

            _start4.applyMatrix4(projectionMatrix);
            _end4.applyMatrix4(projectionMatrix);

            _start4.multiplyScalar(1.0 / _start4.w);
            _end4.multiplyScalar(1.0 / _end4.w);

            _start4.x *= resolution.x / 2;
            _start4.y *= resolution.y / 2;

            _end4.x *= resolution.x / 2;
            _end4.y *= resolution.y / 2;

            _line.start.copy(_start4);
            _line.start.z = 0;

            _line.end.copy(_end4);
            _line.end.z = 0;

            var param:Float = _line.closestPointToPointParameter(_ssOrigin3, true);
            _line.at(param, _closestPoint);

            var isInClipSpace:Bool = _start4.z >= -1 && _start4.z <= 1 && _end4.z >= -1 && _end4.z <= 1;
            var isInside:Bool = _ssOrigin3.distanceTo(_closestPoint) < _lineWidth * 0.5;

            if (isInClipSpace && isInside) {
                _line.start.fromBufferAttribute(instanceStart, i);
                _line.end.fromBufferAttribute(instanceEnd, i);

                _line.start.applyMatrix4(matrixWorld);
                _line.end.applyMatrix4(matrixWorld);

                var pointOnLine:Vector3 = new Vector3();
                var point:Vector3 = new Vector3();

                _ray.distanceSqToSegment(_line.start, _line.end, point, pointOnLine);

                intersects.push({
                    point: point,
                    pointOnLine: pointOnLine,
                    distance: _ray.origin.distanceTo(point),
                    object: lineSegments,
                    face: null,
                    faceIndex: i,
                    uv: null,
                    uv1: null
                });
            }
        }
    }
}