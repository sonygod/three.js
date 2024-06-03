package webxr.input.profiles;

import haxe.Json;
import haxe.io.Bytes;
import haxe.io.Encoding;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.Process;
import js.html.File;
import js.html.XMLHttpRequest;
import js.html.Window;
import js.lib.ArrayBuffer;
import js.lib.Promise;
import js.lib.Uint8Array;

class Constants {
  public static var Handedness: {NONE:String, LEFT:String, RIGHT:String} = {
    NONE: "none",
    LEFT: "left",
    RIGHT: "right"
  };

  public static var ComponentState: {DEFAULT:String, TOUCHED:String, PRESSED:String} = {
    DEFAULT: "default",
    TOUCHED: "touched",
    PRESSED: "pressed"
  };

  public static var ComponentProperty: {BUTTON:String, X_AXIS:String, Y_AXIS:String, STATE:String} = {
    BUTTON: "button",
    X_AXIS: "xAxis",
    Y_AXIS: "yAxis",
    STATE: "state"
  };

  public static var ComponentType: {TRIGGER:String, SQUEEZE:String, TOUCHPAD:String, THUMBSTICK:String, BUTTON:String} = {
    TRIGGER: "trigger",
    SQUEEZE: "squeeze",
    TOUCHPAD: "touchpad",
    THUMBSTICK: "thumbstick",
    BUTTON: "button"
  };

  public static var ButtonTouchThreshold:Float = 0.05;

  public static var AxisTouchThreshold:Float = 0.1;

  public static var VisualResponseProperty: {TRANSFORM:String, VISIBILITY:String} = {
    TRANSFORM: "transform",
    VISIBILITY: "visibility"
  };
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
    this.updateFromComponent(defaultComponentValues);
  }

  public function updateFromComponent(componentValues:Dynamic) {
    var {normalizedXAxis, normalizedYAxis} = normalizeAxes(componentValues.xAxis, componentValues.yAxis);
    switch (this.componentProperty) {
      case Constants.ComponentProperty.X_AXIS:
        this.value = (this.states.indexOf(componentValues.state) != -1) ? normalizedXAxis : 0.5;
        break;
      case Constants.ComponentProperty.Y_AXIS:
        this.value = (this.states.indexOf(componentValues.state) != -1) ? normalizedYAxis : 0.5;
        break;
      case Constants.ComponentProperty.BUTTON:
        this.value = (this.states.indexOf(componentValues.state) != -1) ? componentValues.button : 0;
        break;
      case Constants.ComponentProperty.STATE:
        if (this.valueNodeProperty == Constants.VisualResponseProperty.VISIBILITY) {
          this.value = (this.states.indexOf(componentValues.state) != -1) ? 1.0 : 0.0;
        } else {
          this.value = (this.states.indexOf(componentValues.state) != -1) ? 1.0 : 0.0;
        }
        break;
      default:
        throw "Unexpected visualResponse componentProperty " + this.componentProperty;
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
    if (!componentId || !componentDescription || !componentDescription.visualResponses || !componentDescription.gamepadIndices || Reflect.field(componentDescription.gamepadIndices, "").length == 0) {
      throw "Invalid arguments supplied";
    }

    this.id = componentId;
    this.type = componentDescription.type;
    this.rootNodeName = componentDescription.rootNodeName;
    this.touchPointNodeName = componentDescription.touchPointNodeName;

    this.visualResponses = {};
    for (responseName in componentDescription.visualResponses) {
      var visualResponse = new VisualResponse(componentDescription.visualResponses[responseName]);
      this.visualResponses[responseName] = visualResponse;
    }

    this.gamepadIndices = Reflect.copy(componentDescription.gamepadIndices);

    this.values = {
      state: Constants.ComponentState.DEFAULT,
      button: (this.gamepadIndices.button != null) ? 0 : null,
      xAxis: (this.gamepadIndices.xAxis != null) ? 0 : null,
      yAxis: (this.gamepadIndices.yAxis != null) ? 0 : null
    };
  }

  public function get_data():Dynamic {
    var data = { id: this.id, ...this.values };
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

    for (visualResponse in this.visualResponses) {
      visualResponse.updateFromComponent(this.values);
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
    if (!xrInputSource) {
      throw "No xrInputSource supplied";
    }

    if (!profile) {
      throw "No profile supplied";
    }

    this.xrInputSource = xrInputSource;
    this.assetUrl = assetUrl;
    this.id = profile.profileId;

    this.layoutDescription = profile.layouts[xrInputSource.handedness];
    this.components = {};
    for (componentId in this.layoutDescription.components) {
      var componentDescription = this.layoutDescription.components[componentId];
      this.components[componentId] = new Component(componentId, componentDescription);
    }

    this.updateFromGamepad();
  }

  public function get_gripSpace():Dynamic {
    return this.xrInputSource.gripSpace;
  }

  public function get_targetRaySpace():Dynamic {
    return this.xrInputSource.targetRaySpace;
  }

  public function get_data():Array<Dynamic> {
    var data = [];
    for (component in this.components) {
      data.push(component.data);
    }
    return data;
  }

  public function updateFromGamepad() {
    for (component in this.components) {
      component.updateFromGamepad(this.xrInputSource.gamepad);
    }
  }
}

var defaultComponentValues:Dynamic = {
  xAxis: 0,
  yAxis: 0,
  button: 0,
  state: Constants.ComponentState.DEFAULT
};

function normalizeAxes(x:Float = 0, y:Float = 0):{normalizedXAxis:Float, normalizedYAxis:Float} {
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

function fetchJsonFile(path:String):Promise<Dynamic> {
  var request = new XMLHttpRequest();
  var promise = new Promise();

  request.open("GET", path, true);
  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      promise.resolve(Json.parse(request.responseText));
    } else {
      promise.reject(request.statusText);
    }
  };
  request.onerror = function() {
    promise.reject(request.statusText);
  };
  request.send();
  return promise;
}

