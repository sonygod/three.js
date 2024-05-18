package three.js.examples.jsm.helpers;

import three.Vector2;
import three.Vector3;
import three.Vector4;
import three.Quaternion;
import three.Euler;
import three.Color;
import three.Mesh;
import three.MeshBasicMaterial;
import three.Sprite;
import three.SpriteMaterial;
import three.CanvasTexture;
import three.SRGBColorSpace;
import three.Raycaster;
import three.Object3D;
import three.OrthographicCamera;
import three.CylinderGeometry;

class ViewHelper extends Object3D {

    public var isViewHelper:Bool;
    public var animating:Bool;
    public var center:Vector3;

    public function new(camera:Object3D, domElement:Dynamic) {
        super();

        isViewHelper = true;
        animating = false;
        center = new Vector3();

        var color1:Color = new Color(0xff4466);
        var color2:Color = new Color(0x88ff44);
        var color3:Color = new Color(0x4488ff);
        var color4:Color = new Color(0x000000);

        var interactiveObjects:Array<Object3D> = [];
        var raycaster:Raycaster = new Raycaster();
        var mouse:Vector2 = new Vector2();
        var dummy:Object3D = new Object3D();

        var orthoCamera:OrthographicCamera = new OrthographicCamera(-2, 2, 2, -2, 0, 4);
        orthoCamera.position.set(0, 0, 2);

        var geometry:CylinderGeometry = new CylinderGeometry(0.04, 0.04, 0.8, 5).rotateZ(-Math.PI / 2).translate(0.4, 0, 0);

        var xAxis:Mesh = new Mesh(geometry, getAxisMaterial(color1));
        var yAxis:Mesh = new Mesh(geometry, getAxisMaterial(color2));
        var zAxis:Mesh = new Mesh(geometry, getAxisMaterial(color3));

        yAxis.rotation.z = Math.PI / 2;
        zAxis.rotation.y = -Math.PI / 2;

        add(xAxis);
        add(yAxis);
        add(zAxis);

        var spriteMaterial1:SpriteMaterial = getSpriteMaterial(color1);
        var spriteMaterial2:SpriteMaterial = getSpriteMaterial(color2);
        var spriteMaterial3:SpriteMaterial = getSpriteMaterial(color3);
        var spriteMaterial4:SpriteMaterial = getSpriteMaterial(color4);

        var posXAxisHelper:Sprite = new Sprite(spriteMaterial1);
        var posYAxisHelper:Sprite = new Sprite(spriteMaterial2);
        var posZAxisHelper:Sprite = new Sprite(spriteMaterial3);
        var negXAxisHelper:Sprite = new Sprite(spriteMaterial4);
        var negYAxisHelper:Sprite = new Sprite(spriteMaterial4);
        var negZAxisHelper:Sprite = new Sprite(spriteMaterial4);

        posXAxisHelper.position.x = 1;
        posYAxisHelper.position.y = 1;
        posZAxisHelper.position.z = 1;
        negXAxisHelper.position.x = -1;
        negYAxisHelper.position.y = -1;
        negZAxisHelper.position.z = -1;

        negXAxisHelper.material.opacity = 0.2;
        negYAxisHelper.material.opacity = 0.2;
        negZAxisHelper.material.opacity = 0.2;

        posXAxisHelper.userData.type = 'posX';
        posYAxisHelper.userData.type = 'posY';
        posZAxisHelper.userData.type = 'posZ';
        negXAxisHelper.userData.type = 'negX';
        negYAxisHelper.userData.type = 'negY';
        negZAxisHelper.userData.type = 'negZ';

        add(posXAxisHelper);
        add(posYAxisHelper);
        add(posZAxisHelper);
        add(negXAxisHelper);
        add(negYAxisHelper);
        add(negZAxisHelper);

        interactiveObjects.push(posXAxisHelper);
        interactiveObjects.push(posYAxisHelper);
        interactiveObjects.push(posZAxisHelper);
        interactiveObjects.push(negXAxisHelper);
        interactiveObjects.push(negYAxisHelper);
        interactiveObjects.push(negZAxisHelper);

        var point:Vector3 = new Vector3();
        var dim:Int = 128;
        var turnRate:Float = 2 * Math.PI; // turn rate in angles per second

        render = function(renderer:Dynamic) {
            quaternion.copy(camera.quaternion).invert();
            updateMatrixWorld();

            point.set(0, 0, 1);
            point.applyQuaternion(camera.quaternion);

            //

            var x:Int = domElement.offsetWidth - dim;

            renderer.clearDepth();

            renderer.getViewport(viewport);
            renderer.setViewport(x, 0, dim, dim);

            renderer.render(this, orthoCamera);

            renderer.setViewport(viewport.x, viewport.y, viewport.z, viewport.w);
        };

        var targetPosition:Vector3 = new Vector3();
        var targetQuaternion:Quaternion = new Quaternion();

        var q1:Quaternion = new Quaternion();
        var q2:Quaternion = new Quaternion();
        var viewport:Vector4 = new Vector4();
        var radius:Float = 0;

        handleClick = function(event:Dynamic) {
            if (animating) return false;

            var rect:Dynamic = domElement.getBoundingClientRect();
            var offsetX:Float = rect.left + (domElement.offsetWidth - dim);
            var offsetY:Float = rect.top + (domElement.offsetHeight - dim);
            mouse.x = ((event.clientX - offsetX) / (rect.right - offsetX)) * 2 - 1;
            mouse.y = -((event.clientY - offsetY) / (rect.bottom - offsetY)) * 2 + 1;

            raycaster.setFromCamera(mouse, orthoCamera);

            var intersects:Array<Dynamic> = raycaster.intersectObjects(interactiveObjects);

            if (intersects.length > 0) {
                var intersection:Dynamic = intersects[0];
                var object:Object3D = intersection.object;

                prepareAnimationData(object, center);

                animating = true;

                return true;
            } else {
                return false;
            }
        };

        update = function(delta:Float) {
            var step:Float = delta * turnRate;

            q1.rotateTowards(q2, step);
            camera.position.set(0, 0, 1).applyQuaternion(q1).multiplyScalar(radius).add(center);

            camera.quaternion.rotateTowards(targetQuaternion, step);

            if (q1.angleTo(q2) == 0) {
                animating = false;
            }
        };

        dispose = function() {
            geometry.dispose();

            xAxis.material.dispose();
            yAxis.material.dispose();
            zAxis.material.dispose();

            posXAxisHelper.material.map.dispose();
            posYAxisHelper.material.map.dispose();
            posZAxisHelper.material.map.dispose();
            negXAxisHelper.material.map.dispose();
            negYAxisHelper.material.map.dispose();
            negZAxisHelper.material.map.dispose();

            posXAxisHelper.material.dispose();
            posYAxisHelper.material.dispose();
            posZAxisHelper.material.dispose();
            negXAxisHelper.material.dispose();
            negYAxisHelper.material.dispose();
            negZAxisHelper.material.dispose();
        };

        function prepareAnimationData(object:Object3D, focusPoint:Vector3) {
            switch (object.userData.type) {
                case 'posX':
                    targetPosition.set(1, 0, 0);
                    targetQuaternion.setFromEuler(new Euler(0, Math.PI * 0.5, 0));
                    break;
                case 'posY':
                    targetPosition.set(0, 1, 0);
                    targetQuaternion.setFromEuler(new Euler(-Math.PI * 0.5, 0, 0));
                    break;
                case 'posZ':
                    targetPosition.set(0, 0, 1);
                    targetQuaternion.setFromEuler(new Euler());
                    break;
                case 'negX':
                    targetPosition.set(-1, 0, 0);
                    targetQuaternion.setFromEuler(new Euler(0, -Math.PI * 0.5, 0));
                    break;
                case 'negY':
                    targetPosition.set(0, -1, 0);
                    targetQuaternion.setFromEuler(new Euler(Math.PI * 0.5, 0, 0));
                    break;
                case 'negZ':
                    targetPosition.set(0, 0, -1);
                    targetQuaternion.setFromEuler(new Euler(0, Math.PI, 0));
                    break;
                default:
                    console.error('ViewHelper: Invalid axis.');
            }

            radius = camera.position.distanceTo(focusPoint);
            targetPosition.multiplyScalar(radius).add(focusPoint);

            dummy.position.copy(focusPoint);

            dummy.lookAt(camera.position);
            q1.copy(dummy.quaternion);

            dummy.lookAt(targetPosition);
            q2.copy(dummy.quaternion);
        }

        function getAxisMaterial(color:Color) {
            return new MeshBasicMaterial({ color: color, toneMapped: false });
        }

        function getSpriteMaterial(color:Color) {
            var canvas:Dynamic = document.createElement('canvas');
            canvas.width = 64;
            canvas.height = 64;

            var context:Dynamic = canvas.getContext('2d');
            context.beginPath();
            context.arc(32, 32, 14, 0, 2 * Math.PI);
            context.closePath();
            context.fillStyle = color.getStyle();
            context.fill();

            var texture:CanvasTexture = new CanvasTexture(canvas);
            texture.colorSpace = SRGBColorSpace;

            return new SpriteMaterial({ map: texture, toneMapped: false });
        }
    }
}