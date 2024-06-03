package;

import js.Browser;

/**
 * lil-gui
 * https://lil-gui.georgealways.com
 * @version 0.17.0
 * @author George Michael Brower
 * @license MIT
 */
class Controller {
  public var parent:GUI;
  public var object:Dynamic;
  public var property:String;
  public var domElement:js.html.Element;
  public var $name:js.html.Element;
  public var $widget:js.html.Element;
  public var $disable:js.html.Element;
  public var initialValue:Dynamic;

  var _name:String;
  var _disabled:Bool;
  var _hidden:Bool;
  var _onChange:Dynamic->Void;
  var _onFinishChange:Dynamic->Void;
  var _listenCallback:Void->Void;
  var _listenCallbackID:Int;
  var _listening:Bool;
  var _listenPrevValue:Dynamic;
  var _changed:Bool;

  public static var nextNameID:Int = 0;

  public function new(parent:GUI, object:Dynamic, property:String, controllerType:String, widgetTag:String = "div") {
    this.parent = parent;
    this.object = object;
    this.property = property;
    this._disabled = false;
    this._hidden = false;
    this.initialValue = this.getValue();

    this.domElement = Browser.document.createElement("div");
    this.domElement.classList.add("controller");
    this.domElement.classList.add(controllerType);

    this.$name = Browser.document.createElement("div");
    this.$name.classList.add("name");
    Controller.nextNameID = (Controller.nextNameID != null ? Controller.nextNameID : 0) + 1;
    this.$name.id = 'lil-gui-name-' + Controller.nextNameID;

    this.$widget = Browser.document.createElement(widgetTag);
    this.$widget.classList.add("widget");

    this.$disable = this.$widget;

    this.domElement.appendChild(this.$name);
    this.domElement.appendChild(this.$widget);

    this.parent.children.push(this);
    this.parent.controllers.push(this);
    this.parent.$children.appendChild(this.domElement);

    this._listenCallback = this._listenCallback.bind(this);
    this.name(property);
  }

  public function name(name:String):Controller {
    this._name = name;
    this.$name.innerHTML = name;
    return this;
  }

  public function onChange(callback:Dynamic->Void):Controller {
    this._onChange = callback;
    return this;
  }

  function _callOnChange() {
    this.parent._callOnChange(this);
    if (this._onChange != null) {
      this._onChange(this.getValue());
    }
    this._changed = true;
  }

  public function onFinishChange(callback:Dynamic->Void):Controller {
    this._onFinishChange = callback;
    return this;
  }

  function _callOnFinishChange() {
    if (this._changed) {
      this.parent._callOnFinishChange(this);
      if (this._onFinishChange != null) {
        this._onFinishChange(this.getValue());
      }
    }
    this._changed = false;
  }

  public function reset():Controller {
    this.setValue(this.initialValue);
    this._callOnFinishChange();
    return this;
  }

  public function enable(enabled:Bool = true):Controller {
    return this.disable(!enabled);
  }

  public function disable(disabled:Bool = true):Controller {
    if (disabled != this._disabled) {
      this._disabled = disabled;
      this.domElement.classList.toggle("disabled", disabled);
      this.$disable.toggleAttribute("disabled", disabled);
    }
    return this;
  }

  public function show(show:Bool = true):Controller {
    this._hidden = !show;
    this.domElement.style.display = this._hidden ? "none" : "";
    return this;
  }

  public function hide():Controller {
    return this.show(false);
  }

  public function options(options:Dynamic):Controller {
    var controller:Controller = this.parent.add(this.object, this.property, options);
    controller.name(this._name);
    this.destroy();
    return controller;
  }

  public function min(min:Float):Controller {
    return this; // Abstract method, to be overridden by subclasses
  }

  public function max(max:Float):Controller {
    return this; // Abstract method, to be overridden by subclasses
  }

  public function step(step:Float):Controller {
    return this; // Abstract method, to be overridden by subclasses
  }

  public function decimals(decimals:Int):Controller {
    return this; // Abstract method, to be overridden by subclasses
  }

  public function listen(listen:Bool = true):Controller {
    this._listening = listen;
    if (this._listenCallbackID != null) {
      Browser.window.cancelAnimationFrame(this._listenCallbackID);
      this._listenCallbackID = null;
    }
    if (this._listening) {
      this._listenCallback();
    }
    return this;
  }

  function _listenCallback() {
    this._listenCallbackID = Browser.window.requestAnimationFrame(this._listenCallback);
    var value = this.save();
    if (value != this._listenPrevValue) {
      this.updateDisplay();
    }
    this._listenPrevValue = value;
  }

  public function getValue():Dynamic {
    return Reflect.field(this.object, this.property);
  }

  public function setValue(value:Dynamic):Controller {
    Reflect.setField(this.object, this.property, value);
    this._callOnChange();
    this.updateDisplay();
    return this;
  }

  public function updateDisplay():Controller {
    return this; // Abstract method, to be overridden by subclasses
  }

  public function load(value:Dynamic):Controller {
    this.setValue(value);
    this._callOnFinishChange();
    return this;
  }

  public function save():Dynamic {
    return this.getValue();
  }

  public function destroy():Void {
    this.listen(false);
    this.parent.children.remove(this);
    this.parent.controllers.remove(this);
    this.parent.$children.removeChild(this.domElement);
  }
}

class BooleanController extends Controller {
  public var $input:js.html.Input;

