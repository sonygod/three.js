import three.core.Object3D;
import three.core.BufferGeometry;
import three.core.InterleavedBuffer;
import three.core.InterleavedBufferAttribute;
import three.math.Vector2;
import three.math.Vector3;
import three.math.Matrix4;
import three.math.Triangle;
import three.materials.SpriteMaterial;

class Sprite extends Object3D {

    public static var _geometry:BufferGeometry;

    public var isSprite:Bool;
    public var center:Vector2;

    public function new(material:SpriteMaterial = null) {
        super();

        isSprite = true;

        this.type = 'Sprite';

        if (material == null) {
            material = new SpriteMaterial();
        }

        if (_geometry == null) {
            _geometry = new BufferGeometry();

            var float32Array = [
                -0.5, -0.5, 0, 0, 0,
                0.5, -0.5, 0, 1, 0,
                0.5, 0.5, 0, 1, 1,
                -0.5, 0.5, 0, 0, 1
            ];

            var interleavedBuffer = new InterleavedBuffer(cast float32Array, 5);

            _geometry.setIndex([0, 1, 2, 0, 2, 3]);
            _geometry.setAttribute('position', new InterleavedBufferAttribute(interleavedBuffer, 3, 0, false));
            _geometry.setAttribute('uv', new InterleavedBufferAttribute(interleavedBuffer, 2, 3, false));
        }

        this.geometry = _geometry;
        this.material = material;

        this.center = new Vector2(0.5, 0.5);
    }

    override public function raycast(raycaster:Raycaster, intersects:Array<Intersection>):Void {
        var _intersectPoint = new Vector3();
        var _worldScale = new Vector3();
        var _mvPosition = new Vector3();
        var _alignedPosition = new Vector2();
        var _rotatedPosition = new Vector2();
        var _viewWorldMatrix = new Matrix4();
        var _vA = new Vector3();
        var _vB = new Vector3();
        var _vC = new Vector3();
        var _uvA = new Vector2();
        var _uvB = new Vector2();
        var _uvC = new Vector2();
        
        if (raycaster.camera == null) {
            trace('THREE.Sprite: "Raycaster.camera" needs to be set in order to raycast against sprites.');
            return;
        }

        _worldScale.setFromMatrixScale(this.matrixWorld);

        _viewWorldMatrix.copy(raycaster.camera.matrixWorld);
        this.modelViewMatrix.multiplyMatrices(raycaster.camera.matrixWorldInverse, this.matrixWorld);

        _mvPosition.setFromMatrixPosition(this.modelViewMatrix);

        if (raycaster.camera.isPerspectiveCamera && !this.material.sizeAttenuation) {
            _worldScale.multiplyScalar(-_mvPosition.z);
        }

        var rotation = this.material.rotation;
        var sin = Math.sin(rotation);
        var cos = Math.cos(rotation);

        var center = this.center;

        transformVertex(_vA.set(-0.5, -0.5, 0), _mvPosition, center, _worldScale, sin, cos);
        transformVertex(_vB.set(0.5, -0.5, 0), _mvPosition, center, _worldScale, sin, cos);
        transformVertex(_vC.set(0.5, 0.5, 0), _mvPosition, center, _worldScale, sin, cos);

        _uvA.set(0, 0);
        _uvB.set(1, 0);
        _uvC.set(1, 1);

        // check first triangle
        var intersect = raycaster.ray.intersectTriangle(_vA, _vB, _vC, false, _intersectPoint);

        if (intersect == null) {
            // check second triangle
            transformVertex(_vB.set(-0.5, 0.5, 0), _mvPosition, center, _worldScale, sin, cos);
            _uvB.set(0, 1);

            intersect = raycaster.ray.intersectTriangle(_vA, _vC, _vB, false, _intersectPoint);
            if (intersect == null) {
                return;
            }
        }

        var distance = raycaster.ray.origin.distanceTo(_intersectPoint);

        if (distance < raycaster.near || distance > raycaster.far) {
            return;
        }

        intersects.push({
            distance: distance,
            point: _intersectPoint.clone(),
            uv: Triangle.getInterpolation(_intersectPoint, _vA, _vB, _vC, _uvA, _uvB, _uvC, new Vector2()),
            face: null,
            object: this
        });
    }

    override public function copy(source:Object3D, ?recursive:Bool):Object3D {
        super.copy(source, recursive);

        if (source.center != null) {
            this.center.copy(source.center);
        }

        this.material = source.material;
        
        return this;
    }

    private function transformVertex(vertexPosition:Vector3, mvPosition:Vector3, center:Vector2, scale:Vector3, sin:Float, cos:Float):Void {
        // compute position in camera space
        var _alignedPosition = new Vector2();
        var _rotatedPosition = new Vector2();
        var _viewWorldMatrix = new Matrix4();

        _alignedPosition.subVectors(vertexPosition, center).addScalar(0.5).multiply(scale);

        // to check if rotation is not zero
        if (sin != 0 || cos != 1) {
            _rotatedPosition.x = (cos * _alignedPosition.x) - (sin * _alignedPosition.y);
            _rotatedPosition.y = (sin * _alignedPosition.x) + (cos * _alignedPosition.y);
        } else {
            _rotatedPosition.copy(_alignedPosition);
        }

        vertexPosition.copy(mvPosition);
        vertexPosition.x += _rotatedPosition.x;
        vertexPosition.y += _rotatedPosition.y;

        // transform to world space
        vertexPosition.applyMatrix4(_viewWorldMatrix);
    }

}