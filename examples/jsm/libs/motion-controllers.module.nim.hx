// three.hx/examples/jsm/libs/motion-controllers.module.hx

package libs.motionControllers;

import js.Promise;
import js.html.Window;
import js.html.XMLHttpRequest;
import js.html.XMLHttpRequestResponseType;
import js.html.XMLHttpRequestStatus;
import js.html.XMLHttpRequestReadyState;
import js.html.XMLHttpRequestUpload;
import js.html.XMLHttpRequestProgressEvent;
import js.html.XMLHttpRequestErrorEvent;
import js.html.XMLHttpRequestAbortEvent;
import js.html.XMLHttpRequestLoadEvent;
import js.html.XMLHttpRequestTimeoutEvent;
import js.html.XMLHttpRequestReadystatechangeEvent;
import js.html.XMLHttpRequestProgressEvent.ProgressEvent;
import js.html.XMLHttpRequestErrorEvent.ErrorEvent;
import js.html.XMLHttpRequestAbortEvent.AbortEvent;
import js.html.XMLHttpRequestLoadEvent.LoadEvent;
import js.html.XMLHttpRequestTimeoutEvent.TimeoutEvent;
import js.html.XMLHttpRequestReadystatechangeEvent.ReadystatechangeEvent;
import js.html.XMLHttpRequestUpload.Upload;
import js.html.XMLHttpRequestResponseType.ResponseType;
import js.html.XMLHttpRequestStatus.Status;
import js.html.XMLHttpRequestReadyState.ReadyState;
import js.html.XMLHttpRequestProgressEvent.ProgressEvent.ProgressEvent;
import js.html.XMLHttpRequestErrorEvent.ErrorEvent.ErrorEvent;
import js.html.XMLHttpRequestAbortEvent.AbortEvent.AbortEvent;
import js.html.XMLHttpRequestLoadEvent.LoadEvent.LoadEvent;
import js.html.XMLHttpRequestTimeoutEvent.TimeoutEvent.TimeoutEvent;
import js.html.XMLHttpRequestReadystatechangeEvent.ReadystatechangeEvent.ReadystatechangeEvent;
import js.html.XMLHttpRequestUpload.Upload.Upload;
import js.html.XMLHttpRequestResponseType.ResponseType.ResponseType;
import js.html.XMLHttpRequestStatus.Status.Status;
import js.html.XMLHttpRequestReadyState.ReadyState.ReadyState;

class Constants {
  public static var Handedness = {
    NONE: 'none',
    LEFT: 'left',
    RIGHT: 'right'
  };

  public static var ComponentState = {
    DEFAULT: 'default',
    TOUCHED: 'touched',
    PRESSED: 'pressed'
  };

  public static var ComponentProperty = {
    BUTTON: 'button',
    X_AXIS: 'xAxis',
    Y_AXIS: 'yAxis',
    STATE: 'state'
  };

  public static var ComponentType = {
    TRIGGER: 'trigger',
    SQUEEZE: 'squeeze',
    TOUCHPAD: 'touchpad',
    THUMBSTICK: 'thumbstick',
    BUTTON: 'button'
  };

  public static var ButtonTouchThreshold = 0.05;

  public static var AxisTouchThreshold = 0.1;

  public static var VisualResponseProperty = {
    TRANSFORM: 'transform',
    VISIBILITY: 'visibility'
  };
}

class MotionController {
  public var xrInputSource:Dynamic;
  public var profile:Dynamic;
  public var assetUrl:Dynamic;
  public var id:String;
  public var layoutDescription:Dynamic;
  public var components:Dynamic;

  public function new(xrInputSource:Dynamic, profile:Dynamic, assetUrl:Dynamic) {
    this.xrInputSource = xrInputSource;
    this.assetUrl = assetUrl;
    this.id = profile.profileId;

    this.layoutDescription = profile.layouts[xrInputSource.handedness];
    this.components = new Map<String, Component>();
    for (componentId in this.layoutDescription.components) {
      componentDescription = this.layoutDescription.components[componentId];
      this.components.set(componentId, new Component(componentId, componentDescription));
    }

    this.updateFromGamepad();
  }

  public function get gripSpace() {
    return this.xrInputSource.gripSpace;
  }

  public function get targetRaySpace() {
    return this.xrInputSource.targetRaySpace;
  }

  public function get data() {
    var data = [];
    for (component in this.components.values()) {
      data.push(component.data);
    }
    return data;
  }

  public function updateFromGamepad() {
    for (component in this.components.values()) {
      component.updateFromGamepad(this.xrInputSource.gamepad);
    }
  }
}

class Component {
  public var id:String;
  public var type:String;
  public var rootNodeName:String;
  public var touchPointNodeName:String;
  public var visualResponses:Dynamic;
  public var gamepadIndices:Dynamic;
  public var values:Dynamic;