  public function new(parent:GUI, object:Dynamic, property:String) {
    super(parent, object, property, "boolean", "label");

    this.$input = cast Browser.document.createElement("input");
    this.$input.setAttribute("type", "checkbox");
    this.$input.setAttribute("aria-labelledby", this.$name.id);
    this.$widget.appendChild(this.$input);

    this.$disable = this.$input;

    this.$input.addEventListener("change", function(_) {
      this.setValue(this.$input.checked);
      this._callOnFinishChange();
    });

    this.updateDisplay();
  }

  override public function updateDisplay():Controller {
    this.$input.checked = this.getValue();
    return this;
  }
}

function hexStringToColor(hex:String):{r:Float, g:Float, b:Float} {
  var rgb: { r:Float, g:Float, b:Float } = {r: 0, g: 0, b: 0};
  if (hex.length == 4) {
    rgb.r = Std.parseInt("0x" + hex.charAt(1) + hex.charAt(1)) / 255;
    rgb.g = Std.parseInt("0x" + hex.charAt(2) + hex.charAt(2)) / 255;
    rgb.b = Std.parseInt("0x" + hex.charAt(3) + hex.charAt(3)) / 255;
  } else if (hex.length == 7) {
    rgb.r = Std.parseInt("0x" + hex.substr(1, 2)) / 255;
    rgb.g = Std.parseInt("0x" + hex.substr(3, 2)) / 255;
    rgb.b = Std.parseInt("0x" + hex.substr(5, 2)) / 255;
  }
  return rgb;
}

function colorToHex(color: {r:Float, g:Float, b:Float}): String {
  var r = Std.int(color.r * 255).toString(16).padStart(2, "0");
  var g = Std.int(color.g * 255).toString(16).padStart(2, "0");
  var b = Std.int(color.b * 255).toString(16).padStart(2, "0");
  return "#" + r + g + b;
}

class ColorController extends Controller {
  public var $input:js.html.Input;
  public var $text:js.html.Input;
  public var $display:js.html.Element;
  var _format:Dynamic;
  var _rgbScale:Float;
  var _initialValueHexString:String;
  var _textFocused:Bool;

  public function new(parent:GUI, object:Dynamic, property:String, rgbScale:Float = 1) {
    super(parent, object, property, "color");

    this.$input = cast Browser.document.createElement("input");
    this.$input.setAttribute("type", "color");
    this.$input.setAttribute("tabindex", "-1");
    this.$input.setAttribute("aria-labelledby", this.$name.id);

    this.$text = cast Browser.document.createElement("input");
    this.$text.setAttribute("type", "text");
    this.$text.setAttribute("spellcheck", "false");
    this.$text.setAttribute("aria-labelledby", this.$name.id);

    this.$display = Browser.document.createElement("div");
    this.$display.classList.add("display");
    this.$display.appendChild(this.$input);

    this.$widget.appendChild(this.$display);
    this.$widget.appendChild(this.$text);

    this._rgbScale = rgbScale;
    this._initialValueHexString = this.save();
    this._textFocused = false;

    this.$input.addEventListener("input", function(_) {
      this._setValueFromHexString(this.$input.value);
    });

    this.$input.addEventListener("blur", function(_) {
      this._callOnFinishChange();
    });

    this.$text.addEventListener("input", function(_) {
      var hex = this.$text.value;
      if (hex.length == 7 && hex.charAt(0) == "#") {
        this._setValueFromHexString(hex);
      }
    });

    this.$text.addEventListener("focus", function(_) {
      this._textFocused = true;
      this.$text.select();
    });

    this.$text.addEventListener("blur", function(_) {
      this._textFocused = false;
      this.updateDisplay();
      this._callOnFinishChange();
    });

    this.$disable = this.$text;

    this.updateDisplay();
  }

  override public function reset():Controller {
    this._setValueFromHexString(this._initialValueHexString);
    return this;
  }

  function _setValueFromHexString(hex:String) {
    var color = hexStringToColor(hex);
    var value = this.getValue();
    if (Std.isOfType(value, {r: 0, g: 0, b: 0})) {
      Reflect.setField(value, "r", color.r * this._rgbScale);
      Reflect.setField(value, "g", color.g * this._rgbScale);
      Reflect.setField(value, "b", color.b * this._rgbScale);
    }
    this._callOnChange();
    this.updateDisplay();
  }

  override public function save():String {
    return colorToHex(this.getValue());
  }

  override public function load(value:Dynamic):Controller {
    if (Std.isOfType(value, String)) {
      this._setValueFromHexString(value);
    } else if (Std.isOfType(value, {r: 0, g: 0, b: 0})) {
      this.setValue(value);
    }
    this._callOnFinishChange();
    return this;
  }

  override public function updateDisplay():Controller {
    var hexValue = this.save();
    this.$input.value = hexValue;
    if (!this._textFocused) {
      this.$text.value = hexValue.substring(1);
    }
    this.$display.style.backgroundColor = this.$input.value;
    return this;
  }
}

class FunctionController extends Controller {
  public var $button:js.html.Button;

  public function new(parent:GUI, object:Dynamic, property:String) {
    super(parent, object, property, "function", "button");
    this.$button = cast Browser.document.createElement("button");
    this.$button.appendChild(this.$name);
    this.$widget.appendChild(this.$button);

    this.$button.addEventListener("click", function(event) {
      event.preventDefault();
      Reflect.callMethod(this.object, this.getValue(), []);
    });

    this.$button.addEventListener("touchstart", function(_) {}, {passive: true});

    this.$disable = this.$button;
  }
}

