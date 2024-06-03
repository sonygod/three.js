import js.Browser;
import js.Promise;

class Constants {
    static var Handedness:Object = {
        NONE: 'none',
        LEFT: 'left',
        RIGHT: 'right'
    };

    static var ComponentState:Object = {
        DEFAULT: 'default',
        TOUCHED: 'touched',
        PRESSED: 'pressed'
    };

    static var ComponentProperty:Object = {
        BUTTON: 'button',
        X_AXIS: 'xAxis',
        Y_AXIS: 'yAxis',
        STATE: 'state'
    };

    static var ComponentType:Object = {
        TRIGGER: 'trigger',
        SQUEEZE: 'squeeze',
        TOUCHPAD: 'touchpad',
        THUMBSTICK: 'thumbstick',
        BUTTON: 'button'
    };

    static var ButtonTouchThreshold:Float = 0.05;

    static var AxisTouchThreshold:Float = 0.1;

    static var VisualResponseProperty:Object = {
        TRANSFORM: 'transform',
        VISIBILITY: 'visibility'
    };
}

function fetchJsonFile(path:String):Promise<Dynamic> {
    return Promise.then(Browser.window.fetch(path), function(response:Dynamic) {
        if (!response.ok) {
            throw new Error(response.statusText);
        } else {
            return response.json();
        }
    });
}

function fetchProfilesList(basePath:String):Promise<Dynamic> {
    if (!basePath) {
        throw new Error('No basePath supplied');
    }

    var profileListFileName:String = 'profilesList.json';
    return fetchJsonFile(basePath + '/' + profileListFileName);
}

function fetchProfile(xrInputSource:Dynamic, basePath:String, ?defaultProfile:String = null, ?getAssetPath:Bool = true):Promise<Dynamic> {
    if (!xrInputSource) {
        throw new Error('No xrInputSource supplied');
    }

    if (!basePath) {
        throw new Error('No basePath supplied');
    }

    return Promise.then(fetchProfilesList(basePath), function(supportedProfilesList:Dynamic) {
        var match:Dynamic = null;
        var profiles:Array<String> = xrInputSource.profiles;
        for (profileId in profiles) {
            var supportedProfile:Dynamic = supportedProfilesList[profileId];
            if (supportedProfile != null) {
                match = {
                    profileId: profileId,
                    profilePath: basePath + '/' + supportedProfile.path,
                    deprecated: Bool(supportedProfile.deprecated)
                };
                break;
            }
        }

        if (match == null) {
            if (defaultProfile == null) {
                throw new Error('No matching profile name found');
            }

            var supportedProfile:Dynamic = supportedProfilesList[defaultProfile];
            if (supportedProfile == null) {
                throw new Error('No matching profile name found and default profile "' + defaultProfile + '" missing.');
            }

            match = {
                profileId: defaultProfile,
                profilePath: basePath + '/' + supportedProfile.path,
                deprecated: Bool(supportedProfile.deprecated)
            };
        }

        return Promise.then(fetchJsonFile(match.profilePath), function(profile:Dynamic) {
            var assetPath:String = null;
            if (getAssetPath) {
                var layout:Dynamic;
                if (xrInputSource.handedness == 'any') {
                    layout = profile.layouts[Std.string(Reflect.fields(profile.layouts)[0])];
                } else {
                    layout = profile.layouts[xrInputSource.handedness];
                }
                if (layout == null) {
                    throw new Error('No matching handedness, ' + xrInputSource.handedness + ', in profile ' + match.profileId);
                }

                if (layout.assetPath != null) {
                    assetPath = match.profilePath.replace('profile.json', layout.assetPath);
                }
            }

            return { profile: profile, assetPath: assetPath };
        });
    });
}

var defaultComponentValues:Object = {
    xAxis: 0,
    yAxis: 0,
    button: 0,
    state: Constants.ComponentState.DEFAULT
};

