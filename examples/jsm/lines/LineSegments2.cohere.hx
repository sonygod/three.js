import js.three.*;
import js.three.extras.core.InterleavedBufferAttribute;
import js.three.extras.core.InstancedInterleavedBuffer;
import js.three.extras.core.LineSegmentsGeometry;
import js.three.extras.materials.LineMaterial;
import js.three.extras.objects.LineSegments2;

class LineSegments2 extends js.three.Mesh {
    public function new(geometry:LineSegmentsGeometry = new LineSegmentsGeometry(), material:LineMaterial = new LineMaterial({ color: Std.random() * 0xffffff })) {
        super(geometry, material);
        this.isLineSegments2 = true;
        this.setType('LineSegments2');
    }

    public function computeLineDistances():Void {
        var geometry = this.geometry as LineSegmentsGeometry;
        var instanceStart = geometry.getAttribute('instanceStart') as InterleavedBufferAttribute;
        var instanceEnd = geometry.getAttribute('instanceEnd') as InterleavedBufferAttribute;
        var lineDistances = new Float32Array(2 * instanceStart.count);

        var j = 0;
        var _start = new js.three.Vector3();
        var _end = new js.three.Vector3();
        for (i in 0...instanceStart.count) {
            _start.fromBufferAttribute(instanceStart, i);
            _end.fromBufferAttribute(instanceEnd, i);

            lineDistances[j] = if (j == 0) 0 else lineDistances[j - 1];
            lineDistances[j + 1] = lineDistances[j] + _start.distanceTo(_end);

            j += 2;
        }

        var instanceDistanceBuffer = new InstancedInterleavedBuffer(lineDistances, 2, 1);
        geometry.setAttribute('instanceDistanceStart', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 0));
        geometry.setAttribute('instanceDistanceEnd', new InterleavedBufferAttribute(instanceDistanceBuffer, 1, 1));
    }

    public function raycast(raycaster:js.three.Raycaster, intersects:js.Array<js.three.Intersection>) {
        var worldUnits = this.material.worldUnits;
        var camera = raycaster.camera;

        if (camera == null && !worldUnits) {
            trace('LineSegments2: "Raycaster.camera" needs to be set in order to raycast against LineSegments2 while worldUnits is set to false.');
        }

        var threshold = if (raycaster.params.Line2 != null) raycaster.params.Line2.threshold else 0;

        var _ray = raycaster.ray;

        var matrixWorld = this.matrixWorld;
        var geometry = this.geometry;
        var material = this.material;

        var _lineWidth = material.linewidth + threshold;

        if (geometry.boundingSphere == null) {
            geometry.computeBoundingSphere();
        }

        var _sphere = geometry.boundingSphere.clone();
        _sphere.applyMatrix4(matrixWorld);

        var sphereMargin:Float;
        if (worldUnits) {
            sphereMargin = _lineWidth / 2;
        } else {
            var distanceToSphere = Math.max(camera.near, _sphere.distanceToPoint(_ray.origin));
            sphereMargin = getWorldSpaceHalfWidth(camera, distanceToSphere, material.resolution);
        }

        _sphere.radius += sphereMargin;

        if (!_ray.intersectsSphere(_sphere)) {
            return;
        }

        if (geometry.boundingBox == null) {
            geometry.computeBoundingBox();
        }

        var _box = geometry.boundingBox.clone();
        _box.applyMatrix4(matrixWorld);

        var boxMargin:Float;
        if (worldUnits) {
            boxMargin = _lineWidth / 2;
        } else {
            var distanceToBox = Math.max(camera.near, _box.distanceToPoint(_ray.origin));
            boxMargin = getWorldSpaceHalfWidth(camera, distanceToBox, material.resolution);
        }

        _box.expandByScalar(boxMargin);

        if (!_ray.intersectsBox(_box)) {
            return;
        }

        if (worldUnits) {
            raycastWorldUnits(this, intersects);
        } else {
            raycastScreenSpace(this, camera, intersects);
        }
    }

    public function onBeforeRender(renderer:js.three.WebGLRenderer) {
        var uniforms = this.material.uniforms;

        if (uniforms != null && uniforms.resolution != null) {
            var _viewport = new js.three.Vector4();
            renderer.getViewport(_viewport);
            this.material.uniforms.resolution.value.set(_viewport.z, _viewport.w);
        }
    }
}

function getWorldSpaceHalfWidth(camera:js.three.Camera, distance:Float, resolution:js.three.Vector2):Float {
    var _clipToWorldVector = new js.three.Vector4(0, 0, -distance, 1);
    _clipToWorldVector.applyMatrix4(camera.projectionMatrix);
    _clipToWorldVector.multiplyScalar(1 / _clipToWorldVector.w);
    _clipToWorldVector.x = _lineWidth / resolution.x;
    _clipToWorldVector.y = _lineWidth / resolution.y;
    _clipToWorldVector.applyMatrix4(camera.projectionMatrixInverse);
    _clipToWorldVector.multiplyScalar(1 / _clipToWorldVector.w);

    return Math.abs(Math.max(_clipToWorldVector.x, _clipToWorldVector.y));
}