class NumberController extends Controller {
  public var $input:js.html.Input;
  public var $slider:js.html.Element;
  public var $fill:js.html.Element;

  var _min:Float;
  var _max:Float;
  var _step:Float;
  var _decimals:Int;
  var _stepExplicit:Bool;
  var _hasSlider:Bool;
  var _inputFocused:Bool;

  public function new(parent:GUI, object:Dynamic, property:String, min:Float = null, max:Float = null, step:Float = null) {
    super(parent, object, property, "number");
    this._initInput();
    this.min(min);
    this.max(max);
    var stepExplicit = step != null;
    this.step(step != null ? step : this._getImplicitStep(), stepExplicit);
    this.updateDisplay();
  }

  override public function decimals(decimals:Int):Controller {
    this._decimals = decimals;
    this.updateDisplay();
    return this;
  }

  override public function min(min:Float):Controller {
    this._min = min;
    this._onUpdateMinMax();
    return this;
  }

  override public function max(max:Float):Controller {
    this._max = max;
    this._onUpdateMinMax();
    return this;
  }

  override public function step(step:Float, explicit:Bool = true):Controller {
    this._step = step;
    this._stepExplicit = explicit;
    return this;
  }

  override public function updateDisplay():Controller {
    var value = this.getValue();

    if (this._hasSlider) {
      var sliderRange = (this._max - this._min);
      var sliderValue = (value - this._min) / sliderRange;
      sliderValue = Math.max(0, Math.min(sliderValue, 1));
      this.$fill.style.width = (sliderValue * 100) + "%";
    }

    if (!this._inputFocused) {
      this.$input.value = (this._decimals != null) ? Std.format('%.${this._decimals}f', value) : Std.string(value);
    }
    return this;
  }

  function _initInput() {
    this.$input = cast Browser.document.createElement("input");
    this.$input.setAttribute("type", "number");
    this.$input.setAttribute("step", "any");
    this.$input.setAttribute("aria-labelledby", this.$name.id);
    this.$widget.appendChild(this.$input);

    this.$disable = this.$input;

    var onInput = function(_) {
      var value = Std.parseFloat(this.$input.value);
      if (!Math.isNaN(value)) {
        if (this._stepExplicit) {
          value = this._snap(value);
        }
        this.setValue(this._clamp(value));
      }
    };

    var onKeyDown = function(event:js.html.KeyboardEvent) {
      switch (event.code) {
        case "Enter":
          this.$input.blur();
        case "ArrowUp":
          event.preventDefault();
          this._modifyValue(this._step * this._arrowKeyMultiplier(event));
        case "ArrowDown":
          event.preventDefault();
          this._modifyValue(this._step * this._arrowKeyMultiplier(event) * -1);
        case _:
      }
    };

    var onWheel = function(event:js.html.WheelEvent) {
      if (this._inputFocused) {
        event.preventDefault();
        this._modifyValue(this._step * this._normalizeMouseWheel(event));
      }
    };

    var onMouseDown = function(event:js.html.MouseEvent) {
      // Set up dragging
    };

    var onFocus = function(_) {
      this._inputFocused = true;
    };

    var onBlur = function(_) {
      this._inputFocused = false;
      this.updateDisplay();
      this._callOnFinishChange();
    };

    this.$input.addEventListener("input", onInput);
    this.$input.addEventListener("keydown", onKeyDown);
    this.$input.addEventListener("wheel", onWheel, {passive: false});
    this.$input.addEventListener("mousedown", onMouseDown);
    this.$input.addEventListener("focus", onFocus);
    this.$input.addEventListener("blur", onBlur);
  }

  function _modifyValue(amount:Float) {
    var value = Std.parseFloat(this.$input.value);
    if (Math.isNaN(value)) value = 0;
    this._snapClampSetValue(value + amount);
    this.$input.value = Std.string(this.getValue());
  }

  function _initSlider() {
    this._hasSlider = true;

    this.$slider = Browser.document.createElement("div");
    this.$slider.classList.add("slider");

    this.$fill = Browser.document.createElement("div");
    this.$fill.classList.add("fill");

    this.$slider.appendChild(this.$fill);
    this.$widget.insertBefore(this.$slider, this.$input);
    this.domElement.classList.add("hasSlider");

    var onMouseDown = function(event:js.html.MouseEvent) {
      // Set up dragging
    };

    var onTouchStart = function(event:js.html.TouchEvent) {
      // Set up dragging
    };

    var onWheel = function(event:js.html.WheelEvent) {
      if (Math.abs(event.deltaX) < Math.abs(event.deltaY) && this._hasScrollBar) {
        return;
      }
      event.preventDefault();
      var value = this.getValue() + (this._normalizeMouseWheel(event) * this._step);
      this._snapClampSetValue(value);
      this.$input.value = Std.string(this.getValue());
      // Set up delayed call to onFinishChange
    };

    this.$slider.addEventListener("mousedown", onMouseDown);
    this.$slider.addEventListener("touchstart", onTouchStart, {passive: false});
    this.$slider.addEventListener("wheel", onWheel, {passive: false});
  }

  function _setDraggingStyle(dragging:Bool, direction:String = "horizontal") {
    if (this.$slider != null) {
      this.$slider.classList.toggle("active", dragging);
    }
    Browser.document.body.classList.toggle("lil-gui-dragging", dragging);
    Browser.document.body.classList.toggle("lil-gui-" + direction, dragging);
  }

  function _getImplicitStep():Float {
    if (this._hasMin && this._hasMax) {
      return (this._max - this._min) / 1000;
    } else {
      return 0.1;
    }
  }

