package;

import js.Browser.Fetch;
import js.Browser.Json;

/**
 * @webxr-input-profiles/motion-controllers 1.0.0 https://github.com/immersive-web/webxr-input-profiles
 */

@:enum abstract class Handedness {
  static var NONE = "none";
  static var LEFT = "left";
  static var RIGHT = "right";
}

@:enum abstract class ComponentState {
  static var DEFAULT = "default";
  static var TOUCHED = "touched";
  static var PRESSED = "pressed";
}

@:enum abstract class ComponentProperty {
  static var BUTTON = "button";
  static var X_AXIS = "xAxis";
  static var Y_AXIS = "yAxis";
  static var STATE = "state";
}

@:enum abstract class ComponentType {
  static var TRIGGER = "trigger";
  static var SQUEEZE = "squeeze";
  static var TOUCHPAD = "touchpad";
  static var THUMBSTICK = "thumbstick";
  static var BUTTON = "button";
}

class Constants {
  static var ButtonTouchThreshold = 0.05;
  static var AxisTouchThreshold = 0.1;
  static var VisualResponseProperty = {
    TRANSFORM: "transform",
    VISIBILITY: "visibility"
  };
  static var Handedness = Handedness;
  static var ComponentState = ComponentState;
  static var ComponentProperty = ComponentProperty;
  static var ComponentType = ComponentType;
}

/**
 * @description Static helper function to fetch a JSON file and turn it into a JS object
 * @param {string} path - Path to JSON file to be fetched
 */
async function fetchJsonFile(path:String):Json {
  var response = await Fetch.request(path);
  if (!response.ok) {
    throw new Error(response.statusText);
  } else {
    return response.json();
  }
}

async function fetchProfilesList(basePath:String):Json {
  if (basePath == null) {
    throw new Error("No basePath supplied");
  }

  var profileListFileName = "profilesList.json";
  var profilesList = await fetchJsonFile(basePath + "/" + profileListFileName);
  return profilesList;
}

async function fetchProfile(
  xrInputSource:Dynamic,
  basePath:String,
  ?defaultProfile:String,
  ?getAssetPath:Bool
):Dynamic {
  if (xrInputSource == null) {
    throw new Error("No xrInputSource supplied");
  }

  if (basePath == null) {
    throw new Error("No basePath supplied");
  }

  // Get the list of profiles
  var supportedProfilesList = await fetchProfilesList(basePath);

  // Find the relative path to the first requested profile that is recognized
  var match:Dynamic = null;
  for (profileId in xrInputSource.profiles) {
    var supportedProfile = supportedProfilesList[profileId];
    if (supportedProfile != null) {
      match = {
        profileId: profileId,
        profilePath: basePath + "/" + supportedProfile.path,
        deprecated: supportedProfile.deprecated
      };
      break;
    }
  }

  if (match == null) {
    if (defaultProfile == null) {
      throw new Error("No matching profile name found");
    }

    var supportedProfile = supportedProfilesList[defaultProfile];
    if (supportedProfile == null) {
      throw new Error(
        "No matching profile name found and default profile \"" + defaultProfile + "\" missing."
      );
    }

    match = {
      profileId: defaultProfile,
      profilePath: basePath + "/" + supportedProfile.path,
      deprecated: supportedProfile.deprecated
    };
  }

  var profile = await fetchJsonFile(match.profilePath);

  var assetPath:String;
  if (getAssetPath != null && getAssetPath) {
    var layout:Dynamic;
    if (xrInputSource.handedness == "any") {
      layout = profile.layouts[$arrayKeys(profile.layouts)[0]];
    } else {
      layout = profile.layouts[xrInputSource.handedness];
    }
    if (layout == null) {
      throw new Error(
        "No matching handedness, " + xrInputSource.handedness + ", in profile " + match.profileId
      );
    }

    if (layout.assetPath != null) {
      assetPath = match.profilePath.replace("profile.json", layout.assetPath);
    }
  }

  return { profile: profile, assetPath: assetPath };
}

/** @constant {Object} */
var defaultComponentValues = {
  xAxis: 0,
  yAxis: 0,
  button: 0,
  state: ComponentState.DEFAULT
};

