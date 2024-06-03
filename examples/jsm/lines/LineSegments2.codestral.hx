import js.three.Box3;
import js.three.InstancedInterleavedBuffer;
import js.three.InterleavedBufferAttribute;
import js.three.Line3;
import js.three.MathUtils;
import js.three.Matrix4;
import js.three.Mesh;
import js.three.Sphere;
import js.three.Vector3;
import js.three.Vector4;

import js.three.lines.LineSegmentsGeometry;
import js.three.lines.LineMaterial;

class LineSegments2 extends Mesh {

    private var _viewport: Vector4 = new Vector4();

    private var _start: Vector3 = new Vector3();
    private var _end: Vector3 = new Vector3();

    private var _start4: Vector4 = new Vector4();
    private var _end4: Vector4 = new Vector4();

    private var _ssOrigin: Vector4 = new Vector4();
    private var _ssOrigin3: Vector3 = new Vector3();
    private var _mvMatrix: Matrix4 = new Matrix4();
    private var _line: Line3 = new Line3();
    private var _closestPoint: Vector3 = new Vector3();

    private var _box: Box3 = new Box3();
    private var _sphere: Sphere = new Sphere();
    private var _clipToWorldVector: Vector4 = new Vector4();

    private function getWorldSpaceHalfWidth(camera: Camera, distance: Float, resolution: Vector2): Float {
        _clipToWorldVector.set(0, 0, -distance, 1.0).applyMatrix4(camera.projectionMatrix);
        _clipToWorldVector.multiplyScalar(1.0 / _clipToWorldVector.w);
        _clipToWorldVector.x = lineWidth / resolution.x;
        _clipToWorldVector.y = lineWidth / resolution.y;
        _clipToWorldVector.applyMatrix4(camera.projectionMatrixInverse);
        _clipToWorldVector.multiplyScalar(1.0 / _clipToWorldVector.w);

        return Math.abs(Math.max(_clipToWorldVector.x, _clipToWorldVector.y));
    }

    private function raycastWorldUnits(lineSegments: LineSegments2, intersects: Array<Intersection>) {
        // Implementation omitted for brevity
    }

    private function raycastScreenSpace(lineSegments: LineSegments2, camera: Camera, intersects: Array<Intersection>) {
        // Implementation omitted for brevity
    }

    public function new(geometry: LineSegmentsGeometry = new LineSegmentsGeometry(), material: LineMaterial = new LineMaterial({ color: Math.random() * 0xffffff })) {
        super(geometry, material);
        this.isLineSegments2 = true;
        this.type = 'LineSegments2';
    }

    public function computeLineDistances(): LineSegments2 {
        // Implementation omitted for brevity
        return this;
    }

    public function raycast(raycaster: Raycaster, intersects: Array<Intersection>): Void {
        // Implementation omitted for brevity
    }

    public function onBeforeRender(renderer: Renderer): Void {
        // Implementation omitted for brevity
    }

}