  function _onUpdateMinMax() {
    if (!this._hasSlider && this._hasMin && this._hasMax) {
      if (!this._stepExplicit) {
        this.step(this._getImplicitStep(), false);
      }
      this._initSlider();
      this.updateDisplay();
    }
  }

  function _normalizeMouseWheel(event:js.html.WheelEvent):Float {
    var {deltaX: dx, deltaY: dy} = event;
    if (Math.floor(event.deltaY) != event.deltaY && event.wheelDelta != null) {
      dx = 0;
      dy = -event.wheelDelta / 120;
      dy *= (this._stepExplicit ? 1 : 10);
    }
    return dx + -dy;
  }

  function _arrowKeyMultiplier(event:js.html.KeyboardEvent):Float {
    var multiplier = this._stepExplicit ? 1 : 10;
    if (event.shiftKey) {
      multiplier *= 10;
    } else if (event.altKey) {
      multiplier /= 10;
    }
    return multiplier;
  }

  function _snap(value:Float):Float {
    return Std.parseFloat(Std.string(Math.round(value / this._step) * this._step));
  }

  function _clamp(value:Float):Float {
    if (value < this._min) {
      return this._min;
    } else if (value > this._max) {
      return this._max;
    } else {
      return value;
    }
  }

  function _snapClampSetValue(value:Float) {
    this.setValue(this._clamp(this._snap(value)));
  }

  function get_hasScrollBar():Bool {
    var scrollHeight = this.parent.root.$children.scrollHeight;
    var clientHeight = this.parent.root.$children.clientHeight;
    return scrollHeight > clientHeight;
  }

  var _hasScrollBar(get, never):Bool;
  function get_hasScrollBar():Bool {
    return this.parent.root.$children.scrollHeight > this.parent.root.$children.clientHeight;
  }

  function get_hasMin():Bool {
    return this._min != null;
  }

  var _hasMin(get, never):Bool;
  function get_hasMin():Bool {
    return this._min != null;
  }

  function get_hasMax():Bool {
    return this._max != null;
  }

  var _hasMax(get, never):Bool;
  function get_hasMax():Bool {
    return this._max != null;
  }
}

class OptionController extends Controller {
  public var $select:js.html.Select;
  public var $display:js.html.Element;
  var _values:Array<Dynamic>;
  var _names:Array<String>;

  public function new(parent:GUI, object:Dynamic, property:String, options:Dynamic) {
    super(parent, object, property, "option");

    this.$select = cast Browser.document.createElement("select");
    this.$select.setAttribute("aria-labelledby", this.$name.id);

    this.$display = Browser.document.createElement("div");
    this.$display.classList.add("display");

    if (Std.isOfType(options, Array)) {
      this._values = options;
      this._names = options;
    } else {
      this._values = Reflect.fields(options).map(function(key:String) {
        return Reflect.field(options, key);
      });
      this._names = Reflect.fields(options);
    }

    for (name in this._names) {
      var $option = Browser.document.createElement("option");
      $option.innerHTML = name;
      this.$select.appendChild($option);
    }

    this.$select.addEventListener("change", function(_) {
      this.setValue(this._values[this.$select.selectedIndex]);
      this._callOnFinishChange();
    });

    this.$select.addEventListener("focus", function(_) {
      this.$display.classList.add("focus");
    });

    this.$select.addEventListener("blur", function(_) {
      this.$display.classList.remove("focus");
    });

    this.$widget.appendChild(this.$select);
    this.$widget.appendChild(this.$display);

    this.$disable = this.$select;

    this.updateDisplay();
  }

  override public function updateDisplay():Controller {
    var value = this.getValue();
    var index = this._values.indexOf(value);
    this.$select.selectedIndex = index;
    this.$display.innerHTML = (index == -1) ? Std.string(value) : this._names[index];
    return this;
  }
}

class StringController extends Controller {
  public var $input:js.html.Input;

  public function new(parent:GUI, object:Dynamic, property:String) {
    super(parent, object, property, "string");

    this.$input = cast Browser.document.createElement("input");
    this.$input.setAttribute("type", "text");
    this.$input.setAttribute("aria-labelledby", this.$name.id);

    this.$input.addEventListener("input", function(_) {
      this.setValue(this.$input.value);
    });

    this.$input.addEventListener("keydown", function(event:js.html.KeyboardEvent) {
      if (event.code == "Enter") {
        this.$input.blur();
      }
    });

    this.$input.addEventListener("blur", function(_) {
      this._callOnFinishChange();
    });

    this.$widget.appendChild(this.$input);

    this.$disable = this.$input;

    this.updateDisplay();
  }

  override public function updateDisplay():Controller {
    this.$input.value = this.getValue();
    return this;
  }
}

class GUI {
  public var parent:GUI;
  public var root:GUI;
  public var children:Array<Dynamic>;
  public var controllers:Array<Controller>;
  public var folders:Array<GUI>;
  public var domElement:js.html.Element;
  public var $title:js.html.Element;
  public var $children:js.html.Element;

  var _title:String;
  var _closed:Bool;
  var _hidden:Bool;
  var _onChange:Dynamic->Void;
  var _onFinishChange:Dynamic->Void;

  static var _staticInit:Bool = false;

