package;

import js.three.PerspectiveCamera;
import js.three.Quaternion;
import js.three.Vector3;

/**
 * peppers ghost effect based on http://www.instructables.com/id/Reflective-Prism/?ALLSTEPS
 */
class PeppersGhostEffect {
    var cameraDistance:Float = 15;
    var reflectFromAbove:Bool;
    var _halfWidth:Float;
    var _width:Float;
    var _height:Float;
    var _cameraF:PerspectiveCamera;
    var _cameraB:PerspectiveCamera;
    var _cameraL:PerspectiveCamera;
    var _cameraR:PerspectiveCamera;
    var _position:Vector3;
    var _quaternion:Quaternion;
    var _scale:Vector3;

    function new(renderer:Dynamic) {
        _cameraF = new PerspectiveCamera(); //front
        _cameraB = new PerspectiveCamera(); //back
        _cameraL = new PerspectiveCamera(); //left
        _cameraR = new PerspectiveCamera(); //right

        _position = new Vector3();
        _quaternion = new Quaternion();
        _scale = new Vector3();

        renderer.autoClear = false;
    }

    function setSize(width:Float, height:Float) {
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

    function render(scene:Dynamic, camera:Dynamic) {
        if (scene.matrixWorldAutoUpdate)
            scene.updateMatrixWorld();

        if (camera.parent == null && camera.matrixWorldAutoUpdate)
            camera.updateMatrixWorld();

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
        _cameraB.rotation.z += 180 * (Std.Math.PI / 180);

        // left
        _cameraL.position.copy(_position);
        _cameraL.quaternion.copy(_quaternion);
        _cameraL.translateX(-cameraDistance);
        _cameraL.lookAt(scene.position);
        _cameraL.rotation.x += 90 * (Std.Math.PI / 180);

        // right
        _cameraR.position.copy(_position);
        _cameraR.quaternion.copy(_quaternion);
        _cameraR.translateX(cameraDistance);
        _cameraR.lookAt(scene.position);
        _cameraR.rotation.x += 90 * (Std.Math.PI / 180);

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