  public function new(componentId:String, componentDescription:Dynamic) {
    if (!componentId || !componentDescription || !componentDescription.visualResponses || !componentDescription.gamepadIndices || Object.keys(componentDescription.gamepadIndices).length == 0) {
      throw new Error('Invalid arguments supplied');
    }

    this.id = componentId;
    this.type = componentDescription.type;
    this.rootNodeName = componentDescription.rootNodeName;
    this.touchPointNodeName = componentDescription.touchPointNodeName;

    this.visualResponses = new Map<String, VisualResponse>();
    for (responseName in componentDescription.visualResponses) {
      visualResponse = new VisualResponse(componentDescription.visualResponses[responseName]);
      this.visualResponses.set(responseName, visualResponse);
    }

    this.gamepadIndices = Object.assign({}, componentDescription.gamepadIndices);

    this.values = {
      state: Constants.ComponentState.DEFAULT,
      button: (this.gamepadIndices.button !== undefined) ? 0 : undefined,
      xAxis: (this.gamepadIndices.xAxis !== undefined) ? 0 : undefined,
      yAxis: (this.gamepadIndices.yAxis !== undefined) ? 0 : undefined
    };
  }

  public function get data() {
    var data = { id: this.id, ...this.values };
    return data;
  }

  public function updateFromGamepad(gamepad:Dynamic) {
    this.values.state = Constants.ComponentState.DEFAULT;

    if (this.gamepadIndices.button !== undefined && gamepad.buttons.length > this.gamepadIndices.button) {
      gamepadButton = gamepad.buttons[this.gamepadIndices.button];
      this.values.button = gamepadButton.value;
      this.values.button = (this.values.button < 0) ? 0 : this.values.button;
      this.values.button = (this.values.button > 1) ? 1 : this.values.button;

      if (gamepadButton.pressed || this.values.button == 1) {
        this.values.state = Constants.ComponentState.PRESSED;
      } else if (gamepadButton.touched || this.values.button > Constants.ButtonTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }

    if (this.gamepadIndices.xAxis !== undefined && gamepad.axes.length > this.gamepadIndices.xAxis) {
      this.values.xAxis = gamepad.axes[this.gamepadIndices.xAxis];
      this.values.xAxis = (this.values.xAxis < -1) ? -1 : this.values.xAxis;
      this.values.xAxis = (this.values.xAxis > 1) ? 1 : this.values.xAxis;

      if (this.values.state == Constants.ComponentState.DEFAULT && Math.abs(this.values.xAxis) > Constants.AxisTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }

    if (this.gamepadIndices.yAxis !== undefined && gamepad.axes.length > this.gamepadIndices.yAxis) {
      this.values.yAxis = gamepad.axes[this.gamepadIndices.yAxis];
      this.values.yAxis = (this.values.yAxis < -1) ? -1 : this.values.yAxis;
      this.values.yAxis = (this.values.yAxis > 1) ? 1 : this.values.yAxis;

      if (this.values.state == Constants.ComponentState.DEFAULT && Math.abs(this.values.yAxis) > Constants.AxisTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }

    for (visualResponse in this.visualResponses.values()) {
      visualResponse.updateFromComponent(this.values);
    }
  }
}

class VisualResponse {
  public var componentProperty:String;
  public var states:Dynamic;
  public var valueNodeName:String;
  public var valueNodeProperty:String;
  public var minNodeName:String;
  public var maxNodeName:String;
  public var value:Float;

  public function new(visualResponseDescription:Dynamic) {
    this.componentProperty = visualResponseDescription.componentProperty;
    this.states = visualResponseDescription.states;
    this.valueNodeName = visualResponseDescription.valueNodeName;
    this.valueNodeProperty = visualResponseDescription.valueNodeProperty;

    if (this.valueNodeProperty == Constants.VisualResponseProperty.TRANSFORM) {
      this.minNodeName = visualResponseDescription.minNodeName;
      this.maxNodeName = visualResponseDescription.maxNodeName;
    }

    this.value = 0;
    this.updateFromComponent(defaultComponentValues);
  }

  public function updateFromComponent(componentValues:Dynamic) {
    var { normalizedXAxis, normalizedYAxis } = normalizeAxes(componentValues.xAxis, componentValues.yAxis);
    switch (this.componentProperty) {
      case Constants.ComponentProperty.X_AXIS:
        this.value = (this.states.includes(componentValues.state)) ? normalizedXAxis : 0.5;
        break;
      case Constants.ComponentProperty.Y_AXIS:
        this.value = (this.states.includes(componentValues.state)) ? normalizedYAxis : 0.5;
        break;
      case Constants.ComponentProperty.BUTTON:
        this.value = (this.states.includes(componentValues.state)) ? componentValues.button : 0;
        break;
      case Constants.ComponentProperty.STATE:
        if (this.valueNodeProperty == Constants.VisualResponseProperty.VISIBILITY) {
          this.value = (this.states.includes(componentValues.state));
        } else {
          this.value = this.states.includes(componentValues.state) ? 1.0 : 0.0;
        }
        break;
      default:
        throw new Error('Unexpected visualResponse componentProperty ' + this.componentProperty);
    }
  }
}

function normalizeAxes(x:Float, y:Float):Dynamic {
  var xAxis = x;
  var yAxis = y;

  var hypotenuse = Math.sqrt((x * x) + (y * y));
  if (hypotenuse > 1) {
    var theta = Math.atan2(y, x);
    xAxis = Math.cos(theta);
    yAxis = Math.sin(theta);
  }

  var result = {
    normalizedXAxis: (xAxis * 0.5) + 0.5,
    normalizedYAxis: (yAxis * 0.5) + 0.5
  };
  return result;
}