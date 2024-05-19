package three.js.playground.libs;

import js.html.Element;
import js.html.InputElement;
import js.Browser;

class SliderInput extends Input {
    
    private var rangeDOM:InputElement;
    private var field:NumberInput;

    public function new(value:Float = 0, min:Float = 0, max:Float = 100) {
        var dom:Element = Browser.document.createElement("f-subinputs");
        super(dom);

        value = Math.min(Math.max(value, min), max);

        var step:Float = getStep(min, max);

        rangeDOM = cast Browser.document.createElement("input");
        rangeDOM.type = "range";
        rangeDOM.min = Std.string(min);
        rangeDOM.max = Std.string(max);
        rangeDOM.step = Std.string(step);
        rangeDOM.value = Std.string(value);

        field = new NumberInput(value, min, max, step);
        field.dom.className = "range-value";
        field.onChange(function() {
            rangeDOM.value = Std.string(field.getValue());
            this.dispatchEvent(new Event("change"));
        });

        field.addEventListener("range", function() {
            rangeDOM.min = Std.string(field.min);
            rangeDOM.max = Std.string(field.max);
            rangeDOM.step = Std.string(field.step);
            rangeDOM.value = Std.string(field.getValue());
        });

        dom.appendChild(rangeDOM);
        dom.appendChild(field.dom);

        var updateRangeValue:Void->Void = function() {
            var value:Float = Std.parseFloat(rangeDOM.value);

            if (value != this.max && value + this.step >= this.max) {
                // fix not end range fraction
                rangeDOM.value = Std.string(value = this.max);
            }

            field.setValue(value);
        };

        draggableDOM(rangeDOM, function() {
            updateRangeValue();
            this.dispatchEvent(new Event("change"));
        }, { className: "" });
    }

    public function get_min():Float {
        return field.min;
    }

    public function get_max():Float {
        return field.max;
    }

    public function get_step():Float {
        return field.step;
    }

    public function setRange(min:Float, max:Float):SliderInput {
        field.setRange(min, max, getStep(min, max));
        this.dispatchEvent(new Event("range"));
        this.dispatchEvent(new Event("change"));
        return this;
    }

    public function setValue(val:Float, dispatch:Bool = true):SliderInput {
        field.setValue(val);
        rangeDOM.value = Std.string(val);
        if (dispatch) this.dispatchEvent(new Event("change"));
        return this;
    }

    public function getValue():Float {
        return field.getValue();
    }

    override public function serialize(data:Dynamic) {
        data.min = this.min;
        data.max = this.max;
        super.serialize(data);
    }

    override public function deserialize(data:Dynamic) {
        var min:Float = data.min;
        var max:Float = data.max;
        this.setRange(min, max);
        super.deserialize(data);
    }
}