function raycastWorldUnits(lineSegments:LineSegments2, intersects:js.Array<js.three.Intersection>) {
    var matrixWorld = lineSegments.matrixWorld;
    var geometry = lineSegments.geometry;
    var instanceStart = geometry.getAttribute('instanceStart') as InterleavedBufferAttribute;
    var instanceEnd = geometry.getAttribute('instanceEnd') as InterleavedBufferAttribute;
    var segmentCount = Math.min(geometry.instanceCount, instanceStart.count);

    var _line = new js.three.Line3();
    var _closestPoint = new js.three.Vector3();

    for (i in 0...segmentCount) {
        _line.start.fromBufferAttribute(instanceStart, i);
        _line.end.fromBufferAttribute(instanceEnd, i);

        _line.applyMatrix4(matrixWorld);

        var pointOnLine = new js.three.Vector3();
        var point = new js.three.Vector3();

        _ray.distanceSqToSegment(_line.start, _line.end, point, pointOnLine);
        var isInside = point.distanceTo(pointOnLine) < _lineWidth / 2;

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

function raycastScreenSpace(lineSegments:LineSegments2, camera:js.three.Camera, intersects:js.Array<js.three.Intersection>) {
    var projectionMatrix = camera.projectionMatrix;
    var material = lineSegments.material;
    var resolution = material.resolution;
    var matrixWorld = lineSegments.matrixWorld;

    var geometry = lineSegments.geometry;
    var instanceStart = geometry.getAttribute('instanceStart') as InterleavedBufferAttribute;
    var instanceEnd = geometry.getAttribute('instanceEnd') as InterleavedBufferAttribute;
    var segmentCount = Math.min(geometry.instanceCount, instanceStart.count);

    var near = -camera.near;

    var _ray = new js.three.Raycaster();
    var _ssOrigin = new js.three.Vector4();
    var _ssOrigin3 = new js.three.Vector3();
    var _mvMatrix = new js.three.Matrix4();
    var _line = new js.three.Line3();
    var _start4 = new js.three.Vector4();
    var _end4 = new js.three.Vector4();
    var _start = new js.three.Vector3();
    var _end = new js.three.Vector3();
    var _closestPoint = new js.three.Vector3();
    var _box = new js.three.Box3();
    var _sphere = new js.three.Sphere();
    var _clipToWorldVector = new js.three.Vector4();

    // pick a point 1 unit out along the ray to avoid the ray origin
    // sitting at the camera origin which will cause "w" to be 0 when
    // applying the projection matrix.
    _ray.at(1, _ssOrigin);

    // ndc space [ - 1.0, 1.0 ]
    _ssOrigin.w = 1;
    _ssOrigin.applyMatrix4(camera.matrixWorldInverse);
    _ssOrigin.applyMatrix4(projectionMatrix);
    _ssOrigin.multiplyScalar(1 / _ssOrigin.w);

    // screen space
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

        // camera space
        _start4.applyMatrix4(_mvMatrix);
        _end4.applyMatrix4(_mvMatrix);

        // skip the segment if it's entirely behind the camera
        var isBehindCameraNear = _start4.z > near && _end4.z > near;
        if (isBehindCameraNear) {
            continue;
        }

        // trim the segment if it extends behind camera near
        if (_start4.z > near) {
            var deltaDist = _start4.z - _end4.z;
            var t = (_start4.z - near) / deltaDist;
            _start4.lerp(_end4, t);
        } else if (_end4.z > near) {
            var deltaDist = _end4.z - _start4.z;
            var t = (_end4.z - near) / deltaDist;
            _end4.lerp(_start4, t);
        }

        // clip space
        _start4.applyMatrix4(projectionMatrix);
        _end4.applyMatrix4(projectionMatrix);

        // ndc space [ - 1.0, 1.0 ]
        _start4.multiplyScalar(1 / _start4.w);
        _end4.multiplyScalar(1 / _end4.w);

        // screen space
        _start4.x *= resolution.x / 2;
        _start4.y *= resolution.y / 2;

        _end4.x *= resolution.x / 2;
        _end4.y *= resolution.y / 2;

        // create 2d segment
        _line.start.copy(_start4);
        _line.start.z = 0;

        _line.end.copy(_end4);
        _line.end.z = 0;

        // get closest point on ray to segment
        var param = _line.closestPointToPointParameter(_ssOrigin3, true);
        _line.at(param, _closestPoint);

        // check if the intersection point is within clip space
        var zPos = js.three.MathUtils.lerp(_start4.z, _end4.z, param);
        var isInClipSpace = zPos >= -1 && zPos <= 1;

        var isInside = _ssOrigin3.distanceTo(_closestPoint) < _lineWidth / 2;

        if (isInClipSpace && isInside) {
            _line.start.fromBufferAttribute(instanceStart, i);
            _line.end.fromBufferAttribute(instanceEnd, i);

            _line.start.applyMatrix4(matrixWorld);
            _line.end.applyMatrix4(matrixWorld);

            var pointOnLine = new js.three.Vector3();
            var point = new js.three.Vector3();

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

class Line2Material extends js.three.LineBasicMaterial {
    public var worldUnits:Bool;
    public var resolution:js.three.Vector2;
}