function fetchProfilesList(basePath:String):Promise<Dynamic> {
  if (basePath == null) {
    throw "No basePath supplied";
  }

  var profileListFileName = "profilesList.json";
  var promise = new Promise();

  fetchJsonFile(`${basePath}/${profileListFileName}`).then(function(profilesList) {
    promise.resolve(profilesList);
  }).catch(function(error) {
    promise.reject(error);
  });

  return promise;
}

function fetchProfile(xrInputSource:Dynamic, basePath:String, defaultProfile:String = null, getAssetPath:Bool = true):Promise<{profile:Dynamic, assetPath:String}> {
  if (xrInputSource == null) {
    throw "No xrInputSource supplied";
  }

  if (basePath == null) {
    throw "No basePath supplied";
  }

  var promise = new Promise();

  fetchProfilesList(basePath).then(function(supportedProfilesList) {
    var match:Dynamic;
    xrInputSource.profiles.some(function(profileId) {
      var supportedProfile = supportedProfilesList[profileId];
      if (supportedProfile != null) {
        match = {
          profileId: profileId,
          profilePath: `${basePath}/${supportedProfile.path}`,
          deprecated: (supportedProfile.deprecated != null)
        };
      }
      return match != null;
    });

    if (match == null) {
      if (defaultProfile == null) {
        throw "No matching profile name found";
      }

      var supportedProfile = supportedProfilesList[defaultProfile];
      if (supportedProfile == null) {
        throw "No matching profile name found and default profile " + defaultProfile + " missing.";
      }

      match = {
        profileId: defaultProfile,
        profilePath: `${basePath}/${supportedProfile.path}`,
        deprecated: (supportedProfile.deprecated != null)
      };
    }

    fetchJsonFile(match.profilePath).then(function(profile) {
      var assetPath:String;
      if (getAssetPath) {
        var layout:Dynamic;
        if (xrInputSource.handedness == "any") {
          layout = profile.layouts[Reflect.field(profile.layouts, "").keys()[0]];
        } else {
          layout = profile.layouts[xrInputSource.handedness];
        }
        if (layout == null) {
          throw "No matching handedness, " + xrInputSource.handedness + ", in profile " + match.profileId;
        }

        if (layout.assetPath != null) {
          assetPath = match.profilePath.replace("profile.json", layout.assetPath);
        }
      }

      promise.resolve({profile: profile, assetPath: assetPath});
    }).catch(function(error) {
      promise.reject(error);
    });
  }).catch(function(error) {
    promise.reject(error);
  });

  return promise;
}

export {Constants, MotionController, fetchProfile, fetchProfilesList};