import three.CylinderGeometry;
import three.CanvasTexture;
import three.Color;
import three.Euler;
import three.Mesh;
import three.MeshBasicMaterial;
import three.Object3D;
import three.OrthographicCamera;
import three.Quaternion;
import three.Raycaster;
import three.Sprite;
import three.SpriteMaterial;
import three.SRGBColorSpace;
import three.Vector2;
import three.Vector3;
import three.Vector4;

class ViewHelper extends Object3D {
    public var isViewHelper:Bool;
    public var animating:Bool;
    public var center:Vector3;

    private var color1:Color;
    private var color2:Color;
    private var color3:Color;
    private var color4:Color;

    private var interactiveObjects:Array<Sprite>;
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

    public function new(camera:OrthographicCamera, domElement:Dynamic) {
        super();

        this.isViewHelper = true;
        this.animating = false;
        this.center = new Vector3();

        this.color1 = new Color(0xff4466);
        this.color2 = new Color(0x88ff44);
        this.color3 = new Color(0x4488ff);
        this.color4 = new Color(0x000000);

        this.interactiveObjects = new Array<Sprite>();
        this.raycaster = new Raycaster();
        this.mouse = new Vector2();
        this.dummy = new Object3D();

        this.orthoCamera = new OrthographicCamera(-2, 2, 2, -2, 0, 4);
        this.orthoCamera.position.set(0, 0, 2);

        this.geometry = new CylinderGeometry(0.04, 0.04, 0.8, 5).rotateZ(-Math.PI / 2).translate(0.4, 0, 0);

        this.xAxis = new Mesh(this.geometry, this.getAxisMaterial(this.color1));
        this.yAxis = new Mesh(this.geometry, this.getAxisMaterial(this.color2));
        this.zAxis = new Mesh(this.geometry, this.getAxisMaterial(this.color3));

        this.yAxis.rotation.z = Math.PI / 2;
        this.zAxis.rotation.y = -Math.PI / 2;

        this.add(this.xAxis);
        this.add(this.zAxis);
        this.add(this.yAxis);

        this.spriteMaterial1 = this.getSpriteMaterial(this.color1);
        this.spriteMaterial2 = this.getSpriteMaterial(this.color2);
        this.spriteMaterial3 = this.getSpriteMaterial(this.color3);
        this.spriteMaterial4 = this.getSpriteMaterial(this.color4);

        this.posXAxisHelper = new Sprite(this.spriteMaterial1);
        this.posYAxisHelper = new Sprite(this.spriteMaterial2);
        this.posZAxisHelper = new Sprite(this.spriteMaterial3);
        this.negXAxisHelper = new Sprite(this.spriteMaterial4);
        this.negYAxisHelper = new Sprite(this.spriteMaterial4);
        this.negZAxisHelper = new Sprite(this.spriteMaterial4);

        this.posXAxisHelper.position.x = 1;
        this.posYAxisHelper.position.y = 1;
        this.posZAxisHelper.position.z = 1;
        this.negXAxisHelper.position.x = -1;
        this.negYAxisHelper.position.y = -1;
        this.negZAxisHelper.position.z = -1;

        this.negXAxisHelper.material.opacity = 0.2;
        this.negYAxisHelper.material.opacity = 0.2;
        this.negZAxisHelper.material.opacity = 0.2;

        this.posXAxisHelper.userData["type"] = "posX";
        this.posYAxisHelper.userData["type"] = "posY";
        this.posZAxisHelper.userData["type"] = "posZ";
        this.negXAxisHelper.userData["type"] = "negX";
        this.negYAxisHelper.userData["type"] = "negY";
        this.negZAxisHelper.userData["type"] = "negZ";

        this.add(this.posXAxisHelper);
        this.add(this.posYAxisHelper);
        this.add(this.posZAxisHelper);
        this.add(this.negXAxisHelper);
        this.add(this.negYAxisHelper);
        this.add(this.negZAxisHelper);

        this.interactiveObjects.push(this.posXAxisHelper);
        this.interactiveObjects.push(this.posYAxisHelper);
        this.interactiveObjects.push(this.posZAxisHelper);
        this.interactiveObjects.push(this.negXAxisHelper);
        this.interactiveObjects.push(this.negYAxisHelper);
        this.interactiveObjects.push(this.negZAxisHelper);

        this.point = new Vector3();
        this.dim = 128;
        this.turnRate = 2 * Math.PI;

        this.targetPosition = new Vector3();
        this.targetQuaternion = new Quaternion();

        this.q1 = new Quaternion();
        this.q2 = new Quaternion();
        this.viewport = new Vector4();
        this.radius = 0;
    }

