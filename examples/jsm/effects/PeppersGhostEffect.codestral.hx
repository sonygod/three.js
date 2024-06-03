import haxe.ds.Vector3;
import haxe.ds.Quaternion;
import hxthreejs.THREE.PerspectiveCamera;

class PeppersGhostEffect {
    public var cameraDistance:Float = 15.0;
    public var reflectFromAbove:Bool = false;

    private var _halfWidth:Float;
    private var _width:Float;
    private var _height:Float;

    private var _cameraF:PerspectiveCamera = new PerspectiveCamera();
    private var _cameraB:PerspectiveCamera = new PerspectiveCamera();
    private var _cameraL:PerspectiveCamera = new PerspectiveCamera();
    private var _cameraR:PerspectiveCamera = new PerspectiveCamera();

    private var _position:Vector3 = new Vector3();
    private var _quaternion:Quaternion = new Quaternion();
    private var _scale:Vector3 = new Vector3();

    public function new(renderer:any) {
        renderer.autoClear = false;
    }

    public function setSize(width:Float, height:Float) {
        _halfWidth = width / 2.0;
        if (width < height) {
            _width = width / 3.0;
            _height = width / 3.0;
        } else {
            _width = height / 3.0;
            _height = height / 3.0;
        }
        renderer.setSize(width, height);
    }

    public function render(scene:any, camera:any) {
        if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
        if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
        camera.matrixWorld.decompose(_position, _quaternion, _scale);

        // front
        _cameraF.position.copy(_position);
        _cameraF.quaternion.copy(_quaternion);
        _cameraF.translateZ(cameraDistance);
        _cameraF.lookAt(scene.position);

        // back
        _cameraB.position.copy(_position);
        _cameraB.quaternion.copy(_quaternion);
        _cameraB.translateZ(-cameraDistance);
        _cameraB.lookAt(scene.position);
        _cameraB.rotation.z += 180 * (Math.PI / 180);

        // left
        _cameraL.position.copy(_position);
        _cameraL.quaternion.copy(_quaternion);
        _cameraL.translateX(-cameraDistance);
        _cameraL.lookAt(scene.position);
        _cameraL.rotation.x += 90 * (Math.PI / 180);

        // right
        _cameraR.position.copy(_position);
        _cameraR.quaternion.copy(_quaternion);
        _cameraR.translateX(cameraDistance);
        _cameraR.lookAt(scene.position);
        _cameraR.rotation.x += 90 * (Math.PI / 180);

        renderer.clear();
        renderer.setScissorTest(true);

        renderer.setScissor(_halfWidth - (_width / 2), _height * 2, _width, _height);
        renderer.setViewport(_halfWidth - (_width / 2), _height * 2, _width, _height);

        if (reflectFromAbove) {
            renderer.render(scene, _cameraB);
        } else {
            renderer.render(scene, _cameraF);
        }

        renderer.setScissor(_halfWidth - (_width / 2), 0, _width, _height);
        renderer.setViewport(_halfWidth - (_width / 2), 0, _width, _height);

        if (reflectFromAbove) {
            renderer.render(scene, _cameraF);
        } else {
            renderer.render(scene, _cameraB);
        }

        renderer.setScissor(_halfWidth - (_width / 2) - _width, _height, _width, _height);
        renderer.setViewport(_halfWidth - (_width / 2) - _width, _height, _width, _height);

        if (reflectFromAbove) {
            renderer.render(scene, _cameraR);
        } else {
            renderer.render(scene, _cameraL);
        }

        renderer.setScissor(_halfWidth + (_width / 2), _height, _width, _height);
        renderer.setViewport(_halfWidth + (_width / 2), _height, _width, _height);

        if (reflectFromAbove) {
            renderer.render(scene, _cameraL);
        } else {
            renderer.render(scene, _cameraR);
        }

        renderer.setScissorTest(false);
    }
}