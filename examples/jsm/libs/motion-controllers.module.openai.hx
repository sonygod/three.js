package three.js.examples.jsm.libs.motion_controllers;

/**
 * @webxr-input-profiles/motion-controllers 1.0.0 https://github.com/immersive-web/webxr-input-profiles
 */

class Constants {
  public static inline var Handedness = {
    NONE: 'none',
    LEFT: 'left',
    RIGHT: 'right'
  };

  public static inline var ComponentState = {
    DEFAULT: 'default',
    TOUCHED: 'touched',
    PRESSED: 'pressed'
  };

  public static inline var ComponentProperty = {
    BUTTON: 'button',
    X_AXIS: 'xAxis',
    Y_AXIS: 'yAxis',
    STATE: 'state'
  };

  public static inline var ComponentType = {
    TRIGGER: 'trigger',
    SQUEEZE: 'squeeze',
    TOUCHPAD: 'touchpad',
    THUMBSTICK: 'thumbstick',
    BUTTON: 'button'
  };

  public static inline var ButtonTouchThreshold: Float = 0.05;
  public static inline var AxisTouchThreshold: Float = 0.1;

  public static inline var VisualResponseProperty = {
    TRANSFORM: 'transform',
    VISIBILITY: 'visibility'
  };
}

async function fetchJsonFile(path: String): Promise<Dynamic> {
  // NOTE: The `fetch` API is not available in Haxe, so we'll use the `haxe.Http` class instead
  var request = new haxe.Http(path);
  request.async = true;
  request.onStatus = function(status) {
    if (status != 200) {
      throw new Error('Failed to fetch JSON file: ' + status);
    }
  };
  request.onData = function(data: String) {
    return JSON.parse(data);
  };
  request.send();
}

async function fetchProfilesList(basePath: String): Promise<Dynamic> {
  if (basePath == null) {
    throw new Error('No basePath supplied');
  }

  var profileListFileName = 'profilesList.json';
  var profilesList = await fetchJsonFile('${basePath}/${profileListFileName}');
  return profilesList;
}

async function fetchProfile(xrInputSource: Dynamic, basePath: String, ?defaultProfile: String = null, ?getAssetPath: Bool = true): Promise<Dynamic> {
  if (xrInputSource == null) {
    throw new Error('No xrInputSource supplied');
  }

  if (basePath == null) {
    throw new Error('No basePath supplied');
  }

  // Get the list of profiles
  var supportedProfilesList = await fetchProfilesList(basePath);

  // Find the relative path to the first requested profile that is recognized
  var match: Dynamic = null;
  xrInputSource.profiles.some(function(profileId) {
    var supportedProfile = supportedProfilesList[profileId];
    if (supportedProfile != null) {
      match = {
        profileId: profileId,
        profilePath: '${basePath}/${supportedProfile.path}',
        deprecated: !!supportedProfile.deprecated
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
      deprecated: !!supportedProfile.deprecated
    };
  }

  var profile = await fetchJsonFile(match.profilePath);

  var assetPath: String = null;
  if (getAssetPath) {
    var layout: Dynamic = null;
    if (xrInputSource.handedness == 'any') {
      layout = profile.layouts[Object.keys(profile.layouts)[0]];
    } else {
      layout = profile.layouts[xrInputSource.handedness];
    }
    if (layout == null) {
      throw new Error('No matching handedness, ${xrInputSource.handedness}, in profile ${match.profileId}');
    }

    if (layout.assetPath != null) {
      assetPath = match.profilePath.replace('profile.json', layout.assetPath);
    }
  }

  return { profile: profile, assetPath: assetPath };
}

class VisualResponse {
  public var componentProperty: String;
  public var states: Array<String>;
  public var valueNodeName: String;
  public var valueNodeProperty: String;

  public function new(visualResponseDescription: Dynamic) {
    componentProperty = visualResponseDescription.componentProperty;
    states = visualResponseDescription.states;
    valueNodeName = visualResponseDescription.valueNodeName;
    valueNodeProperty = visualResponseDescription.valueNodeProperty;

    if (valueNodeProperty == Constants.VisualResponseProperty.TRANSFORM) {
      minNodeName = visualResponseDescription.minNodeName;
      maxNodeName = visualResponseDescription.maxNodeName;
    }

    // Initializes the response's current value based on default data
    value = 0;
    updateFromComponent(defaultComponentValues);
  }

  public function updateFromComponent(componentValues: Dynamic) {
    // TO DO: implement updateFromComponent method
    // (Note: this method is not implemented as it relies on the `normalizeAxes` function)
  }
}

class Component {
  public var id: String;
  public var type: String;
  public var rootNodeName: String;
  public var touchPointNodeName: String;
  public var visualResponses: Array<VisualResponse>;
  public var gamepadIndices: Dynamic;
  public var values: Dynamic;

  public function new(componentId: String, componentDescription: Dynamic) {
    if (componentId == null || componentDescription == null) {
      throw new Error('Invalid arguments supplied');
    }

    id = componentId;
    type = componentDescription.type;
    rootNodeName = componentDescription.rootNodeName;
    touchPointNodeName = componentDescription.touchPointNodeName;

    // Build all the visual responses for this component
    visualResponses = [];
    for (responseName in componentDescription.visualResponses.keys()) {
      var visualResponse = new VisualResponse(componentDescription.visualResponses[responseName]);
      visualResponses.push(visualResponse);
    }

    // Set default values
    gamepadIndices = componentDescription.gamepadIndices.copy();
    values = {
      state: Constants.ComponentState.DEFAULT,
      button: (gamepadIndices.button != null) ? 0 : null,
      xAxis: (gamepadIndices.xAxis != null) ? 0 : null,
      yAxis: (gamepadIndices.yAxis != null) ? 0 : null
    };
  }

  public function get_data(): Dynamic {
    var data = { id: id, ...values };
    return data;
  }

  public function updateFromGamepad(gamepad: Dynamic): Void {
    // TO DO: implement updateFromGamepad method
    // (Note: this method is not implemented as it relies on the `normalizeAxes` function)
  }
}

class MotionController {
  public var xrInputSource: Dynamic;
  public var profile: Dynamic;
  public var assetUrl: String;
  public var id: String;
  public var layoutDescription: Dynamic;
  public var components: Array<Component>;

  public function new(xrInputSource: Dynamic, profile: Dynamic, assetUrl: String) {
    if (xrInputSource == null) {
      throw new Error('No xrInputSource supplied');
    }

    if (profile == null) {
      throw new Error('No profile supplied');
    }

    this.xrInputSource = xrInputSource;
    this.profile = profile;
    this.assetUrl = assetUrl;
    id = profile.profileId;

    // Build child components as described in the profile description
    layoutDescription = profile.layouts[xrInputSource.handedness];
    components = [];
    for (componentId in layoutDescription.components.keys()) {
      var componentDescription = layoutDescription.components[componentId];
      components.push(new Component(componentId, componentDescription));
    }

    // Initialize components based on current gamepad state
    updateFromGamepad();
  }

  public function get_gripSpace(): Dynamic {
    return xrInputSource.gripSpace;
  }

  public function get_targetRaySpace(): Dynamic {
    return xrInputSource.targetRaySpace;
  }

  public function get_data(): Array<Dynamic> {
    var data = [];
    for (component in components) {
      data.push(component.get_data());
    }
    return data;
  }

  public function updateFromGamepad(): Void {
    for (component in components) {
      component.updateFromGamepad(xrInputSource.gamepad);
    }
  }
}