import three.core.EventDispatcher;
import three.core.Object3D;
import three.math.Box3;
import three.math.Matrix3;
import three.math.Spherical;
import three.math.Sphere;
import three.math.Vector2;
import three.math.Vector3;

@:enum abstract STATE(Int) {
  var NONE = -1;
  var ROTATE = 0;
  var ZOOM = 1;
  var PAN = 2;
}

class EditorControls extends EventDispatcher {

  public var enabled:Bool;
  public var center:Vector3;
  public var panSpeed:Float;
  public var zoomSpeed:Float;
  public var rotationSpeed:Float;

  private var object:Object3D;
  private var domElement:js.html.Element;

  private var vector:Vector3;
  private var delta:Vector3;
  private var box:Box3;
  private var state:STATE;
  private var normalMatrix:Matrix3;
  private var pointer:Vector2;
  private var pointerOld:Vector2;
  private var spherical:Spherical;
  private var sphere:Sphere;

  private var pointers:Array<Int>;
  private var pointerPositions:Map<Int, Vector2>;

  public function new(object:Object3D, domElement:js.html.Element) {
    super();

    this.object = object;
    this.domElement = domElement;

    this.enabled = true;
    this.center = new Vector3();
    this.panSpeed = 0.002;
    this.zoomSpeed = 0.1;
    this.rotationSpeed = 0.005;

    this.vector = new Vector3();
    this.delta = new Vector3();
    this.box = new Box3();

    this.state = STATE.NONE;

    this.normalMatrix = new Matrix3();
    this.pointer = new Vector2();
    this.pointerOld = new Vector2();
    this.spherical = new Spherical();
    this.sphere = new Sphere();

    this.pointers = [];
    this.pointerPositions = new Map();

    domElement.addEventListener("contextmenu", contextmenu);
    domElement.addEventListener("dblclick", onMouseUp);
    domElement.addEventListener("wheel", onMouseWheel, { passive: false });

    domElement.addEventListener("pointerdown", onPointerDown);
  }

  public function focus(target:Object3D):Void {
    var distance:Float;

    box.setFromObject(target);

    if (!box.isEmpty()) {
      box.getCenter(center);
      distance = box.getBoundingSphere(sphere).radius;
    } else {
      // Focusing on an Group, AmbientLight, etc

      center.setFromMatrixPosition(target.matrixWorld);
      distance = 0.1;
    }

    delta.set(0, 0, 1);
    delta.applyQuaternion(object.quaternion);
    delta.multiplyScalar(distance * 4);

    object.position.copy(center).add(delta);

    dispatchEvent({ type: "change" });
  }

  public function pan(delta:Vector3):Void {
    var distance = object.position.distanceTo(center);

    delta.multiplyScalar(distance * panSpeed);
    delta.applyMatrix3(normalMatrix.getNormalMatrix(object.matrix));

    object.position.add(delta);
    center.add(delta);

    dispatchEvent({ type: "change" });
  }

  public function zoom(delta:Vector3):Void {
    var distance = object.position.distanceTo(center);

    delta.multiplyScalar(distance * zoomSpeed);

    if (delta.length() > distance) {
      return;
    }

    delta.applyMatrix3(normalMatrix.getNormalMatrix(object.matrix));

    object.position.add(delta);

    dispatchEvent({ type: "change" });
  }

  public function rotate(delta:Vector3):Void {
    vector.copy(object.position).sub(center);

    spherical.setFromVector3(vector);

    spherical.theta += delta.x * rotationSpeed;
    spherical.phi += delta.y * rotationSpeed;

    spherical.makeSafe();

    vector.setFromSpherical(spherical);

    object.position.copy(center).add(vector);

    object.lookAt(center);

    dispatchEvent({ type: "change" });
  }

  private function onPointerDown(event:js.jquery.JQueryEventObject):Void {
    var e:Dynamic = event;
    if (!enabled) {
      return;
    }

    if (pointers.length == 0) {
      domElement.setPointerCapture(e.pointerId);

      domElement.ownerDocument.addEventListener("pointermove", onPointerMove);
      domElement.ownerDocument.addEventListener("pointerup", onPointerUp);
    }

    if (isTrackingPointer(e)) {
      return;
    }

    addPointer(e);

    if (e.pointerType == "touch") {
      onTouchStart(e);
    } else {
      onMouseDown(e);
    }
  }

  private function onPointerMove(event:js.jquery.JQueryEventObject):Void {
    var e:Dynamic = event;
    if (!enabled) {
      return;
    }

    if (e.pointerType == "touch") {
      onTouchMove(e);
    } else {
      onMouseMove(e);
    }
  }

  private function onPointerUp(event:js.jquery.JQueryEventObject):Void {
    var e:Dynamic = event;
    removePointer(e);

    switch (pointers.length) {
      case 0:
        domElement.releasePointerCapture(e.pointerId);

        domElement.ownerDocument.removeEventListener("pointermove", onPointerMove);
        domElement.ownerDocument.removeEventListener("pointerup", onPointerUp);
      case 1:
        var pointerId = pointers[0];
        var position = pointerPositions.get(pointerId);

        // minimal placeholder event - allows state correction on pointer-up
        onTouchStart({
          pointerId: pointerId,
          pageX: position.x,
          pageY: position.y
        });
      default:
    }
  }