  public function new(?options: {
    parent:GUI,
    autoPlace:Bool,
    container:js.html.Element,
    width:Int,
    title:String,
    injectStyles:Bool,
    touchStyles:Bool
  }) {
    options = options != null ? options : {};

    this.parent = options.parent;
    this.root = (this.parent != null) ? this.parent.root : this;
    this.children = [];
    this.controllers = [];
    this.folders = [];
    this._closed = false;
    this._hidden = false;

    this.domElement = Browser.document.createElement("div");
    this.domElement.classList.add("lil-gui");

    this.$title = Browser.document.createElement("div");
    this.$title.classList.add("title");
    this.$title.setAttribute("role", "button");
    this.$title.setAttribute("aria-expanded", "true");
    this.$title.setAttribute("tabindex", "0");

    this.$title.addEventListener("click", function(_) {
      this.openAnimated(this._closed);
    });

    this.$title.addEventListener("keydown", function(event:js.html.KeyboardEvent) {
      if (event.code == "Enter" || event.code == "Space") {
        event.preventDefault();
        this.$title.click();
      }
    });

    this.$title.addEventListener("touchstart", function(_) {}, {passive: true});

    this.$children = Browser.document.createElement("div");
    this.$children.classList.add("children");

    this.domElement.appendChild(this.$title);
    this.domElement.appendChild(this.$children);

    this.title(options.title != null ? options.title : "Controls");

    if (options.touchStyles) {
      this.domElement.classList.add("allow-touch-styles");
    }

    if (this.parent != null) {
      this.parent.children.push(this);
      this.parent.folders.push(this);
      this.parent.$children.appendChild(this.domElement);
    } else {
      this.domElement.classList.add("root");
      if (!_staticInit && (options.injectStyles != false)) {
        _injectStyles();
        _staticInit = true;
      }
      if (options.container != null) {
        options.container.appendChild(this.domElement);
      } else if (options.autoPlace != false) {
        this.domElement.classList.add("autoPlace");
        Browser.document.body.appendChild(this.domElement);
      }
    }

    if (options.width != null) {
      this.domElement.style.setProperty("--width", options.width + "px");
    }

    this.domElement.addEventListener("keydown", function(event:js.html.KeyboardEvent) {
      event.stopPropagation();
    });

    this.domElement.addEventListener("keyup", function(event:js.html.KeyboardEvent) {
      event.stopPropagation();
    });
  }

  public function add(object:Dynamic, property:String, ?min:Dynamic, ?max:Dynamic, ?step:Dynamic):Controller {
    if (Reflect.isObject(min)) {
      return new OptionController(this, object, property, min);
    }

    var type = Type.typeof(Reflect.field(object, property));
    switch (type) {
      case TFloat, TInt:
        return new NumberController(this, object, property, min, max, step);
      case TBool:
        return new BooleanController(this, object, property);
      case TClass(String):
        return new StringController(this, object, property);
      case TFunction:
        return new FunctionController(this, object, property);
      case _:
        throw "Unsupported type: " + type;
    }
  }

  public function addColor(object:Dynamic, property:String, rgbScale:Float = 1):ColorController {
    return new ColorController(this, object, property, rgbScale);
  }

  public function addFolder(title:String):GUI {
    return new GUI({parent: this, title: title});
  }

  public function load(data:Dynamic, recursive:Bool = true):GUI {
    if (data.controllers != null) {
      for (controller in this.controllers) {
        if (!(controller is FunctionController) && Reflect.hasField(data.controllers, controller._name)) {
          controller.load(Reflect.field(data.controllers, controller._name));
        }
      }
    }
    if (recursive && data.folders != null) {
      for (folder in this.folders) {
        if (Reflect.hasField(data.folders, folder._title)) {
          folder.load(Reflect.field(data.folders, folder._title));
        }
      }
    }
    return this;
  }

  public function save(recursive:Bool = true):Dynamic {
    var data = {controllers: {}, folders: {}};
    for (controller in this.controllers) {
      if (!(controller is FunctionController)) {
        if (Reflect.hasField(data.controllers, controller._name)) {
          throw 'Cannot save GUI with duplicate property "${controller._name}"';
        }
        Reflect.setField(data.controllers, controller._name, controller.save());
      }
    }
    if (recursive) {
      for (folder in this.folders) {
        if (Reflect.hasField(data.folders, folder._title)) {
          throw 'Cannot save GUI with duplicate folder "${folder._title}"';
        }
        Reflect.setField(data.folders, folder._title, folder.save());
      }
    }
    return data;
  }

  public function open(open:Bool = true):GUI {
    this._closed = !open;
    this.$title.setAttribute("aria-expanded", Std.string(!this._closed));
    this.domElement.classList.toggle("closed", this._closed);
    return this;
  }

  public function close():GUI {
    return this.open(false);
  }

  public function show(show:Bool = true):GUI {
    this._hidden = !show;
    this.domElement.style.display = this._hidden ? "none" : "";
    return this;
  }

  public function hide():GUI {
    return this.show(false);
  }

  public function openAnimated(open:Bool = true):GUI {
    this._closed = !open;
    this.$title.setAttribute("aria-expanded", Std.string(!this._closed));

    Browser.window.requestAnimationFrame(function(_) {
      var height = this.$children.clientHeight;
      this.$children.style.height = height + "px";
      this.domElement.classList.add("transition");

      var onTransitionEnd = function(event:js.html.Event) {
        if (event.target == this.$children) {
          this.$children.style.height = "";
          this.domElement.classList.remove("transition");
          this.$children.removeEventListener("transitionend", onTransitionEnd);
        }
      };

      this.$children.addEventListener("transitionend", onTransitionEnd);

      var targetHeight = open ? this.$children.scrollHeight : 0;
      this.domElement.classList.toggle("closed", !open);

      Browser.window.requestAnimationFrame(function(_) {
        this.$children.style.height = target
       this.$children.style.height = targetHeight + "px";
      });
    });
    return this;
  }