    public function render(renderer:Dynamic) {
        this.quaternion.copy(camera.quaternion).invert();
        this.updateMatrixWorld();

        this.point.set(0, 0, 1);
        this.point.applyQuaternion(camera.quaternion);

        var x = domElement.offsetWidth - this.dim;

        renderer.clearDepth();

        renderer.getViewport(this.viewport);
        renderer.setViewport(x, 0, this.dim, this.dim);

        renderer.render(this, this.orthoCamera);

        renderer.setViewport(this.viewport.x, this.viewport.y, this.viewport.z, this.viewport.w);
    }

    public function handleClick(event:Dynamic):Bool {
        if (this.animating) return false;

        var rect = domElement.getBoundingClientRect();
        var offsetX = rect.left + (domElement.offsetWidth - this.dim);
        var offsetY = rect.top + (domElement.offsetHeight - this.dim);
        this.mouse.x = ((event.clientX - offsetX) / (rect.right - offsetX)) * 2 - 1;
        this.mouse.y = -((event.clientY - offsetY) / (rect.bottom - offsetY)) * 2 + 1;

        this.raycaster.setFromCamera(this.mouse, this.orthoCamera);

        var intersects = this.raycaster.intersectObjects(this.interactiveObjects);

        if (intersects.length > 0) {
            var intersection = intersects[0];
            var object = intersection.object;

            this.prepareAnimationData(object, this.center);

            this.animating = true;

            return true;
        } else {
            return false;
        }
    }

    public function update(delta:Float) {
        var step = delta * this.turnRate;

        this.q1.rotateTowards(this.q2, step);
        camera.position.set(0, 0, 1).applyQuaternion(this.q1).multiplyScalar(this.radius).add(this.center);

        camera.quaternion.rotateTowards(this.targetQuaternion, step);

        if (this.q1.angleTo(this.q2) == 0) {
            this.animating = false;
        }
    }

    public function dispose() {
        this.geometry.dispose();

        this.xAxis.material.dispose();
        this.yAxis.material.dispose();
        this.zAxis.material.dispose();

        this.posXAxisHelper.material.map.dispose();
        this.posYAxisHelper.material.map.dispose();
        this.posZAxisHelper.material.map.dispose();
        this.negXAxisHelper.material.map.dispose();
        this.negYAxisHelper.material.map.dispose();
        this.negZAxisHelper.material.map.dispose();

        this.posXAxisHelper.material.dispose();
        this.posYAxisHelper.material.dispose();
        this.posZAxisHelper.material.dispose();
        this.negXAxisHelper.material.dispose();
        this.negYAxisHelper.material.dispose();
        this.negZAxisHelper.material.dispose();
    }

    private function prepareAnimationData(object:Sprite, focusPoint:Vector3) {
        switch (object.userData["type"]) {
            case "posX":
                this.targetPosition.set(1, 0, 0);
                this.targetQuaternion.setFromEuler(new Euler(0, Math.PI * 0.5, 0));
                break;

            case "posY":
                this.targetPosition.set(0, 1, 0);
                this.targetQuaternion.setFromEuler(new Euler(-Math.PI * 0.5, 0, 0));
                break;

            case "posZ":
                this.targetPosition.set(0, 0, 1);
                this.targetQuaternion.setFromEuler(new Euler());
                break;

            case "negX":
                this.targetPosition.set(-1, 0, 0);
                this.targetQuaternion.setFromEuler(new Euler(0, -Math.PI * 0.5, 0));
                break;

            case "negY":
                this.targetPosition.set(0, -1, 0);
                this.targetQuaternion.setFromEuler(new Euler(Math.PI * 0.5, 0, 0));
                break;

            case "negZ":
                this.targetPosition.set(0, 0, -1);
                this.targetQuaternion.setFromEuler(new Euler(0, Math.PI, 0));
                break;

            default:
                trace("ViewHelper: Invalid axis.");
        }

        this.radius = camera.position.distanceTo(focusPoint);
        this.targetPosition.multiplyScalar(this.radius).add(focusPoint);

        this.dummy.position.copy(focusPoint);

        this.dummy.lookAt(camera.position);
        this.q1.copy(this.dummy.quaternion);

        this.dummy.lookAt(this.targetPosition);
        this.q2.copy(this.dummy.quaternion);
    }

    private function getAxisMaterial(color:Color):MeshBasicMaterial {
        return new MeshBasicMaterial({color: color, toneMapped: false});
    }

    private function getSpriteMaterial(color:Color):SpriteMaterial {
        // Haxe does not support Canvas directly, so you would need to use a library like hxCanvas to create the canvas and draw on it.
        // The following is a placeholder and does not actually create the SpriteMaterial.
        return new SpriteMaterial({map: null, toneMapped: false});
    }
}