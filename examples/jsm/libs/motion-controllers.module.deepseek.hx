// Constants.hx
class Constants {
  static var Handedness:Map<String, String> = {
    NONE: 'none',
    LEFT: 'left',
    RIGHT: 'right'
  };

  static var ComponentState:Map<String, String> = {
    DEFAULT: 'default',
    TOUCHED: 'touched',
    PRESSED: 'pressed'
  };

  static var ComponentProperty:Map<String, String> = {
    BUTTON: 'button',
    X_AXIS: 'xAxis',
    Y_AXIS: 'yAxis',
    STATE: 'state'
  };

  static var ComponentType:Map<String, String> = {
    TRIGGER: 'trigger',
    SQUEEZE: 'squeeze',
    TOUCHPAD: 'touchpad',
    THUMBSTICK: 'thumbstick',
    BUTTON: 'button'
  };

  static var ButtonTouchThreshold:Float = 0.05;
  static var AxisTouchThreshold:Float = 0.1;

  static var VisualResponseProperty:Map<String, String> = {
    TRANSFORM: 'transform',
    VISIBILITY: 'visibility'
  };
}

// FetchJsonFile.hx
class FetchJsonFile {
  static function fetchJsonFile(path:String):Promise<Dynamic> {
    return js.Browser.fetch(path).then(function(response) {
      if (!response.ok) {
        throw new Error(response.statusText);
      } else {
        return response.json();
      }
    });
  }
}

// FetchProfilesList.hx
class FetchProfilesList {
  static function fetchProfilesList(basePath:String):Promise<Dynamic> {
    if (!basePath) {
      throw new Error('No basePath supplied');
    }

    var profileListFileName = 'profilesList.json';
    var profilesList = FetchJsonFile.fetchJsonFile(`${basePath}/${profileListFileName}`);
    return profilesList;
  }
}

// FetchProfile.hx
class FetchProfile {
  static function fetchProfile(xrInputSource:Dynamic, basePath:String, defaultProfile:Dynamic = null, getAssetPath:Bool = true):Promise<Dynamic> {
    if (!xrInputSource) {
      throw new Error('No xrInputSource supplied');
    }

    if (!basePath) {
      throw new Error('No basePath supplied');
    }

    // Get the list of profiles
    var supportedProfilesList = FetchProfilesList.fetchProfilesList(basePath);

    // Find the relative path to the first requested profile that is recognized
    var match:Dynamic = null;
    for (profileId in xrInputSource.profiles) {
      var supportedProfile = supportedProfilesList[profileId];
      if (supportedProfile) {
        match = {
          profileId: profileId,
          profilePath: `${basePath}/${supportedProfile.path}`,
          deprecated: !!supportedProfile.deprecated
        };
        break;
      }
    }

    if (!match) {
      if (!defaultProfile) {
        throw new Error('No matching profile name found');
      }

      var supportedProfile = supportedProfilesList[defaultProfile];
      if (!supportedProfile) {
        throw new Error(`No matching profile name found and default profile "${defaultProfile}" missing.`);
      }

      match = {
        profileId: defaultProfile,
        profilePath: `${basePath}/${supportedProfile.path}`,
        deprecated: !!supportedProfile.deprecated
      };
    }

    var profile = FetchJsonFile.fetchJsonFile(match.profilePath);

    var assetPath:String = null;
    if (getAssetPath) {
      var layout:Dynamic = null;
      if (xrInputSource.handedness == 'any') {
        layout = profile.layouts[Object.keys(profile.layouts)[0]];
      } else {
        layout = profile.layouts[xrInputSource.handedness];
      }
      if (!layout) {
        throw new Error(
          `No matching handedness, ${xrInputSource.handedness}, in profile ${match.profileId}`
        );
      }

      if (layout.assetPath) {
        assetPath = match.profilePath.replace('profile.json', layout.assetPath);
      }
    }

    return { profile: profile, assetPath: assetPath };
  }
}

