package three.js.examples.jsm.libs.motion_controllers;

import js.html.XMLHttpRequest;
import js.Promise;
import js.html.XMLHttpRequestResponseType;

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

class MotionControllers {
  public static function fetchJsonFile(path:String):Promise<String> {
    var xhr = new XMLHttpRequest();
    xhr.open('GET', path, true);
    xhr.responseType = XMLHttpRequestResponseType.TEXT;
    xhr.onload = function() {
      if (xhr.status == 200) {
        return xhr.responseText;
      } else {
        throw new Error(xhr.statusText);
      }
    };
    xhr.send();
    return Promise.fromJS(xhr);
  }

  public static function fetchProfilesList(basePath:String):Promise<String> {
    if (basePath == null) {
      throw new Error('No basePath supplied');
    }
    var profileListFileName = 'profilesList.json';
    return fetchJsonFile('${basePath}/${profileListFileName}');
  }

  public static function fetchProfile(xrInputSource:Dynamic, basePath:String, ?defaultProfile:String, getAssetPath:Bool = true):Promise<MotionController> {
    if (xrInputSource == null) {
      throw new Error('No xrInputSource supplied');
    }
    if (basePath == null) {
      throw new Error('No basePath supplied');
    }
    var supportedProfilesList = fetchProfilesList(basePath);
    var match:Dynamic = null;
    xrInputSource.profiles.some(function(profileId) {
      var supportedProfile = supportedProfilesList[profileId];
      if (supportedProfile != null) {
        match = {
          profileId: profileId,
          profilePath: '${basePath}/${supportedProfile.path}',
          deprecated: supportedProfile.deprecated != null
        };
      }
      return match != null;
    });
    if (match == null) {
      if (defaultProfile == null) {
        throw new Error('No matching profile name found');
      }
      var supportedProfile = supportedProfilesList[defaultProfile];
      if (supportedProfile == null) {
        throw new Error('No matching profile name found and default profile "${defaultProfile}" missing.');
      }
      match = {
        profileId: defaultProfile,
        profilePath: '${basePath}/${supportedProfile.path}',
        deprecated: supportedProfile.deprecated != null
      };
    }
    var profile = fetchJsonFile(match.profilePath);
    var assetPath:String = null;
    if (getAssetPath) {
      var layout:Dynamic = xrInputSource.handedness == 'any' ? profile.layouts[Reflect.fields(profile.layouts)[0]] : profile.layouts[xrInputSource.handedness];
      if (layout == null) {
        throw new Error('No matching handedness, ${xrInputSource.handedness}, in profile ${match.profileId}');
      }
      if (layout.assetPath != null) {
        assetPath = match.profilePath.replace('profile.json', layout.assetPath);
      }
    }
    return new MotionController(xrInputSource, profile, assetPath);
  }
}

class VisualResponse {
  public var componentProperty:String;
  public var states:Array<String>;
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
    updateFromComponent(defaultComponentValues);
  }

  public function updateFromComponent(componentValues:Dynamic) {
    var { xAxis, yAxis, button, state } = componentValues;
    var { normalizedXAxis, normalizedYAxis } = normalizeAxes(xAxis, yAxis);
    switch (this.componentProperty) {
      case Constants.ComponentProperty.X_AXIS:
        this.value = (this.states.includes(state)) ? normalizedXAxis : 0.5;
      case Constants.ComponentProperty.Y_AXIS:
        this.value = (this.states.includes(state)) ? normalizedYAxis : 0.5;
      case Constants.ComponentProperty.BUTTON:
        this.value = (this.states.includes(state)) ? button : 0;
      case Constants.ComponentProperty.STATE:
        if (this.valueNodeProperty == Constants.VisualResponseProperty.VISIBILITY) {
          this.value = (this.states.includes(state));
        } else {
          this.value = this.states.includes(state) ? 1.0 : 0.0;
        }
      default:
        throw new Error('Unexpected visualResponse componentProperty ${this.componentProperty}');
    }
  }
}

class Component {
  public var id:String;
  public var type:String;
  public var rootNodeName:String;
  public var touchPointNodeName:String;
  public var gamepadIndices:Dynamic;
  public var values:Dynamic;
  public var visualResponses:Dynamic;

