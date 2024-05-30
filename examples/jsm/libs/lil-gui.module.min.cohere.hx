/**
 * lil-gui
 * https://lil-gui.georgealways.com
 * @version 0.17.0
 * @author George Michael Brower
 * @license MIT
 */
class t {
    public var parent:Dynamic;
    public var object:Dynamic;
    public var property:Dynamic;
    public var _disabled:Bool;
    public var _hidden:Bool;
    public var initialValue:Dynamic;
    public var domElement:Dynamic;
    public var $name:Dynamic;
    public static var nextNameID:Int;
    public var $widget:Dynamic;
    public var $disable:Dynamic;
    public function new(i:Dynamic, e:Dynamic, s:Dynamic, n:Dynamic, l:Dynamic = "div") {
        this.parent = i;
        this.object = e;
        this.property = s;
        this._disabled = false;
        this._hidden = false;
        this.initialValue = this.getValue();
        this.domElement = untyped __js__("document.createElement(\"div\")");
        this.domElement.@classList.add("controller");
        this.domElement.@classList.add(n);
        this.$name = untyped __js__("document.createElement(\"div\")");
        this.$name.@classList.add("name");
        if (t.nextNameID == null) {
            t.nextNameID = 0;
        }
        this.$name.id = "lil-gui-name-" + (t.nextNameID + 1);
        this.$widget = untyped __js__("document.createElement")(l);
        this.$widget.@classList.add("widget");
        this.$disable = this.$widget;
        this.domElement.appendChild(this.$name);
        this.domElement.appendChild(this.$widget);
        this.parent.children.push(this);
        this.parent.controllers.push(this);
        this.parent.$children.appendChild(this.domElement);
        this._listenCallback = this._listenCallback.bind(this);
        this.name(s);
    }

    public function name(t:Dynamic):Dynamic {
        this._name = t;
        this.$name.innerHTML = t;
        return this;
    }

    public function onChange(t:Dynamic):Dynamic {
        this._onChange = t;
        return this;
    }

    public function _callOnChange():Void {
        this.parent._callOnChange(this);
        if (this._onChange != null) {
            this._onChange.call(this, this.getValue());
        }
        this._changed = true;
    }

    public function onFinishChange(t:Dynamic):Dynamic {
        this._onFinishChange = t;
        return this;
    }

    public function _callOnFinishChange():Void {
        if (this._changed) {
            this.parent._callOnFinishChange(this);
            if (this._onFinishChange != null) {
                this._onFinishChange.call(this, this.getValue());
            }
        }
        this._changed = false;
    }

    public function reset():Dynamic {
        this.setValue(this.initialValue);
        this._callOnFinishChange();
        return this;
    }

    public function enable(t:Dynamic = true):Dynamic {
        return this.disable(!t);
    }

    public function disable(t:Dynamic = true):Dynamic {
        if (t != this._disabled) {
            this._disabled = t;
            this.domElement.@classList.toggle("disabled", t);
            this.$disable.toggleAttribute("disabled", t);
        }
        return this;
    }

    public function show(t:Dynamic = true):Dynamic {
        this._hidden = !t;
        this.domElement.style.display = this._hidden ? "none" : "";
        return this;
    }

    public function hide():Dynamic {
        return this.show(false);
    }

    public function options(t:Dynamic):Dynamic {
        var i = this.parent.add(this.object, this.property, t);
        i.name(this._name);
        this.destroy();
        return i;
    }

    public function min(t:Dynamic):Dynamic {
        return this;
    }

    public function max(t:Dynamic):Dynamic {
        return this;
    }

    public function step(t:Dynamic, i:Dynamic = true):Dynamic {
        return this;
    }

    public function decimals(t:Dynamic):Dynamic {
        return this;
    }

    public function listen(t:Dynamic = true):Dynamic {
        this._listening = t;
        if (this._listenCallbackID != null) {
            untyped __js__("cancelAnimationFrame")(this._listenCallbackID);
            this._listenCallbackID = null;
        }
        if (this._listening) {
            this._listenCallback();
        }
        return this;
    }

    public function _listenCallback():Void {
        this._listenCallbackID = untyped __js__("requestAnimationFrame")(this._listenCallback);
        var t = this.save();
        if (t != this._listenPrevValue) {
            this.updateDisplay();
        }
        this._listenPrevValue = t;
    }

    public function getValue():Dynamic {
        return this.object[this.property];
    }

    public function setValue(t:Dynamic):Dynamic {
        this.object[this.property] = t;
        this._callOnChange();
        this.updateDisplay();
        return this;
    }

    public function updateDisplay():Dynamic {
        return this;
    }

    public function load(t:Dynamic):Dynamic {
        this.setValue(t);
        this._callOnFinishChange();
        return this;
    }

    public function save():Dynamic {
        return this.getValue();
    }

