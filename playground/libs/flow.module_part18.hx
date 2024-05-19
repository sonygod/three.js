package three.js.playground.libs;

import js.Browser;
import js.html.InputElement;
import js.html.Event;

class NumberInput extends Input {
  public var min:Float;
  public var max:Float;
  public var step:Float;
  public var integer:Bool;

  public function new(value:Float = 0, min:Float = -Math.POSITIVE_INFINITY, max:Float = Math.POSITIVE_INFINITY, step:Float = 0.01) {
    super(Browser.document.createElement("input"));

    this.min = min;
    this.max = max;
    this.step = step;
    this.integer = false;

    cast(dom, InputElement).type = "text";
    dom.className = "number";
    dom.value = _getString(value);
    dom.spellcheck = false;
    dom.autocomplete = "off";

    dom.addEventListener("dragstart", (e) -> {
      e.preventDefault();
      e.stopPropagation();
    });

    dom.addEventListener("contextmenu", (e) -> {
      e.preventDefault();
      e.stopPropagation();
    });

    dom.addEventListener("focus", (e) -> {
      dom.select();
    });

    dom.addEventListener("click", (e) -> {
      dom.select();
    });

    dom.addEventListener("blur", (e) -> {
      dom.value = _getString(dom.value);
      dispatchEvent(new Event("blur"));
    });

    dom.addEventListener("change", (e) -> {
      dispatchEvent(new Event("change"));
    });

    dom.addEventListener("keydown", (e) -> {
      if (e.key.length == 1 && !/\d|\.|\-/g.test(e.key)) {
        return false;
      }
      if (e.key == "Enter") {
        e.target.blur();
      }
      e.stopPropagation();
    });

    draggableDOM(dom, (data) -> {
      var delta = data.delta;
      if (dom.readOnly == true) return;
      if (data.value == null) {
        data.value = getValue();
      }
      var diff = delta.x - delta.y;
      var value = data.value + (diff * step);
      dom.value = _getString(value.toFixed(precision));
      dispatchEvent(new Event("change"));
    });
  }

  public function setStep(step:Float):NumberInput {
    this.step = step;
    return this;
  }

  public function setRange(min:Float, max:Float, step:Float):NumberInput {
    this.min = min;
    this.max = max;
    this.step = step;
    dispatchEvent(new Event("range"));
    return setValue(getValue());
  }

  public var precision(get, never):Int;

  private function get_precision():Int {
    if (integer) return 0;
    var fract = step % 1;
    return fract != 0 ? fract.toString().split(".")[1].length : 1;
  }

  public function setValue(val:Float, dispatch:Bool = true):NumberInput {
    return super.setValue(_getString(val), dispatch);
  }

  public function getValue():Float {
    return Std.parseFloat(dom.value);
  }

  public function serialize(data:Dynamic) {
    if (min != -Math.POSITIVE_INFINITY && max != Math.POSITIVE_INFINITY) {
      data.min = min;
      data.max = max;
      data.step = step;
    }
    super.serialize(data);
  }

  public function deserialize(data:Dynamic) {
    if (data.min != null) {
      setRange(data.min, data.max, data.step);
    }
    super.deserialize(data);
  }

  private function _getString(value:Float):String {
    var num = Math.min(Math.max(value, min), max);
    if (integer) {
      return Math.floor(num) + "";
    } else {
      return num + (num % 1 == 0 ? ".0" : "");
    }
  }
}