  public function new(componentId:String, componentDescription:Dynamic) {
    if (!componentId || !componentDescription || !componentDescription.visualResponses || !componentDescription.gamepadIndices || Reflect.fields(componentDescription.gamepadIndices).length == 0) {
      throw new Error('Invalid arguments supplied');
    }
    this.id = componentId;
    this.type = componentDescription.type;
    this.rootNodeName = componentDescription.rootNodeName;
    this.touchPointNodeName = componentDescription.touchPointNodeName;
    this.visualResponses = {};
    for (responseName in Reflect.fields(componentDescription.visualResponses)) {
      var visualResponse = new VisualResponse(componentDescription.visualResponses[responseName]);
      this.visualResponses[responseName] = visualResponse;
    }
    this.gamepadIndices = Reflect.copy(componentDescription.gamepadIndices);
    this.values = {
      state: Constants.ComponentState.DEFAULT,
      button: this.gamepadIndices.button != null ? 0 : null,
      xAxis: this.gamepadIndices.xAxis != null ? 0 : null,
      yAxis: this.gamepadIndices.yAxis != null ? 0 : null
    };
  }

  public function get_data():Dynamic {
    var data = { id: this.id, state: this.values.state, button: this.values.button, xAxis: this.values.xAxis, yAxis: this.values.yAxis };
    return data;
  }

  public function updateFromGamepad(gamepad:Dynamic) {
    this.values.state = Constants.ComponentState.DEFAULT;
    if (this.gamepadIndices.button != null && gamepad.buttons.length > this.gamepadIndices.button) {
      var gamepadButton = gamepad.buttons[this.gamepadIndices.button];
      this.values.button = gamepadButton.value;
      this.values.button = (this.values.button < 0) ? 0 : this.values.button;
      this.values.button = (this.values.button > 1) ? 1 : this.values.button;
      if (gamepadButton.pressed || this.values.button == 1) {
        this.values.state = Constants.ComponentState.PRESSED;
      } else if (gamepadButton.touched || this.values.button > Constants.ButtonTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }
    if (this.gamepadIndices.xAxis != null && gamepad.axes.length > this.gamepadIndices.xAxis) {
      this.values.xAxis = gamepad.axes[this.gamepadIndices.xAxis];
      this.values.xAxis = (this.values.xAxis < -1) ? -1 : this.values.xAxis;
      this.values.xAxis = (this.values.xAxis > 1) ? 1 : this.values.xAxis;
      if (this.values.state == Constants.ComponentState.DEFAULT && Math.abs(this.values.xAxis) > Constants.AxisTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }
    if (this.gamepadIndices.yAxis != null && gamepad.axes.length > this.gamepadIndices.yAxis) {
      this.values.yAxis = gamepad.axes[this.gamepadIndices.yAxis];
      this.values.yAxis = (this.values.yAxis < -1) ? -1 : this.values.yAxis;
      this.values.yAxis = (this.values.yAxis > 1) ? 1 : this.values.yAxis;
      if (this.values.state == Constants.ComponentState.DEFAULT && Math.abs(this.values.yAxis) > Constants.AxisTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }
    for (responseName in Reflect.fields(this.visualResponses)) {
      this.visualResponses[responseName].updateFromComponent(this.values);
    }
  }
}

class MotionController {
  public var xrInputSource:Dynamic;
  public var assetUrl:String;
  public var id:String;
  public var layoutDescription:Dynamic;
  public var components:Dynamic;

  public function new(xrInputSource:Dynamic, profile:Dynamic, assetUrl:String) {
    if (xrInputSource == null) {
      throw new Error('No xrInputSource supplied');
    }
    if (profile == null) {
      throw new Error('No profile supplied');
    }
    this.xrInputSource = xrInputSource;
    this.assetUrl = assetUrl;
    this.id = profile.profileId;
    this.layoutDescription = profile.layouts[xrInputSource.handedness];
    this.components = {};
    for (componentId in Reflect.fields(this.layoutDescription.components)) {
      var componentDescription = this.layoutDescription.components[componentId];
      this.components[componentId] = new Component(componentId, componentDescription);
    }
    updateFromGamepad();
  }

  public function get_gripSpace():Dynamic {
    return this.xrInputSource.gripSpace;
  }

  public function get_targetRaySpace():Dynamic {
    return this.xrInputSource.targetRaySpace;
  }

  public function get_data():Array<Dynamic> {
    var data = [];
    for (component in Reflect.fields(this.components)) {
      data.push(this.components[component].get_data());
    }
    return data;
  }

  public function updateFromGamepad() {
    for (component in Reflect.fields(this.components)) {
      this.components[component].updateFromGamepad(this.xrInputSource.gamepad);
    }
  }
}