  public function title(title:String):GUI {
    this._title = title;
    this.$title.innerHTML = title;
    return this;
  }

  public function reset(recursive:Bool = true):GUI {
    for (controller in (recursive ? this.controllersRecursive() : this.controllers)) {
      controller.reset();
    }
    return this;
  }

  public function onChange(callback:Dynamic->Void):GUI {
    this._onChange = callback;
    return this;
  }

  function _callOnChange(controller:Controller) {
    if (this.parent != null) {
      this.parent._callOnChange(controller);
    }
    if (this._onChange != null) {
      this._onChange({
        object: controller.object,
        property: controller.property,
        value: controller.getValue(),
        controller: controller
      });
    }
  }

  public function onFinishChange(callback:Dynamic->Void):GUI {
    this._onFinishChange = callback;
    return this;
  }

  function _callOnFinishChange(controller:Controller) {
    if (this.parent != null) {
      this.parent._callOnFinishChange(controller);
    }
    if (this._onFinishChange != null) {
      this._onFinishChange({
        object: controller.object,
        property: controller.property,
        value: controller.getValue(),
        controller: controller
      });
    }
  }

  public function destroy():Void {
    if (this.parent != null) {
      this.parent.children.remove(this);
      this.parent.folders.remove(this);
    }
    if (this.domElement.parentElement != null) {
      this.domElement.parentElement.removeChild(this.domElement);
    }
    for (child in this.children) {
      if (Std.isOfType(child, GUI)) {
        cast(child, GUI).destroy();
      } else if (Std.isOfType(child, Controller)) {
        cast(child, Controller).destroy();
      }
    }
  }

  public function controllersRecursive():Array<Controller> {
    var controllers = this.controllers.copy();
    for (folder in this.folders) {
      controllers = controllers.concat(folder.controllersRecursive());
    }
    return controllers;
  }

  public function foldersRecursive():Array<GUI> {
    var folders = this.folders.copy();
    for (folder in this.folders) {
      folders = folders.concat(folder.foldersRecursive());
    }
    return folders;
  }
}