// NormalizeAxes.hx
class NormalizeAxes {
  static function normalizeAxes(x:Float = 0, y:Float = 0):Dynamic {
    var xAxis:Float = x;
    var yAxis:Float = y;

    // Determine if the point is outside the bounds of the circle
    // and, if so, place it on the edge of the circle
    var hypotenuse:Float = Math.sqrt((x * x) + (y * y));
    if (hypotenuse > 1) {
      var theta:Float = Math.atan2(y, x);
      xAxis = Math.cos(theta);
      yAxis = Math.sin(theta);
    }

    // Scale and move the circle so values are in the interpolation range.  The circle's origin moves
    // from (0, 0) to (0.5, 0.5). The circle's radius scales from 1 to be 0.5.
    var result:Dynamic = {
      normalizedXAxis: (xAxis * 0.5) + 0.5,
      normalizedYAxis: (yAxis * 0.5) + 0.5
    };
    return result;
  }
}

// VisualResponse.hx
class VisualResponse {
  var componentProperty:String;
  var states:Array<String>;
  var valueNodeName:String;
  var valueNodeProperty:String;
  var minNodeName:String;
  var maxNodeName:String;
  var value:Float;

  public function new(visualResponseDescription:Dynamic) {
    this.componentProperty = visualResponseDescription.componentProperty;
    this.states = visualResponseDescription.states;
    this.valueNodeName = visualResponseDescription.valueNodeName;
    this.valueNodeProperty = visualResponseDescription.valueNodeProperty;

    if (this.valueNodeProperty == Constants.VisualResponseProperty.TRANSFORM) {
      this.minNodeName = visualResponseDescription.minNodeName;
      this.maxNodeName = visualResponseDescription.maxNodeName;
    }

    // Initializes the response's current value based on default data
    this.value = 0;
    this.updateFromComponent({
      xAxis: 0,
      yAxis: 0,
      button: 0,
      state: Constants.ComponentState.DEFAULT
    });
  }

  public function updateFromComponent(componentValues:Dynamic):Void {
    var { normalizedXAxis, normalizedYAxis } = NormalizeAxes.normalizeAxes(componentValues.xAxis, componentValues.yAxis);
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
          this.value = (this.states.indexOf(componentValues.state) != -1);
        } else {
          this.value = (this.states.indexOf(componentValues.state) != -1) ? 1.0 : 0.0;
        }
        break;
      default:
        throw new Error(`Unexpected visualResponse componentProperty ${this.componentProperty}`);
    }
  }
}

// Component.hx
class Component {
  var id:String;
  var type:String;
  var rootNodeName:String;
  var touchPointNodeName:String;
  var visualResponses:Dynamic;
  var gamepadIndices:Dynamic;
  var values:Dynamic;

  public function new(componentId:String, componentDescription:Dynamic) {
    if (!componentId
     || !componentDescription
     || !componentDescription.visualResponses
     || !componentDescription.gamepadIndices
     || Object.keys(componentDescription.gamepadIndices).length == 0) {
      throw new Error('Invalid arguments supplied');
    }

    this.id = componentId;
    this.type = componentDescription.type;
    this.rootNodeName = componentDescription.rootNodeName;
    this.touchPointNodeName = componentDescription.touchPointNodeName;

    // Build all the visual responses for this component
    this.visualResponses = {};
    for (responseName in componentDescription.visualResponses) {
      var visualResponse = new VisualResponse(componentDescription.visualResponses[responseName]);
      this.visualResponses[responseName] = visualResponse;
    }

    // Set default values
    this.gamepadIndices = haxe.Json.stringify(componentDescription.gamepadIndices);

    this.values = {
      state: Constants.ComponentState.DEFAULT,
      button: (this.gamepadIndices.button !== undefined) ? 0 : undefined,
      xAxis: (this.gamepadIndices.xAxis !== undefined) ? 0 : undefined,
      yAxis: (this.gamepadIndices.yAxis !== undefined) ? 0 : undefined
    };
  }

  public function get data():Dynamic {
    var data:Dynamic = { id: this.id, ...this.values };
    return data;
  }

