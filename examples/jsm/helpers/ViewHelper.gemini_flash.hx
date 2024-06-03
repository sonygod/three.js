import three.core.Object3D;
import three.core.Quaternion;
import three.core.Vector2;
import three.core.Vector3;
import three.core.Vector4;
import three.core.Euler;
import three.core.Color;
import three.geometries.CylinderGeometry;
import three.materials.MeshBasicMaterial;
import three.objects.Mesh;
import three.cameras.OrthographicCamera;
import three.math.Raycaster;
import three.objects.Sprite;
import three.materials.SpriteMaterial;
import three.textures.CanvasTexture;
import three.constants.SRGBColorSpace;

class ViewHelper extends Object3D {

  public var animating:Bool;
  public var center:Vector3;
  public var render:Dynamic;
  public var handleClick:Dynamic;
  public var update:Dynamic;
  public var dispose:Dynamic;

  public function new(camera:Dynamic, domElement:Dynamic) {
    super();

    animating = false;
    center = new Vector3();

    var color1 = new Color(0xff4466);
    var color2 = new Color(0x88ff44);
    var color3 = new Color(0x4488ff);
    var color4 = new Color(0x000000);

    var interactiveObjects:Array<Dynamic> = [];
    var raycaster = new Raycaster();
    var mouse = new Vector2();
    var dummy = new Object3D();

    var orthoCamera = new OrthographicCamera(- 2, 2, 2, - 2, 0, 4);
    orthoCamera.position.set(0, 0, 2);

    var geometry = new CylinderGeometry(0.04, 0.04, 0.8, 5).rotateZ(- Math.PI / 2).translate(0.4, 0, 0);

    var xAxis = new Mesh(geometry, getAxisMaterial(color1));
    var yAxis = new Mesh(geometry, getAxisMaterial(color2));
    var zAxis = new Mesh(geometry, getAxisMaterial(color3));

    yAxis.rotation.z = Math.PI / 2;
    zAxis.rotation.y = - Math.PI / 2;

    this.add(xAxis);
    this.add(zAxis);
    this.add(yAxis);

    var spriteMaterial1 = getSpriteMaterial(color1);
    var spriteMaterial2 = getSpriteMaterial(color2);
    var spriteMaterial3 = getSpriteMaterial(color3);
    var spriteMaterial4 = getSpriteMaterial(color4);

    var posXAxisHelper = new Sprite(spriteMaterial1);
    var posYAxisHelper = new Sprite(spriteMaterial2);
    var posZAxisHelper = new Sprite(spriteMaterial3);
    var negXAxisHelper = new Sprite(spriteMaterial4);
    var negYAxisHelper = new Sprite(spriteMaterial4);
    var negZAxisHelper = new Sprite(spriteMaterial4);

    posXAxisHelper.position.x = 1;
    posYAxisHelper.position.y = 1;
    posZAxisHelper.position.z = 1;
    negXAxisHelper.position.x = - 1;
    negYAxisHelper.position.y = - 1;
    negZAxisHelper.position.z = - 1;

    negXAxisHelper.material.opacity = 0.2;
    negYAxisHelper.material.opacity = 0.2;
    negZAxisHelper.material.opacity = 0.2;

    posXAxisHelper.userData.type = "posX";
    posYAxisHelper.userData.type = "posY";
    posZAxisHelper.userData.type = "posZ";
    negXAxisHelper.userData.type = "negX";
    negYAxisHelper.userData.type = "negY";
    negZAxisHelper.userData.type = "negZ";

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

    var point = new Vector3();
    var dim = 128;
    var turnRate = 2 * Math.PI;

    this.render = function(renderer:Dynamic) {
      this.quaternion.copy(camera.quaternion).invert();
      this.updateMatrixWorld();

      point.set(0, 0, 1);
      point.applyQuaternion(camera.quaternion);

      var x = domElement.offsetWidth - dim;

      renderer.clearDepth();

      renderer.getViewport(viewport);
      renderer.setViewport(x, 0, dim, dim);

      renderer.render(this, orthoCamera);

      renderer.setViewport(viewport.x, viewport.y, viewport.z, viewport.w);
    };

    var targetPosition = new Vector3();
    var targetQuaternion = new Quaternion();

    var q1 = new Quaternion();
    var q2 = new Quaternion();
    var viewport = new Vector4();
    var radius = 0;

    this.handleClick = function(event:Dynamic) {
      if (this.animating) return false;

      var rect = domElement.getBoundingClientRect();
      var offsetX = rect.left + (domElement.offsetWidth - dim);
      var offsetY = rect.top + (domElement.offsetHeight - dim);
      mouse.x = ((event.clientX - offsetX) / (rect.right - offsetX)) * 2 - 1;
      mouse.y = -((event.clientY - offsetY) / (rect.bottom - offsetY)) * 2 + 1;

      raycaster.setFromCamera(mouse, orthoCamera);

      var intersects = raycaster.intersectObjects(interactiveObjects);

      if (intersects.length > 0) {
        var intersection = intersects[0];
        var object = intersection.object;

        prepareAnimationData(object, this.center);

        this.animating = true;

        return true;
      } else {
        return false;
      }
    };

    this.update = function(delta:Float) {
      var step = delta * turnRate;

      q1.rotateTowards(q2, step);
      camera.position.set(0, 0, 1).applyQuaternion(q1).multiplyScalar(radius).add(this.center);

      camera.quaternion.rotateTowards(targetQuaternion, step);

      if (q1.angleTo(q2) == 0) {
        this.animating = false;
      }
    };

    this.dispose = function() {
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

    function prepareAnimationData(object:Dynamic, focusPoint:Vector3) {
      switch (object.userData.type) {
        case "posX":
          targetPosition.set(1, 0, 0);
          targetQuaternion.setFromEuler(new Euler(0, Math.PI * 0.5, 0));
          break;
        case "posY":
          targetPosition.set(0, 1, 0);
          targetQuaternion.setFromEuler(new Euler(- Math.PI * 0.5, 0, 0));
          break;
        case "posZ":
          targetPosition.set(0, 0, 1);
          targetQuaternion.setFromEuler(new Euler());
          break;
        case "negX":
          targetPosition.set(- 1, 0, 0);
          targetQuaternion.setFromEuler(new Euler(0, - Math.PI * 0.5, 0));
          break;
        case "negY":
          targetPosition.set(0, - 1, 0);
          targetQuaternion.setFromEuler(new Euler(Math.PI * 0.5, 0, 0));
          break;
        case "negZ":
          targetPosition.set(0, 0, - 1);
          targetQuaternion.setFromEuler(new Euler(0, Math.PI, 0));
          break;
        default:
          js.Lib.console.error("ViewHelper: Invalid axis.");
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
      return new MeshBasicMaterial({color: color, toneMapped: false});
    }

    function getSpriteMaterial(color:Color) {
      var canvas = js.html.document.createElement("canvas");
      canvas.width = 64;
      canvas.height = 64;

      var context = canvas.getContext("2d");
      context.beginPath();
      context.arc(32, 32, 14, 0, 2 * Math.PI);
      context.closePath();
      context.fillStyle = color.getStyle();
      context.fill();

      var texture = new CanvasTexture(canvas);
      texture.colorSpace = SRGBColorSpace;

      return new SpriteMaterial({map: texture, toneMapped: false});
    }
  }
}