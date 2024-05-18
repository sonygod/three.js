package three.js.examples.jsm.lines;

import three.js.Lib;
import three.js.math.Box3;
import three.js.math.InstancedInterleavedBuffer;
import three.js.math.InterleavedBufferAttribute;
import three.js.math.Line3;
import three.js.math.Matrix4;
import three.js.math.Sphere;
import three.js.math.Vector3;
import three.js.math.Vector4;
import three.js.objects.LineSegmentsGeometry;
import three.js.objects.LineMaterial;

class LineSegments2 extends Mesh {
    public var isLineSegments2:Bool;
    public var type:String;

    public function new(geometry:LineSegmentsGeometry = new LineSegmentsGeometry(), material:LineMaterial = new LineMaterial({ color: Math.random() * 0xffffff })) {
        super(geometry, material);
        this.isLineSegments2 = true;
        this.type = 'LineSegments2';
    }

    // for backwards-compatibility, but could be a method of LineSegmentsGeometry...
    public function computeLineDistances():LineSegments2 {
        var geometry:LineSegmentsGeometry = this.geometry;
        var instanceStart:InstancedInterleavedBuffer = geometry.attributes.instanceStart;
        var instanceEnd:InstancedInterleavedBuffer = geometry.attributes.instanceEnd;
        var lineDistances:Float32Array = new Float32Array(2 * instanceStart.count);

        for (i in 0...instanceStart.count) {
            var _start:Vector3 = new Vector3();
            _start.fromBufferAttribute(instanceStart, i);
            var _end:Vector3 = new Vector3();
            _end.fromBufferAttribute(instanceEnd, i);

            lineDistances[i * 2] = (i === 0) ? 0 : lineDistances[i * 2 - 1];
            lineDistances[i * 2 + 1] = lineDistances[i * 2] + _start.distanceTo(_end);
        }

        var instanceDistanceBuffer:InstancedInterleavedBuffer = new InstancedInterleavedBuffer(lineDistances, 2, 1); // d0, d1

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

        var ray:Ray = raycaster.ray;

        var matrixWorld:Matrix4 = this.matrixWorld;
        var geometry:LineSegmentsGeometry = this.geometry;
        var material:LineMaterial = this.material;

        var lineWidth:Float = material.linewidth + threshold;

        // check if we intersect the sphere bounds
        if (geometry.boundingSphere == null) {
            geometry.computeBoundingSphere();
        }

        var sphere:Sphere = geometry.boundingSphere.clone();
        sphere.applyMatrix4(matrixWorld);

        // increase the sphere bounds by the worst case line screen space width
        var sphereMargin:Float;
        if (worldUnits) {
            sphereMargin = lineWidth * 0.5;
        } else {
            var distanceToSphere:Float = Math.max(camera.near, sphere.distanceToPoint(ray.origin));
            sphereMargin = getWorldSpaceHalfWidth(camera, distanceToSphere, material.resolution);
        }

        sphere.radius += sphereMargin;

        if (!ray.intersectsSphere(sphere)) {
            return;
        }

        // check if we intersect the box bounds
        if (geometry.boundingBox == null) {
            geometry.computeBoundingBox();
        }

        var box:Box3 = geometry.boundingBox.clone();
        box.applyMatrix4(matrixWorld);

        // increase the box bounds by the worst case line width
        var boxMargin:Float;
        if (worldUnits) {
            boxMargin = lineWidth * 0.5;
        } else {
            var distanceToBox:Float = Math.max(camera.near, box.distanceToPoint(ray.origin));
            boxMargin = getWorldSpaceHalfWidth(camera, distanceToBox, material.resolution);
        }

        box.expandByScalar(boxMargin);

        if (!ray.intersectsBox(box)) {
            return;
        }

        if (worldUnits) {
            raycastWorldUnits(this, intersects);
        } else {
            raycastScreenSpace(this, camera, intersects);
        }
    }

    public function onBeforeRender(renderer:Renderer) {
        var uniforms:Dynamic = this.material.uniforms;

        if (uniforms != null && uniforms.resolution != null) {
            renderer.getViewport(_viewport);
            this.material.uniforms.resolution.value.set(_viewport.z, _viewport.w);
        }
    }
}

// helper functions
var _viewport:Vector4 = new Vector4();
var _start:Vector3 = new Vector3();
var _end:Vector3 = new Vector3();
var _start4:Vector4 = new Vector4();
var _end4:Vector4 = new Vector4();
var _ssOrigin:Vector4 = new Vector4();
var _ssOrigin3:Vector3 = new Vector3();
var _mvMatrix:Matrix4 = new Matrix4();
var _line:Line3 = new Line3();
var _closestPoint:Vector3 = new Vector3();
var _box:Box3 = new Box3();
var _sphere:Sphere = new Sphere();
var _clipToWorldVector:Vector4 = new Vector4();
var _ray:Ray;
var _lineWidth:Float;

function getWorldSpaceHalfWidth(camera:Camera, distance:Float, resolution:Vector2):Float {
    // transform into clip space, adjust the x and y values by the pixel width offset, then
    // transform back into world space to get world offset. Note clip space is [-1, 1] so full
    // width does not need to be halved.
    _clipToWorldVector.set(0, 0, -distance, 1.0);
    _clipToWorldVector.applyMatrix4(camera.projectionMatrix);
    _clipToWorldVector.multiplyScalar(1.0 / _clipToWorldVector.w);
    _clipToWorldVector.x = _lineWidth / resolution.x;
    _clipToWorldVector.y = _lineWidth / resolution.y;
    _clipToWorldVector.applyMatrix4(camera.projectionMatrixInverse);
    _clipToWorldVector.multiplyScalar(1.0 / _clipToWorldVector.w);

    return Math.abs(Math.max(_clipToWorldVector.x, _clipToWorldVector.y));
}

function raycastWorldUnits(lineSegments:LineSegments2, intersects:Array<Intersection>) {
    // ...
}

function raycastScreenSpace(lineSegments:LineSegments2, camera:Camera, intersects:Array<Intersection>) {
    // ...
}