  public function updateFromGamepad(gamepad:Dynamic):Void {
    // Set the state to default before processing other data sources
    this.values.state = Constants.ComponentState.DEFAULT;

    // Get and normalize button
    if (this.gamepadIndices.button !== undefined
        && gamepad.buttons.length > this.gamepadIndices.button) {
      var gamepadButton = gamepad.buttons[this.gamepadIndices.button];
      this.values.button = gamepadButton.value;
      this.values.button = (this.values.button < 0) ? 0 : this.values.button;
      this.values.button = (this.values.button > 1) ? 1 : this.values.button;

      // Set the state based on the button
      if (gamepadButton.pressed || this.values.button == 1) {
        this.values.state = Constants.ComponentState.PRESSED;
      } else if (gamepadButton.touched || this.values.button > Constants.ButtonTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }

    // Get and normalize x axis value
    if (this.gamepadIndices.xAxis !== undefined
        && gamepad.axes.length > this.gamepadIndices.xAxis) {
      this.values.xAxis = gamepad.axes[this.gamepadIndices.xAxis];
      this.values.xAxis = (this.values.xAxis < -1) ? -1 : this.values.xAxis;
      this.values.xAxis = (this.values.xAxis > 1) ? 1 : this.values.xAxis;

      // If the state is still default, check if the xAxis makes it touched
      if (this.values.state == Constants.ComponentState.DEFAULT
        && Math.abs(this.values.xAxis) > Constants.AxisTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }

    // Get and normalize Y axis value
    if (this.gamepadIndices.yAxis !== undefined
        && gamepad.axes.length > this.gamepadIndices.yAxis) {
      this.values.yAxis = gamepad.axes[this.gamepadIndices.yAxis];
      this.values.yAxis = (this.values.yAxis < -1) ? -1 : this.values.yAxis;
      this.values.yAxis = (this.values.yAxis > 1) ? 1 : this.values.yAxis;

      // If the state is still default, check if the yAxis makes it touched
      if (this.values.state == Constants.ComponentState.DEFAULT
        && Math.abs(this.values.yAxis) > Constants.AxisTouchThreshold) {
        this.values.state = Constants.ComponentState.TOUCHED;
      }
    }

    // Update the visual response weights based on the current component data
    for (visualResponse in this.visualResponses.values()) {
      visualResponse.updateFromComponent(this.values);
    }
  }
}

// MotionController.hx
class MotionController {
  var xrInputSource:Dynamic;
  var assetUrl:String;
  var id:String;
  var layoutDescription:Dynamic;
  var components:Dynamic;

  public function new(xrInputSource:Dynamic, profile:Dynamic, assetUrl:String) {
    if (!xrInputSource) {
      throw new Error('No xrInputSource supplied');
    }

    if (!profile) {
      throw new Error('No profile supplied');
    }

    this.xrInputSource = xrInputSource;
    this.assetUrl = assetUrl;
    this.id = profile.profileId;

    // Build child components as described in the profile description
    this.layoutDescription = profile.layouts[xrInputSource.handedness];
    this.components = {};
    for (componentId in this.layoutDescription.components) {
      var componentDescription = this.layoutDescription.components[componentId];
      this.components[componentId] = new Component(componentId, componentDescription);
    }

    // Initialize components based on current gamepad state
    this.updateFromGamepad();
  }

  public function get gripSpace():Dynamic {
    return this.xrInputSource.gripSpace;
  }

  public function get targetRaySpace():Dynamic {
    return this.xrInputSource.targetRaySpace;
  }

  public function get data():Array<Dynamic> {
    var data:Array<Dynamic> = [];
    for (component in this.components.values()) {
      data.push(component.data);
    }
    return data;
  }

  public function updateFromGamepad():Void {
    for (component in this.components.values()) {
      component.updateFromGamepad(this.xrInputSource.gamepad);
    }
  }
}

// Export classes
typedef Constants = Constants;
typedef MotionController = MotionController;
typedef FetchProfile = FetchProfile;
typedef FetchProfilesList = FetchProfilesList;