function normalizeAxes(?x:Float = 0, ?y:Float = 0):Object {
    var xAxis:Float = x;
    var yAxis:Float = y;

    var hypotenuse:Float = Math.sqrt((x * x) + (y * y));
    if (hypotenuse > 1) {
        var theta:Float = Math.atan2(y, x);
        xAxis = Math.cos(theta);
        yAxis = Math.sin(theta);
    }

    var result:Object = {
        normalizedXAxis: (xAxis * 0.5) + 0.5,
        normalizedYAxis: (yAxis * 0.5) + 0.5
    };
    return result;
}

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

        this.value = 0;
        this.updateFromComponent(defaultComponentValues);
    }

    public function updateFromComponent(componentValues:Dynamic) {
        var xAxis:Float = componentValues.xAxis;
        var yAxis:Float = componentValues.yAxis;
        var button:Float = componentValues.button;
        var state:String = componentValues.state;

        var normalizedAxes:Object = normalizeAxes(xAxis, yAxis);
        var normalizedXAxis:Float = normalizedAxes.normalizedXAxis;
        var normalizedYAxis:Float = normalizedAxes.normalizedYAxis;

        switch (this.componentProperty) {
            case Constants.ComponentProperty.X_AXIS:
                this.value = (this.states.indexOf(state) != -1) ? normalizedXAxis : 0.5;
                break;
            case Constants.ComponentProperty.Y_AXIS:
                this.value = (this.states.indexOf(state) != -1) ? normalizedYAxis : 0.5;
                break;
            case Constants.ComponentProperty.BUTTON:
                this.value = (this.states.indexOf(state) != -1) ? button : 0;
                break;
            case Constants.ComponentProperty.STATE:
                if (this.valueNodeProperty == Constants.VisualResponseProperty.VISIBILITY) {
                    this.value = (this.states.indexOf(state) != -1);
                } else {
                    this.value = (this.states.indexOf(state) != -1) ? 1.0 : 0.0;
                }
                break;
            default:
                throw new Error('Unexpected visualResponse componentProperty ' + this.componentProperty);
        }
    }
}

class Component {
    var id:String;
    var type:String;
    var rootNodeName:String;
    var touchPointNodeName:String;
    var visualResponses:Object;
    var gamepadIndices:Object;
    var values:Object;

    public function new(componentId:String, componentDescription:Dynamic) {
        if (componentId == null || componentDescription == null || componentDescription.visualResponses == null || componentDescription.gamepadIndices == null || Reflect.fields(componentDescription.gamepadIndices).length == 0) {
            throw new Error('Invalid arguments supplied');
        }

        this.id = componentId;
        this.type = componentDescription.type;
        this.rootNodeName = componentDescription.rootNodeName;
        this.touchPointNodeName = componentDescription.touchPointNodeName;

        this.visualResponses = {};
        var visualResponsesNames:Array<String> = Reflect.fields(componentDescription.visualResponses);
        for (visualResponseName in visualResponsesNames) {
            var visualResponse:VisualResponse = new VisualResponse(componentDescription.visualResponses[visualResponseName]);
            this.visualResponses[visualResponseName] = visualResponse;
        }

        this.gamepadIndices = componentDescription.gamepadIndices;

        this.values = {
            state: Constants.ComponentState.DEFAULT,
            button: (this.gamepadIndices.button != null) ? 0 : null,
            xAxis: (this.gamepadIndices.xAxis != null) ? 0 : null,
            yAxis: (this.gamepadIndices.yAxis != null) ? 0 : null
        };
    }

    public function get_data():Object {
        var data:Object = { id: this.id };
        var valueNames:Array<String> = Reflect.fields(this.values);
        for (valueName in valueNames) {
            data[valueName] = this.values[valueName];
        }
        return data;
    }

    public function updateFromGamepad(gamepad:Dynamic) {
        this.values.state = Constants.ComponentState.DEFAULT;

        if (this.gamepadIndices.button != null && gamepad.buttons.length > this.gamepadIndices.button) {
            var gamepadButton:Dynamic = gamepad.buttons[this.gamepadIndices.button];
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

        var visualResponsesValues:Array<VisualResponse> = Reflect.fields(this.visualResponses).map((key) => this.visualResponses[key]);
        for (visualResponse in visualResponsesValues) {
            visualResponse.updateFromComponent(this.values);
        }
    }
}

class MotionController {
    var xrInputSource:Dynamic;
    var assetUrl:String;
    var id:String;
    var layoutDescription:Dynamic;
    var components:Object;

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
        var componentIds:Array<String> = Reflect.fields(this.layoutDescription.components);
        for (componentId in componentIds) {
            var componentDescription:Dynamic = this.layoutDescription.components[componentId];
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

    public function get_data():Array<Object> {
        var data:Array<Object> = [];
        var componentsValues:Array<Component> = Reflect.fields(this.components).map((key) => this.components[key]);
        for (component in componentsValues) {
            data.push(component.get_data());
        }
        return data;
    }

    public function updateFromGamepad() {
        var componentsValues:Array<Component> = Reflect.fields(this.components).map((key) => this.components[key]);
        for (component in componentsValues) {
            component.updateFromGamepad(this.xrInputSource.gamepad);
        }
    }
}

export { Constants, MotionController, fetchProfile, fetchProfilesList };