/**
 * @description Converts an X, Y coordinate from the range -1 to 1 (as reported by the Gamepad
 * API) to the range 0 to 1 (for interpolation). Also caps the X, Y values to be bounded within
 * a circle. This ensures that thumbsticks are not animated outside the bounds of their physical
 * range of motion and touchpads do not report touch locations off their physical bounds.
 * @param {number} x The original x coordinate in the range -1 to 1
 * @param {number} y The original y coordinate in the range -1 to 1
 */
function normalizeAxes(x:Float = 0, y:Float = 0):Dynamic {
  var xAxis = x;
  var yAxis = y;

  // Determine if the point is outside the bounds of the circle
  // and, if so, place it on the edge of the circle
  var hypotenuse = Math.sqrt(x * x + y * y);
  if (hypotenuse > 1) {
    var theta = Math.atan2(y, x);
    xAxis = Math.cos(theta);
    yAxis = Math.sin(theta);
  }

  // Scale and move the circle so values are in the interpolation range.  The circle's origin moves
  // from (0, 0) to (0.5, 0.5). The circle's radius scales from 1 to be 0.5.
  return {
    normalizedXAxis: (xAxis * 0.5) + 0.5,
    normalizedYAxis: (yAxis * 0.5) + 0.5
  };
}

/**
 * Contains the description of how the 3D model should visually respond to a specific user input.
 * This is accomplished by initializing the object with the name of a node in the 3D model and
 * property that need to be modified in response to user input, the name of the nodes representing
 * the allowable range of motion, and the name of the input which triggers the change. In response
 * to the named input changing, this object computes the appropriate weighting to use for
 * interpolating between the range of motion nodes.
 */
class VisualResponse {
  public var componentProperty:ComponentProperty;
  public var states:Array<ComponentState>;
  public var valueNodeName:String;
  public var valueNodeProperty:String;
  public var minNodeName:String;
  public var maxNodeName:String;
  public var value:Float;

  public function new(visualResponseDescription:Dynamic) {
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

  /**
   * Computes the visual response's interpolation weight based on component state
   * @param {Object} componentValues - The component from which to update
   * @param {number} xAxis - The reported X axis value of the component
   * @param {number} yAxis - The reported Y axis value of the component
   * @param {number} button - The reported value of the component's button
   * @param {string} state - The component's active state
   */
  public function updateFromComponent(componentValues:Dynamic) {
    var { normalizedXAxis, normalizedYAxis } = normalizeAxes(
      componentValues.xAxis,
      componentValues.yAxis
    );
    switch (componentProperty) {
      case ComponentProperty.X_AXIS:
        value = states.includes(componentValues.state) ? normalizedXAxis : 0.5;
        break;
      case ComponentProperty.Y_AXIS:
        value = states.includes(componentValues.state) ? normalizedYAxis : 0.5;
        break;
      case ComponentProperty.BUTTON:
        value = states.includes(componentValues.state) ? componentValues.button : 0;
        break;
      case ComponentProperty.STATE:
        if (valueNodeProperty == Constants.VisualResponseProperty.VISIBILITY) {
          value = states.includes(componentValues.state);
        } else {
          value = states.includes(componentValues.state) ? 1.0 : 0.0;
        }
        break;
      default:
        throw new Error(
          "Unexpected visualResponse componentProperty " + componentProperty
        );
    }
  }
}

class Component {
  public var id:String;
  public var type:ComponentType;
  public var rootNodeName:String;
  public var touchPointNodeName:String;
  public var visualResponses:Dynamic;
  public var gamepadIndices:Dynamic;
  public var values:Dynamic;

  public function new(componentId:String, componentDescription:Dynamic) {
    if (
      componentId == null ||
      componentDescription == null ||
      componentDescription.visualResponses == null ||
      componentDescription.gamepadIndices == null ||
      $arrayKeys(componentDescription.gamepadIndices).length == 0
    ) {
      throw new Error("Invalid arguments supplied");
    }

    id = componentId;
    type = componentDescription.type;
    rootNodeName = componentDescription.rootNodeName;
    touchPointNodeName = componentDescription.touchPointNodeName;

    // Build all the visual responses for this component
    visualResponses = {};
    for (responseName in componentDescription.visualResponses) {
      var visualResponse = new VisualResponse(
        componentDescription.visualResponses[responseName]
      );
      visualResponses[responseName] = visualResponse;
    }

    // Set default values
    gamepadIndices = componentDescription.gamepadIndices;

    values = {
      state: ComponentState.DEFAULT,
      button: gamepadIndices.button != null ? 0 : null,
      xAxis: gamepadIndices.xAxis != null ? 0 : null,
      yAxis: gamepadIndices.yAxis != null ? 0 : null
    };
  }