function _injectStyles():Void {
  var style = Browser.document.createElement("style");
  style.innerHTML = '.lil-gui{--background-color:#1f1f1f;--text-color:#ebebeb;--title-background-color:#111;--title-text-color:#ebebeb;--widget-color:#424242;--hover-color:#4f4f4f;--focus-color:#595959;--number-color:#2cc9ff;--string-color:#a2db3c;--font-size:11px;--input-font-size:11px;--font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Arial,sans-serif;--font-family-mono:Menlo,Monaco,Consolas,"Droid Sans Mono",monospace;--padding:4px;--spacing:4px;--widget-height:20px;--name-width:45%;--slider-knob-width:2px;--slider-input-width:27%;--color-input-width:27%;--slider-input-min-width:45px;--color-input-min-width:45px;--folder-indent:7px;--widget-padding:0 0 0 3px;--widget-border-radius:2px;--checkbox-size:calc(var(--widget-height)*0.75);--scrollbar-width:5px;background-color:var(--background-color);color:var(--text-color);font-family:var(--font-family);font-size:var(--font-size);font-style:normal;font-weight:400;line-height:1;text-align:left;touch-action:manipulation;user-select:none;-webkit-user-select:none}.lil-gui,.lil-gui *{box-sizing:border-box;margin:0;padding:0}.lil-gui.root{display:flex;flex-direction:column;width:var(--width,245px)}.lil-gui.root>.title{background:var(--title-background-color);color:var(--title-text-color)}.lil-gui.root>.children{overflow-x:hidden;overflow-y:auto}.lil-gui.root>.children::-webkit-scrollbar{background:var(--background-color);height:var(--scrollbar-width);width:var(--scrollbar-width)}.lil-gui.root>.children::-webkit-scrollbar-thumb{background:var(--focus-color);border-radius:var(--scrollbar-width)}.lil-gui.force-touch-styles{--widget-height:28px;--padding:6px;--spacing:6px;--font-size:13px;--input-font-size:16px;--folder-indent:10px;--scrollbar-width:7px;--slider-input-min-width:50px;--color-input-min-width:65px}.lil-gui.autoPlace{max-height:100%;position:fixed;right:15px;top:0;z-index:1001}.lil-gui .controller{align-items:center;display:flex;margin:var(--spacing) 0;padding:0 var(--padding)}.lil-gui .controller.disabled{opacity:.5}.lil-gui .controller.disabled,.lil-gui .controller.disabled *{pointer-events:none!important}.lil-gui .controller>.name{flex-shrink:0;line-height:var(--widget-height);min-width:var(--name-width);padding-right:var(--spacing);white-space:pre}.lil-gui .controller .widget{align-items:center;display:flex;min-height:var(--widget-height);position:relative;width:100%}.lil-gui .controller.string input{color:var(--string-color)}.lil-gui .controller.boolean .widget{cursor:pointer}.lil-gui .controller.color .display{border-radius:var(--widget-border-radius);height:var(--widget-height);position:relative;width:100%}.lil-gui .controller.color input[type=color]{cursor:pointer;height:100%;opacity:0;width:100%}.lil-gui .controller.color input[type=text]{flex-shrink:0;font-family:var(--font-family-mono);margin-left:var(--spacing);min-width:var(--color-input-min-width);width:var(--color-input-width)}.lil-gui .controller.option select{max-width:100%;opacity:0;position:absolute;width:100%}.lil-gui .controller.option .display{background:var(--widget-color);border-radius:var(--widget-border-radius);height:var(--widget-height);line-height:var(--widget-height);max-width:100%;overflow:hidden;padding-left:.55em;padding-right:1.75em;pointer-events:none;position:relative;word-break:break-all}.lil-gui .controller.option .display.active{background:var(--focus-color)}.lil-gui .controller.option .display:after{bottom:0;content:"↕";font-family:lil-gui;padding-right:.375em;position:absolute;right:0;top:0}.lil-gui .controller.option .widget,.lil-gui .controller.option select{cursor:pointer}.lil-gui .controller.number input{color:var(--number-color)}.lil-gui .controller.number.hasSlider input{flex-shrink:0;margin-left:var(--spacing);min-width:var(--slider-input-min-width);width:var(--slider-input-width)}.lil-gui .controller.number .slider{background-color:var(--widget-color);border-radius:var(--widget-border-radius);cursor:ew-resize;height:var(--widget-height);overflow:hidden;padding-right:var(--slider-knob-width);touch-action:pan-y;width:100%}.lil-gui .controller.number .slider.active{background-color:var(--focus-color)}.lil-gui .controller.number .slider.active .fill{opacity:.95}.lil-gui .controller.number .fill{border-right:var(--slider-knob-width) solid var(--number-color);box-sizing:content-box;height:100%}.lil-gui-dragging .lil-gui{--hover-color:var(--widget-color)}.lil-gui-dragging *{cursor:ew-resize!important}.lil-gui-dragging.lil-gui-vertical *{cursor:ns-resize!important}.lil-gui .title{--title-height:calc(var(--widget-height) + var(--spacing)*1.25);-webkit-tap-highlight-color:transparent;text-decoration-skip:objects;cursor:pointer;font-weight:600;height:var(--title-height);line-height:calc(var(--title-height) - 4px);outline:none;padding:0 var(--padding)}.lil-gui .title:before{content:"▾";display:inline-block;font-family:lil-gui;padding-right:2px}.lil-gui .title:active{background:var(--title-background-color);opacity:.75}.lil-gui.root>.title:focus{text-decoration:none!important}.lil-gui.closed>.title:before{content:"▸"}.lil-gui.closed>.children{opacity:0;transform:translateY(-7px)}.lil-gui.closed:not(.transition)>.children{display:none}.lil-gui.transition>.children{overflow:hidden;pointer-events:none;transition-duration:.3s;transition-property:height,opacity,transform;transition-timing-function:cubic-bezier(.2,.6,.35,1)}.lil-gui .children:empty:before{content:"Empty";display:block;font-style:italic;height:var(--widget-height);line-height:var(--widget-height);margin:var(--spacing) 0;opacity:.5;padding:0 var(--padding)}.lil-gui.root>.children>.lil-gui>.title{border-width:0;border-bottom:1px solid var(--widget-color);border-left:0 solid var(--widget-color);border-right:0 solid var(--widget-color);border-top:1px solid var(--widget-color);transition:border-color .3s}.lil-gui.root>.children>.lil-gui.closed>.title{border-bottom-color:transparent}.lil-gui+.controller{border-top:1px solid var(--widget-color);margin-top:0;padding-top:var(--spacing)}.lil-gui .lil-gui .lil-gui>.title{border:none}.lil-gui .lil-gui .lil-gui>.children{border:none;border-left:2px solid var(--widget-color);margin-left:var(--folder-indent)}.lil-gui .lil-gui .controller{border:none}.lil-gui input{-webkit-tap-highlight-color:transparent;background:var(--widget-color);border:0;border-radius:var(--widget-border-radius);color:var(--text-color);font-family:var(--font-family);font-size:var(--input-font-size);height:var(--widget-height);outline:none;width:100%}.lil-gui input:disabled{opacity:1}.lil-gui input[type=number],.lil-gui input[type=text]{padding:var(--widget-padding)}.lil-gui input[type=number]:focus,.lil-gui input[type=text]:focus{background:var(--focus-color)}.lil-gui input::-webkit-inner-spin-button,.lil-gui input::-webkit-outer-spin-button{-webkit-appearance:none;margin:0}.lil-gui input[type=number]{-moz-appearance:textfield}.lil-gui input[type=checkbox]{appearance:none;-webkit-appearance:none;border-radius:var(--widget-border-radius);cursor:pointer;height:var(--checkbox-size);text-align:center;width:var(--checkbox-size)}.lil-gui input[type=checkbox]:checked:before{content:"✓";font-family:lil-gui;font-size:var(--checkbox-size);line-height:var(--checkbox-size)}.lil-gui button{-webkit-tap-highlight-color:transparent;background:var(--widget-color);border:1px solid var(--widget-color);border-radius:var(--widget-border-radius);color:var(--text-color);cursor:pointer;font-family:var(--font-family);font-size:var(--font-size);height:var(--widget-height);line-height:calc(var(--widget-height) - 4px);outline:none;text-align:center;text-transform:none;width:100%}.lil-gui button:active{background:var(--focus-color)}@font-face{font-family:lil-gui;src:url("data:application/font-woff;charset=utf-8;base64,d09GRgABAAAAAAUsAAsAAAAACJwAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAABHU1VCAAABCAAAAH4AAADAImwmYE9TLzIAAAGIAAAAPwAAAGBKqH5SY21hcAAAAcgAAAD0AAACrukyyJBnbHlmAAACvAAAAF8AAACEIZpWH2hlYWQAAAMcAAAAJwAAADZfcj2zaGhlYQAAA0QAAAAYAAAAJAC5AHhobXR4AAADXAAAABAAAABMAZAAAGxvY2EAAANsAAAAFAAAACgCEgIybWF4cAAAA4AAAAAeAAAAIAEfABJuYW1lAAADoAAAASIAAAIK9SUU/XBvc3QAAATEAAAAZgAAAJCTcMc2eJxVjbEOgjAURU+hFRBK1dGRL+ALnAiToyMLEzFpnPz/eAshwSa97517c/MwwJmeB9kwPl+0cf5+uGPZXsqPu4nvZabcSZldZ6kfyWnomFY/eScKqZNWupKJO6kXN3K9uCVoL7iInPr1X5baXs3tjuMqCtzEuagm/AAlzQgPAAB4nGNgYRBlnMDAysDAYM/gBiT5oLQBAwuDJAMDEwMrMwNWEJDmmsJwgCFeXZghBcjlZMgFCzOiKOIFAB71Bb8AeJy1kjFuwkAQRZ+DwRAwBtNQRUGKQ8OdKCAWUhAgKLhIuAsVSpWz5Bbkj3dEgYiUIszqWdpZe+Z7/wB1oCYmIoboiwiLT2WjKl/jscrHfGg/pKdMkyklC5Zs2LEfHYpjcRoPzme9MWWmk3dWbK9ObkWkikOetJ554fWyoEsmdSlt+uR0pCJR34b6t/TVg1SY3sYvdf8vuiKrpyaDXDISiegp17p7579Gp3p++y7HPAiY9pmTibljrr85qSidtlg4+l25GLCaS8e6rRxNBmsnERunKbaOObRz7N72ju5vdAjYpBXHgJylOAVsMseDAPEP8LYoUHicY2BiAAEfhiAGJgZWBgZ7RnFRdnVJELCQlBSRlATJMoLV2DK4glSYs6ubq5vbKrJLSbGrgEmovDuDJVhe3VzcXFwNLCOILB/C4IuQ1xTn5FPilBTj5FPmBAB4WwoqAHicY2BkYGAA4sk1sR/j+W2+MnAzpDBgAyEMQUCSg4EJxAEAwUgFHgB4nGNgZGBgSGFggJMhDIwMqEAYAByHATJ4nGNgAIIUNEwmAABl3AGReJxjYAACIQYlBiMGJ3wQAEcQBEV4nGNgZGBgEGZgY2BiAAEQyQWEDAz/wXwGAAsPATIAAHicXdBNSsNAHAXwl35iA0UQXYnMShfS9GPZA7T7LgIu03SSpkwzYTIt1BN4Ak/gKTyAeCxfw39jZkjymzcvAwmAW/wgwHUEGDb36+jQQ3GXGot79L24jxCP4gHzF/EIr4jEIe7wxhOC3g2TMYy4Q7+Lu/SHuEd/ivt4wJd4wPxbPEKMX3GI5+DJFGaSn4qNzk8mcbKSR6xdXdhSzaOZJGtdapd4vVPbi6rP+cL7TGXOHtXKll4bY1Xl7EGnPtp7Xy2n00zyKLVHfkHBa4IcJ2oD3cgggWvt/V/FbDrUlEUJhTn/0azVWbNTNr0Ens8de1tceK9xZmfB1CPjOmPH4kitmvOubcNpmVTN3oFJyjzCvnmrwhJTzqzVj9jiSX911FjeAAB4nG3HMRKCMBBA0f0giiKi4DU8k0V2GWbIZDOh4PoWWvq6J5V8If9NVNQcaDhyouXMhY4rPTcG7jwYmXhKq8Wz+p762aNaeYXom2n3m2dLTVgsrCgFJ7OTmIkYbwIbC6vIB7WmFfAAAA==") format("woff")}@media (pointer:coarse){.lil-gui.allow-touch-styles{--widget-height:28px;--padding:6px;--spacing:6px;--font-size:13px;--input-font-size:16px;--folder-indent:10px;--scrollbar-width:7px;--slider-input-min-width:50px;--color-input-min-width:65px}}@media (hover:hover){.lil-gui .controller.color .display:hover:before{border:1px solid #fff9;border-radius:var(--widget-border-radius);bottom:0;content:" ";display:block;left:0;position:absolute;right:0;top:0}.lil-gui .controller.option .display.focus{background:var(--focus-color)}.lil-gui .controller.option .widget:hover .display{background:var(--hover-color)}.lil-gui .controller.number .slider:hover{background-color:var(--hover-color)}body:not(.lil-gui-dragging) .lil-gui .title:hover{background:var(--title-background-color);opacity:.85}.lil-gui .title:focus{text-decoration:underline var(--focus-color)}.lil-gui input:hover{background:var(--hover-color)}.lil-gui input:active{background:var(--focus-color)}.lil-gui input[type=checkbox]:focus{box-shadow:inset 0 0 0 1px var(--focus-color)}.lil-gui button:hover{background:var(--hover-color);border-color:var(--hover-color)}.lil-gui button:focus{border-color:var(--focus-color)}}';

  var firstLinkOrStyle = Browser.document.querySelector('head link[rel=stylesheet], head style');
  if (firstLinkOrStyle != null) {
    Browser.document.head.insertBefore(style, firstLinkOrStyle);
  } else {
    Browser.document.head.appendChild(style);
  }
}