    public function destroy():Void {
        this.listen(false);
        this.parent.children.splice(this.parent.children.indexOf(this), 1);
        this.parent.controllers.splice(this.parent.controllers.indexOf(this), 1);
        this.parent.$children.removeChild(this.domElement);
    }
}

class i extends t {
    public var $input:Dynamic;

    public function new(t:Dynamic, i:Dynamic, e:Dynamic) {
        super(t, i, e, "boolean", "label");
        this.$input = untyped __js__("document.createElement")("input");
        this.$input.setAttribute("type", "checkbox");
        this.$input.setAttribute("aria-labelledby", this.$name.id);
        this.$widget.appendChild(this.$input);
        this.$input.addEventListener("change", () -> {
            this.setValue(this.$input.checked);
            this._callOnFinishChange();
        });
        this.$disable = this.$input;
        this.updateDisplay();
    }

    public function updateDisplay():Dynamic {
        this.$input.checked = this.getValue();
        return this;
    }
}

function e(t:Dynamic):Dynamic {
    var i:Dynamic, e:Dynamic;
    if ((i = t.match(/#|0x)?([a-f0-9]{6})/i)) {
        e = i[2];
    } else if ((i = t.match(/rgb\(\s*(\d*)\s*,\s*(\d*)\s*,\s*(\d*)\s*\)/))) {
        e = Std.parseInt(i[1]).toString(16).padStart(2, "0") + Std.parseInt(i[2]).toString(16).padStart(2, "0") + Std.parseInt(i[3]).toString(16).padString(2, "0");
    } else if ((i = t.match(/^#?([a-f0-9])([a-f0-9])([a-f0-9])$/i))) {
        e = i[1] + i[1] + i[2] + i[2] + i[3] + i[3];
    }
    if (e != null) {
        return "#" + e;
    } else {
        return null;
    }
}

class s {
    public static var isPrimitive:Bool;
    public static function match(t:Dynamic):Bool {
        return __typeof(t) == "String";
    }

    public static function fromHexString(e:Dynamic, i:Dynamic, s:Dynamic = 1):Dynamic {
        var n = n.fromHexString(t);
        i[0] = (n >> 16 & 255) / 255 * s;
        i[1] = (n >> 8 & 255) / 255 * s;
        i[2] = (255 & n) / 255 * s;
    }

    public static function toHexString(t:Dynamic, i:Dynamic = 1):Dynamic {
        return n.toHexString(t * (s = 255 / i) << 16 ^ i * s << 8 ^ e * s << 0);
    }
}

class n {
    public static var isPrimitive:Bool;
    public static function match(t:Dynamic):Bool {
        return __typeof(t) == "Float";
    }

    public static function fromHexString(t:Dynamic, i:Dynamic, e:Dynamic = 1):Dynamic {
        var s = n.fromHexString(t);
        i.r = (s >> 16 & 255) / 255 * e;
        i.g = (s >> 8 & 255) / 255 * e;
        i.b = (255 & s) / 255 * e;
    }

    public static function toHexString(t:Dynamic, i:Dynamic = 1):Dynamic {
        return n.toHexString(t * (i = 255 / i) << 16 ^ i * i << 8 ^ e * i << 0);
    }
}

class l {
    public static var isPrimitive:Bool;
    public static function match(t:Dynamic):Bool {
        return __typeof(t) == "Array";
    }

    public static function fromHexString(t:Dynamic, i:Dynamic, e:Dynamic = 1):Dynamic {
        var s = n.fromHexString(t);
        i[0] = (s >> 16 & 255) / 255 * e;
        i[1] = (s >> 8 & 255) / 255 * e;
        i[2] = (255 & s) / 255 * e;
    }

    public static function toHexString(t:Dynamic, i:Dynamic = 1):Dynamic {
        return n.toHexString(t * (i = 255 / i) << 16 ^ i * i << 8 ^ e * i << 0);
    }
}

class r {
    public static var isPrimitive:Bool;
    public static function match(t:Dynamic):Bool {
        return __typeof(t) == "Object";
    }

    public static function fromHexString(t:Dynamic, i:Dynamic, e:Dynamic = 1):Dynamic {
        var s = n.fromHexString(t);
        i.r = (s >> 16 & 255) / 255 * e;
        i.g = (s >> 8 & 255) / 255 * e;
        i.b = (255 & s) / 255 * e;
    }

    public static function toHexString(t:Dynamic, i:Dynamic = 1):Dynamic {
        return n.toHexString(t * (i = 255 / i) << 16 ^ i * i << 8 ^ e * i << 0);
    }
}

var o = [s, n, l, r];

class a extends t {
    public var $input:Dynamic;
    public var $text:Dynamic;
    public var $display:Dynamic;
    public var _format:Dynamic;
    public var _rgbScale:Dynamic;
    public var _initialValueHexString:Dynamic;
    public var _textFocused:Bool;

    public function new(t:Dynamic, i:Dynamic, s:Dynamic, n:Dynamic) {
        super(t, i, s, "color");
        this.$input = untyped __js__("document.createElement")("input");
        this.$input.setAttribute("type", "color");
        this.$input.setAttribute("tabindex", -1);
        this.$input.setAttribute("aria-labelledby", this.$name.id);
        this.$text = untyped __js__("document.createElement")("input");
        this.$text.setAttribute("type", "text");
        this.$text.setAttribute("spellcheck", "false");
        this.$text.setAttribute("aria-labelledby", this.$name.id);
        this.$display = untyped __js__("document.createElement")("div");
        this.$display.@classList.add("display");
        this.$display.appendChild(this.$input);
        this.$widget.appendChild(this.$display);
        this.$widget.appendChild(this.$text);
        this._format = (l = this.initialValue, o.find(t -> t.match(l)));
        this._rgbScale = n;
        this._initialValueHexString = this.save();
        this._textFocused = false;
        this.$input.addEventListener("input", () -> {
            this._setValueFromHexString(this.$input.value);
        });
        this.$input.addEventListener("blur", () -> {
            this._callOnFinishChange();
        });
        this.$text.addEventListener("input", () -> {
            var t = e(this.$text.value);
            if (t != null) {
                this._setValueFromHexString(t);
            }
        });
        this.$text.addEventListener("focus", () -> {
            this._textFocused = true;
            this.$text.select();
        });
        this.$text.addEventListener("blur", () -> {
            this._textFocused = false;
            this.updateDisplay();
            this._callOnFinishChange();
        });
        this.$disable = this.$text;
        this.updateDisplay();
    }

    public function reset():Dynamic {
        this._setValueFromHexString(this._initialValueHexString);
        return this;
    }

    public function _setValueFromHexString(t:Dynamic):Void {
        if (this._format.isPrimitive) {
            var i = this._format.fromHexString(t);
            this.setValue(i);
        } else {
            this._format.fromHexString(t, this.getValue(), this._rgbScale);
            this._callOnChange();
            this.updateDisplay();
        }
    }

    public function save():Dynamic {
        return this._format.toHexString(this.getValue(), this._rgbScale);
    }

    public function load(t:Dynamic):Dynamic {
        this._setValueFromHexString(t);
        this._callOnFinishChange();
        return this;
    }

    public function updateDisplay():Dynamic {
        this.$input.value = this._format.toHexString(this.getValue(), this._rgbScale);
        if (!this._textFocused) {
            this.$text.value = this.$input.value.substring(1);
        }
        this.$display.style.backgroundColor = this.$input.value;
        return this;
    }
}

class h extends t {
    public var $button:Dynamic;

    public function new(t:Dynamic, i:Dynamic, e:Dynamic) {
        super(t, i, e, "function");
        this.$button = untyped __js__("document.createElement")("button");
        this.$button.appendChild(this.$name);
        this.$widget.appendChild(this.$button);
        this.$button.addEventListener("click", t -> {
            t.preventDefault();
            this.getValue().call(this.object);
        });
        this.$button.addEventListener("touchstart", () -> {}, { passive: true });
        this.$disable = this.$button;
    }
}

class d extends t {
    public var _initInput:Void;
    public var _min:Dynamic;
    public var _max:Dynamic;
    public var _step:Dynamic;
    public var _stepExplicit:Dynamic;
    public var _decimals:Dynamic;
    public var _hasSlider:Bool;
    public var $fill:Dynamic;
    public var _inputFocused:Bool;
    public var _hasMin:Bool;
    public var _hasMax:Bool;
    public var _getImplicitStep:Dynamic;
    public var _onUpdateMinMax:Dynamic;
    public var _normalizeMouseWheel:Dynamic;
    public var _arrowKeyMultiplier:Dynamic;
    public var _snap:Dynamic;
    public var _clamp:Dynamic;
    public var _snapClampSetValue:Dynamic;
    public var _hasScrollBar:Dynamic;

    public function new(t:Dynamic, i:Dynamic, e:Dynamic, s:Dynamic, n:Dynamic, l:Dynamic) {
        super(t, i, e, "number");
        this._initInput();
        this.min(s);
        this.max(n);
        var r = l != null;
        this.step(r ? l : this._getImplicitStep(), r);
        this.updateDisplay();
    }

    public function decimals(t:Dynamic):Dynamic {
        this._decimals = t;
        this.updateDisplay();
        return this;
    }

    public function min(t:Dynamic):Dynamic {
        this._min = t;
        this._onUpdateMinMax();
        return this;
    }

    public function max(t:Dynamic):Dynamic {
        this._max = t;
        this._onUpdateMinMax();
        return this;
    }

    public function step(t:Dynamic, i:Dynamic = true):Dynamic {
        this._step = t;
        this._stepExplicit = i;
        return this;
    }

    public function updateDisplay():Dynamic {
        var t = this.getValue();
        if (this._hasSlider) {
            var i = (t - this._min) / (this._max - this._min);
            i = Math.max(0, Math.min(i