  public function get data():Dynamic {
    return { id: id, ...values };
  }

  /**
   * @description Poll for updated data based on current gamepad state
   * @param {Object} gamepad - The gamepad object from which the component data should be polled
   */
  public function updateFromGamepad(gamepad:Dynamic) {
    // Set the state to default before processing other data sources
    values.state = ComponentState.DEFAULT;

    // Get and normalize button
    if (gamepadIndices.button != null && gamepad.buttons.length > gamepadIndices.button) {
      var gamepadButton = gamepad.buttons[gamepadIndices.button];
      values.button = gamepadButton.value;
      values.button = values.button < 0 ? 0 : values.button;
      values.button = values.button > 1 ? 1 : values.button;

      // Set the state based on the button
      if (gamepadButton.pressed || values.button == 1) {
        values.state = ComponentState.PRESSED;
      } else if (gamepadButton.touched || values.button > Constants.ButtonTouchThreshold) {
        values.state = ComponentState.TOUCHED;
      }
    }

    // Get and normalize x axis value
    if (
      gamepadIndices.xAxis != null &&
      gamepad.axes.length > gamepadIndices.xAxis
    ) {
      values.xAxis = gamepad.axes[gamepadIndices.xAxis];
      values.xAxis = values.xAxis < -1 ? -1 : values.xAxis;
      values.xAxis = values.xAxis > 1 ? 1 : values.xAxis;

      // If the state is still default, check if the xAxis makes it touched
      if (
        values.state == ComponentState.DEFAULT &&
        Math.abs(values.xAxis) > Constants.AxisTouchThreshold
      ) {
        values.state = ComponentState.TOUCHED;
      }
    }

    // Get and normalize Y axis value
    if (
      gamepadIndices.yAxis != null &&
      gamepad.axes.length > gamepadIndices.yAxis
    ) {
      values.yAxis = gamepad.axes[gamepadIndices.yAxis];
      values.yAxis = values.yAxis < -1 ? -1 : values.yAxis;
      values.yAxis = values.yAxis > 1 ? 1 : values.yAxis;

      // If the state is still default, check if the yAxis makes it touched
      if (
        values.state == ComponentState.DEFAULT &&
        Math.abs(values.yAxis) > Constants.AxisTouchThreshold
      ) {
        values.state = ComponentState.TOUCHED;
      }
    }

    // Update the visual response weights based on the current component data
    for (visualResponse in visualResponses) {
      visualResponse.updateFromComponent(values);
    }
  }
}

/**
  * @description Builds a motion controller with components and visual responses based on the
  * supplied profile description. Data is polled from the xrInputSource's gamepad.
  * @author Nell Waliczek / https://github.com/NellWaliczek
*/
class MotionController {
  public var xrInputSource:Dynamic;
  public var assetUrl:String;
  public var id:String;
  public var layoutDescription:Dynamic;
  public var components:Dynamic;
  public var gripSpace:Dynamic;
  public var targetRaySpace:Dynamic;

  public function new(xrInputSource:Dynamic, profile:Dynamic, assetUrl:String) {
    if (xrInputSource == null) {
      throw new Error("No xrInputSource supplied");
    }

    if (profile == null) {
      throw new Error("No profile supplied");
    }

    this.xrInputSource = xrInputSource;
    this.assetUrl = assetUrl;
    id = profile.profileId;

    // Build child components as described in the profile description
    layoutDescription = profile.layouts[xrInputSource.handedness];
    components = {};
    for (componentId in layoutDescription.components) {
      var componentDescription = layoutDescription.components[componentId];
      components[componentId] = new Component(componentId, componentDescription);
    }

    // Initialize components based on current gamepad state
    updateFromGamepad();
  }

  public function get data():Dynamic {
    var data = [];
    for (component in components) {
      data.push(component.data);
    }
    return data;
  }

  /**
   * @description Poll for updated data based on current gamepad state
   */
  public function updateFromGamepad() {
    for (component in components) {
      component.updateFromGamepad(xrInputSource.gamepad);
    }
  }
}

@:extern class Dynamic {
  public function get(key:String):Dynamic;
}

@:extern class Array {
  public static function keys<T>(arr:Array<T>):Array<Int>;
}