  private function onMouseDown(event:Dynamic):Void {
    if (event.button == 0) {
      state = STATE.ROTATE;
    } else if (event.button == 1) {
      state = STATE.ZOOM;
    } else if (event.button == 2) {
      state = STATE.PAN;
    }

    pointerOld.set(event.clientX, event.clientY);
  }

  private function onMouseMove(event:Dynamic):Void {
    pointer.set(event.clientX, event.clientY);

    var movementX = pointer.x - pointerOld.x;
    var movementY = pointer.y - pointerOld.y;

    switch (state) {
      case ROTATE:
        rotate(delta.set(-movementX, -movementY, 0));
      case ZOOM:
        zoom(delta.set(0, 0, movementY));
      case PAN:
        pan(delta.set(-movementX, movementY, 0));
      default:
    }

    pointerOld.set(event.clientX, event.clientY);
  }

  private function onMouseUp(event:Dynamic):Void {
    state = STATE.NONE;
  }

  private function onMouseWheel(event:js.jquery.JQueryEventObject):Void {
    var e:Dynamic = event;
    if (!enabled) {
      return;
    }

    e.preventDefault();

    // Normalize deltaY due to https://bugzilla.mozilla.org/show_bug.cgi?id=1392460
    zoom(delta.set(0, 0, e.deltaY > 0 ? 1 : -1));
  }

  private function contextmenu(event:Dynamic):Void {
    event.preventDefault();
  }

  public function dispose():Void {
    domElement.removeEventListener("contextmenu", contextmenu);
    domElement.removeEventListener("dblclick", onMouseUp);
    domElement.removeEventListener("wheel", onMouseWheel);

    domElement.removeEventListener("pointerdown", onPointerDown);
  }

  // touch

  private var touches:Array<Vector3> = [new Vector3(), new Vector3(), new Vector3()];
  private var prevTouches:Array<Vector3> = [new Vector3(), new Vector3(), new Vector3()];

  private var prevDistance:Float = null;

  private function onTouchStart(event:Dynamic):Void {
    trackPointer(event);

    switch (pointers.length) {
      case 1:
        touches[0].set(event.pageX, event.pageY, 0).divideScalar(js.Browser.window.devicePixelRatio);
        touches[1].set(event.pageX, event.pageY, 0).divideScalar(js.Browser.window.devicePixelRatio);
      case 2:
        var position = getSecondPointerPosition(event);

        touches[0].set(event.pageX, event.pageY, 0).divideScalar(js.Browser.window.devicePixelRatio);
        touches[1].set(position.x, position.y, 0).divideScalar(js.Browser.window.devicePixelRatio);
        prevDistance = touches[0].distanceTo(touches[1]);
      default:
    }

    prevTouches[0].copy(touches[0]);
    prevTouches[1].copy(touches[1]);
  }

  private function onTouchMove(event:Dynamic):Void {
    trackPointer(event);

    switch (pointers.length) {
      case 1:
        touches[0].set(event.pageX, event.pageY, 0).divideScalar(js.Browser.window.devicePixelRatio);
        touches[1].set(event.pageX, event.pageY, 0).divideScalar(js.Browser.window.devicePixelRatio);
        rotate(touches[0].sub(getClosest(touches[0], prevTouches)).multiplyScalar(-1));
      case 2:
        var position = getSecondPointerPosition(event);

        touches[0].set(event.pageX, event.pageY, 0).divideScalar(js.Browser.window.devicePixelRatio);
        touches[1].set(position.x, position.y, 0).divideScalar(js.Browser.window.devicePixelRatio);
        var distance = touches[0].distanceTo(touches[1]);
        zoom(delta.set(0, 0, prevDistance - distance));
        prevDistance = distance;

        var offset0 = touches[0].clone().sub(getClosest(touches[0], prevTouches));
        var offset1 = touches[1].clone().sub(getClosest(touches[1], prevTouches));
        offset0.x = -offset0.x;
        offset1.x = -offset1.x;

        pan(offset0.add(offset1));
      default:
    }

    prevTouches[0].copy(touches[0]);
    prevTouches[1].copy(touches[1]);
  }

  private function getClosest(touch:Vector3, touches:Array<Vector3>):Vector3 {
    var closest = touches[0];

    for (touch2 in touches) {
      if (closest.distanceTo(touch) > touch2.distanceTo(touch)) {
        closest = touch2;
      }
    }

    return closest;
  }

  private function addPointer(event:Dynamic):Void {
    pointers.push(event.pointerId);
    pointerPositions.set(event.pointerId, new Vector2());
  }

  private function removePointer(event:Dynamic):Void {
    pointerPositions.remove(event.pointerId);

    for (i in 0...pointers.length) {
      if (pointers[i] == event.pointerId) {
        pointers.splice(i, 1);
        return;
      }
    }
  }

  private function isTrackingPointer(event:Dynamic):Bool {
    for (i in 0...pointers.length) {
      if (pointers[i] == event.pointerId) {
        return true;
      }
    }

    return false;
  }

  private function trackPointer(event:Dynamic):Void {
    var position = pointerPositions.get(event.pointerId);

    if (position == null) {
      position = new Vector2();
      pointerPositions.set(event.pointerId, position);
    }

    position.set(event.pageX, event.pageY);
  }

  private function getSecondPointerPosition(event:Dynamic):Vector2 {
    var pointerId = (event.pointerId == pointers[0]) ? pointers[1] : pointers[0];

    return pointerPositions.get(pointerId);
  }
}