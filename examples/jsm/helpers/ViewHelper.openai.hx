package three.js.examples.javascript.helpers;

import three.js.Object3D;
import three.js.CylinderGeometry;
import three.js.CanvasTexture;
import three.js.Color;
import three.js.Euler;
import three.js.Mesh;
import three.js.MeshBasicMaterial;
import three.js.OrthographicCamera;
import three.js.Quaternion;
import three.js.Raycaster;
import three.js.Sprite;
import three.js.SpriteMaterial;
import three.js.SRGBColorSpace;
import three.js.Vector2;
import three.js.Vector3;
import three.js.Vector4;

class ViewHelper extends Object3D
{
    public var isViewHelper:Bool = true;

    public var animating:Bool = false;
    public var center:Vector3;

    private var interactiveObjects:Array<Mesh>;
    private var raycaster:Raycaster;
    private var mouse:Vector2;
    private var dummy:Object3D;
    private var orthoCamera:OrthographicCamera;
    private var geometry:CylinderGeometry;
    private var xAxis:Mesh;
    private var yAxis:Mesh;
    private var zAxis:Mesh;
    private var spriteMaterial1:SpriteMaterial;
    private var spriteMaterial2:SpriteMaterial;
    private var spriteMaterial3:SpriteMaterial;
    private var spriteMaterial4:SpriteMaterial;
    private var posXAxisHelper:Sprite;
    private var posYAxisHelper:Sprite;
    private var posZAxisHelper:Sprite;
    private var negXAxisHelper:Sprite;
    private var negYAxisHelper:Sprite;
    private var negZAxisHelper:Sprite;
    private var point:Vector3;
    private var dim:Int;
    private var turnRate:Float;
    private var targetPosition:Vector3;
    private var targetQuaternion:Quaternion;
    private var q1:Quaternion;
    private var q2:Quaternion;
    private var viewport:Vector4;
    private var radius:Float;

    public function new(camera:Object3D, domElement:js.html.Element)
    {
        super();

        center = new Vector3();

        var color1:Color = new Color(0xff4466);
        var color2:Color = new Color(0x88ff44);
        var color3:Color = new Color(0x4488ff);
        var color4:Color = new Color(0x000000);

        interactiveObjects = [];
        raycaster = new Raycaster();
        mouse = new Vector2();
        dummy = new Object3D();

        orthoCamera = new OrthographicCamera(-2, 2, 2, -2, 0, 4);
        orthoCamera.position.set(0, 0, 2);

        geometry = new CylinderGeometry(0.04, 0.04, 0.8, 5).rotateZ(-Math.PI / 2).translate(0.4, 0, 0);

        xAxis = new Mesh(geometry, getAxisMaterial(color1));
        yAxis = new Mesh(geometry, getAxisMaterial(color2));
        zAxis = new Mesh(geometry, getAxisMaterial(color3));

        yAxis.rotation.z = Math.PI / 2;
        zAxis.rotation.y = -Math.PI / 2;

        this.add(xAxis);
        this.add(zAxis);
        this.add(yAxis);

        spriteMaterial1 = getSpriteMaterial(color1);
        spriteMaterial2 = getSpriteMaterial(color2);
        spriteMaterial3 = getSpriteMaterial(color3);
        spriteMaterial4 = getSpriteMaterial(color4);

        posXAxisHelper = new Sprite(spriteMaterial1);
        posYAxisHelper = new Sprite(spriteMaterial2);
        posZAxisHelper = new Sprite(spriteMaterial3);
        negXAxisHelper = new Sprite(spriteMaterial4);
        negYAxisHelper = new Sprite(spriteMaterial4);
        negZAxisHelper = new Sprite(spriteMaterial4);

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

        this.add(posXAxisHelper);
        this.add(posYAxisHelper);
        this.add(posZAxisHelper);
        this.add(negXAxisHelper);
        this.add(negYAxisHelper);
        this.add(negZAxisHelper);

        interactiveObjects.push(posXAxisHelper);
        interactiveObjects.push(posYAxisHelper);
        interactiveObjects.push(posZAxisHelper);
        interactiveObjects.push(negXAxisHelper);
        interactiveObjects.push(negYAxisHelper);
        interactiveObjects.push(negZAxisHelper);

        point = new Vector3();
        dim = 128;
        turnRate = 2 * Math.PI; // turn rate in angles per second

        this.render = function(renderer:three.js.WebGLRenderer)
        {
            this.quaternion.copy(camera.quaternion).invert();
            this.updateMatrixWorld();

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

        targetPosition = new Vector3();
        targetQuaternion = new Quaternion();
        q1 = new Quaternion();
        q2 = new Quaternion();
        viewport = new Vector4();
        radius = 0;

        this.handleClick = function(event:js.html.MouseEvent)
        {
            if (this.animating) return false;

            var rect = domElement.getBoundingClientRect();
            var offsetX = rect.left + (domElement.offsetWidth - dim);
            var offsetY = rect.top + (domElement.offsetHeight - dim);
            mouse.x = ((event.clientX - offsetX) / (rect.right - offsetX)) * 2 - 1;
            mouse.y = -((event.clientY - offsetY) / (rect.bottom - offsetY)) * 2 + 1;

            raycaster.setFromCamera(mouse, orthoCamera);

            var intersects:Array<RaycastResult> = raycaster.intersectObjects(interactiveObjects);

            if (intersects.length > 0)
            {
                var intersection:RaycastResult = intersects[0];
                var object:Object3D = intersection.object;

                prepareAnimationData(object, center);

                this.animating = true;

                return true;
            }
            else
            {
                return false;
            }
        };

        this.update = function(delta:Float)
        {
            var step:Float = delta * turnRate;

            // animate position by doing a slerp and then scaling the position on the unit sphere

            q1.rotateTowards(q2, step);
            camera.position.set(0, 0, 1).applyQuaternion(q1).multiplyScalar(radius).add(center);

            // animate orientation

            camera.quaternion.rotateTowards(targetQuaternion, step);

            if (q1.angleTo(q2) === 0)
            {
                this.animating = false;
            }
        };

        this.dispose = function()
        {
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
    }

    private function prepareAnimationData(object:Object3D, focusPoint:Vector3)
    {
        switch (object.userData.type)
        {
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
                js.Lib.debug('ViewHelper: Invalid axis.');
        }

        // 

        radius = camera.position.distanceTo(focusPoint);
        targetPosition.multiplyScalar(radius).add(focusPoint);

        dummy.position.copy(focusPoint);

        dummy.lookAt(camera.position);
        q1.copy(dummy.quaternion);

        dummy.lookAt(targetPosition);
        q2.copy(dummy.quaternion);
    }

    private function getAxisMaterial(color:Color):MeshBasicMaterial
    {
        return new MeshBasicMaterial({ color: color, toneMapped: false });
    }

    private function getSpriteMaterial(color:Color):SpriteMaterial
    {
        var canvas:js.html.CanvasElement = js.Browser.createElement('canvas');
        canvas.width = 64;
        canvas.height = 64;

        var context:js.html.CanvasRenderingContext2D = canvas.getContext('2d');
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