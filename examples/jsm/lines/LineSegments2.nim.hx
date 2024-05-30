import three.js.examples.jsm.lines.LineSegmentsGeometry;
import three.js.examples.jsm.lines.LineMaterial;
import three.js.Box3;
import three.js.InstancedInterleavedBuffer;
import three.js.InterleavedBufferAttribute;
import three.js.Line3;
import three.js.MathUtils;
import three.js.Matrix4;
import three.js.Mesh;
import three.js.Sphere;
import three.js.Vector3;
import three.js.Vector4;

class Main {
    static var _viewport:Vector4;
    static var _start:Vector3;
    static var _end:Vector3;
    static var _start4:Vector4;
    static var _end4:Vector4;
    static var _ssOrigin:Vector4;
    static var _ssOrigin3:Vector3;
    static var _mvMatrix:Matrix4;
    static var _line:Line3;
    static var _closestPoint:Vector3;
    static var _box:Box3;
    static var _sphere:Sphere;
    static var _clipToWorldVector:Vector4;
    static var _ray:Ray;
    static var _lineWidth:Float;

    static function main() {
        _viewport = new Vector4();
        _start = new Vector3();
        _end = new Vector3();
        _start4 = new Vector4();
        _end4 = new Vector4();
        _ssOrigin = new Vector4();
        _ssOrigin3 = new Vector3();
        _mvMatrix = new Matrix4();
        _line = new Line3();
        _closestPoint = new Vector3();
        _box = new Box3();
        _sphere = new Sphere();
        _clipToWorldVector = new Vector4();

        // Your code here...
    }

    static function getWorldSpaceHalfWidth(camera:Camera, distance:Float, resolution:Vector2):Float {
        // Transform into clip space, adjust the x and y values by the pixel width offset,
        // then transform back into world space to get world offset.
        _clipToWorldVector.set(0, 0, -distance, 1.0).applyMatrix4(camera.projectionMatrix);
        _clipToWorldVector.multiplyScalar(1.0 / _clipToWorldVector.w);
        _clipToWorldVector.x = _lineWidth / resolution.width;
        _clipToWorldVector.y = _lineWidth / resolution.height;
        _clipToWorldVector.applyMatrix4(camera.projectionMatrixInverse);
        _clipToWorldVector.multiplyScalar(1.0 / _clipToWorldVector.w);

        return Math.abs(Math.max(_clipToWorldVector.x, _clipToWorldVector.y));
    }

    static function raycastWorldUnits(lineSegments:LineSegments2, intersects:Array<Dynamic>) {
        // Your code here...
    }

    static function raycastScreenSpace(lineSegments:LineSegments2, camera:Camera, intersects:Array<Dynamic>) {
        // Your code here...
    }

    class LineSegments2 extends Mesh {
        public function new(geometry:LineSegmentsGeometry = new LineSegmentsGeometry(), material:LineMaterial = new LineMaterial({color: Math.random() * 0xffffff})) {
            super(geometry, material);

            this.isLineSegments2 = true;
            this.type = 'LineSegments2';
        }

        // Your code here...
    }
}