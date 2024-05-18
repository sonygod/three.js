package three.examples.jsm.effects;

import three.PerspectiveCamera;
import three.Quaternion;
import three.Vector3;

class PeppersGhostEffect {
    private var cameraDistance:Float = 15;
    private var reflectFromAbove:Bool = false;

    private var _halfWidth:Float;
    private var _width:Float;
    private var _height:Float;

    private var _cameraF:PerspectiveCamera;
    private var _cameraB:PerspectiveCamera;
    private var _cameraL:PerspectiveCamera;
    private var _cameraR:PerspectiveCamera;

    private var _position:Vector3;
    private var _quaternion:Quaternion;
    private var _scale:Vector3;

    public function new(renderer:js.html.webgl.RenderingContext) {
        _cameraF = new PerspectiveCamera(); //front
        _cameraB = new PerspectiveCamera(); //back
        _cameraL = new PerspectiveCamera(); //left
        _cameraR = new PerspectiveCamera(); //right

        _position = new Vector3();
        _quaternion = new Quaternion();
        _scale = new Vector3();

        renderer.autoClear = false;
    }

    public function setSize(width:Int, height:Int) {
        _halfWidth = width / 2;
        if (width < height) {
            _width = width / 3;
            _height = width / 3;
        } else {
            _width = height / 3;
            _height = height / 3;
        }

        renderer.setSize(width, height);
    }

    public function render(scene:Dynamic, camera:Dynamic) {
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
        _cameraB.rotation.z += Math.PI;

        // left
        _cameraL.position.copy(_position);
        _cameraL.quaternion.copy(_quaternion);
        _cameraL.translateX(-cameraDistance);
        _cameraL.lookAt(scene.position);
        _cameraL.rotation.x += Math.PI / 2;

        // right
        _cameraR.position.copy(_position);
        _cameraR.quaternion.copy(_quaternion);
        _cameraR.translateX(cameraDistance);
        _cameraR.lookAt(scene.position);
        _cameraR.rotation.x += Math.PI / 2;

        renderer.clear();
        renderer.setScissorTest(true);

        renderer.setScissor(_halfWidth - (_width / 2), (_height * 2), _width, _height);
        renderer.setViewport(_halfWidth - (_width / 2), (_height * 2), _width, _height);

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