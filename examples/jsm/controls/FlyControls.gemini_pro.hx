import three.core.EventDispatcher;
import three.math.Quaternion;
import three.math.Vector3;

class FlyControls extends EventDispatcher {

  public var object:Dynamic;
  public var domElement:Dynamic;

  // API

  // Set to false to disable this control
  public var enabled:Bool = true;

  public var movementSpeed:Float = 1.0;
  public var rollSpeed:Float = 0.005;

  public var dragToLook:Bool = false;
  public var autoForward:Bool = false;

  // disable default target object behavior

  // internals

  private var EPS:Float = 0.000001;

  private var lastQuaternion:Quaternion = new Quaternion();
  private var lastPosition:Vector3 = new Vector3();

  private var tmpQuaternion:Quaternion = new Quaternion();

  private var status:Int = 0;

  private var moveState:Dynamic = {
    up: 0,
    down: 0,
    left: 0,
    right: 0,
    forward: 0,
    back: 0,
    pitchUp: 0,
    pitchDown: 0,
    yawLeft: 0,
    yawRight: 0,
    rollLeft: 0,
    rollRight: 0
  };
  private var moveVector:Vector3 = new Vector3(0, 0, 0);
  private var rotationVector:Vector3 = new Vector3(0, 0, 0);

  public function new(object:Dynamic, domElement:Dynamic) {
    super();
    this.object = object;
    this.domElement = domElement;

    var scope = this;

    var _keydown = function(event:Dynamic) {
      if (event.altKey || !scope.enabled) {
        return;
      }
      switch (event.code) {
        case "ShiftLeft":
        case "ShiftRight":
          scope.movementSpeedMultiplier = 0.1;
          break;
        case "KeyW":
          scope.moveState.forward = 1;
          break;
        case "KeyS":
          scope.moveState.back = 1;
          break;
        case "KeyA":
          scope.moveState.left = 1;
          break;
        case "KeyD":
          scope.moveState.right = 1;
          break;
        case "KeyR":
          scope.moveState.up = 1;
          break;
        case "KeyF":
          scope.moveState.down = 1;
          break;
        case "ArrowUp":
          scope.moveState.pitchUp = 1;
          break;
        case "ArrowDown":
          scope.moveState.pitchDown = 1;
          break;
        case "ArrowLeft":
          scope.moveState.yawLeft = 1;
          break;
        case "ArrowRight":
          scope.moveState.yawRight = 1;
          break;
        case "KeyQ":
          scope.moveState.rollLeft = 1;
          break;
        case "KeyE":
          scope.moveState.rollRight = 1;
          break;
      }
      scope.updateMovementVector();
      scope.updateRotationVector();
    };

    var _keyup = function(event:Dynamic) {
      if (!scope.enabled) return;
      switch (event.code) {
        case "ShiftLeft":
        case "ShiftRight":
          scope.movementSpeedMultiplier = 1;
          break;
        case "KeyW":
          scope.moveState.forward = 0;
          break;
        case "KeyS":
          scope.moveState.back = 0;
          break;
        case "KeyA":
          scope.moveState.left = 0;
          break;
        case "KeyD":
          scope.moveState.right = 0;
          break;
        case "KeyR":
          scope.moveState.up = 0;
          break;
        case "KeyF":
          scope.moveState.down = 0;
          break;
        case "ArrowUp":
          scope.moveState.pitchUp = 0;
          break;
        case "ArrowDown":
          scope.moveState.pitchDown = 0;
          break;
        case "ArrowLeft":
          scope.moveState.yawLeft = 0;
          break;
        case "ArrowRight":
          scope.moveState.yawRight = 0;
          break;
        case "KeyQ":
          scope.moveState.rollLeft = 0;
          break;
        case "KeyE":
          scope.moveState.rollRight = 0;
          break;
      }
      scope.updateMovementVector();
      scope.updateRotationVector();
    };

    var _pointerdown = function(event:Dynamic) {
      if (!scope.enabled) return;
      if (scope.dragToLook) {
        scope.status++;
      } else {
        switch (event.button) {
          case 0:
            scope.moveState.forward = 1;
            break;
          case 2:
            scope.moveState.back = 1;
            break;
        }
        scope.updateMovementVector();
      }
    };

    var _pointermove = function(event:Dynamic) {
      if (!scope.enabled) return;
      if (!scope.dragToLook || scope.status > 0) {
        var container = scope.getContainerDimensions();
        var halfWidth = container.size[0] / 2;
        var halfHeight = container.size[1] / 2;
        scope.moveState.yawLeft = -((event.pageX - container.offset[0]) - halfWidth) / halfWidth;
        scope.moveState.pitchDown = ((event.pageY - container.offset[1]) - halfHeight) / halfHeight;
        scope.updateRotationVector();
      }
    };

    var _pointerup = function(event:Dynamic) {
      if (!scope.enabled) return;
      if (scope.dragToLook) {
        scope.status--;
        scope.moveState.yawLeft = 0;
        scope.moveState.pitchDown = 0;
      } else {
        switch (event.button) {
          case 0:
            scope.moveState.forward = 0;
            break;
          case 2:
            scope.moveState.back = 0;
            break;
        }
        scope.updateMovementVector();
      }
      scope.updateRotationVector();
    };

    var _pointercancel = function() {
      if (!scope.enabled) return;
      if (scope.dragToLook) {
        scope.status = 0;
        scope.moveState.yawLeft = 0;
        scope.moveState.pitchDown = 0;
      } else {
        scope.moveState.forward = 0;
        scope.moveState.back = 0;
        scope.updateMovementVector();
      }
      scope.updateRotationVector();
    };

    var _contextMenu = function(event:Dynamic) {
      if (!scope.enabled) return;
      event.preventDefault();
    };

    var _changeEvent:Dynamic = { type: "change" };

    this.update = function(delta:Float) {
      if (!scope.enabled) return;
      var moveMult = delta * scope.movementSpeed;
      var rotMult = delta * scope.rollSpeed;
      scope.object.translateX(scope.moveVector.x * moveMult);
      scope.object.translateY(scope.moveVector.y * moveMult);
      scope.object.translateZ(scope.moveVector.z * moveMult);
      scope.tmpQuaternion.set(
        scope.rotationVector.x * rotMult,
        scope.rotationVector.y * rotMult,
        scope.rotationVector.z * rotMult,
        1
      ).normalize();
      scope.object.quaternion.multiply(scope.tmpQuaternion);
      if (
        lastPosition.distanceToSquared(scope.object.position) > EPS ||
        8 * (1 - lastQuaternion.dot(scope.object.quaternion)) > EPS
      ) {
        scope.dispatchEvent(_changeEvent);
        lastQuaternion.copy(scope.object.quaternion);
        lastPosition.copy(scope.object.position);
      }
    };

    this.updateMovementVector = function() {
      var forward =
        scope.moveState.forward ||
        (scope.autoForward && !scope.moveState.back)
          ? 1
          : 0;
      scope.moveVector.x = -scope.moveState.left + scope.moveState.right;
      scope.moveVector.y = -scope.moveState.down + scope.moveState.up;
      scope.moveVector.z = -forward + scope.moveState.back;
      //console.log( 'move:', [ this.moveVector.x, this.moveVector.y, this.moveVector.z ] );
    };

    this.updateRotationVector = function() {
      scope.rotationVector.x =
        -scope.moveState.pitchDown + scope.moveState.pitchUp;
      scope.rotationVector.y =
        -scope.moveState.yawRight + scope.moveState.yawLeft;
      scope.rotationVector.z =
        -scope.moveState.rollRight + scope.moveState.rollLeft;
      //console.log( 'rotate:', [ this.rotationVector.x, this.rotationVector.y, this.rotationVector.z ] );
    };

    this.getContainerDimensions = function() {
      if (scope.domElement != document) {
        return {
          size: [scope.domElement.offsetWidth, scope.domElement.offsetHeight],
          offset: [
            scope.domElement.offsetLeft,
            scope.domElement.offsetTop
          ]
        };
      } else {
        return {
          size: [window.innerWidth, window.innerHeight],
          offset: [0, 0]
        };
      }
    };

    this.dispose = function() {
      scope.domElement.removeEventListener("contextmenu", _contextMenu);
      scope.domElement.removeEventListener("pointerdown", _pointerdown);
      scope.domElement.removeEventListener("pointermove", _pointermove);
      scope.domElement.removeEventListener("pointerup", _pointerup);
      scope.domElement.removeEventListener("pointercancel", _pointercancel);
      window.removeEventListener("keydown", _keydown);
      window.removeEventListener("keyup", _keyup);
    };

    scope.domElement.addEventListener("contextmenu", _contextMenu);
    scope.domElement.addEventListener("pointerdown", _pointerdown);
    scope.domElement.addEventListener("pointermove", _pointermove);
    scope.domElement.addEventListener("pointerup", _pointerup);
    scope.domElement.addEventListener("pointercancel", _pointercancel);
    window.addEventListener("keydown", _keydown);
    window.addEventListener("keyup", _keyup);

    scope.updateMovementVector();
    scope.updateRotationVector();
  }
}