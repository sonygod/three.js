import js.html.DOMElement;
import js.html.Event;
import js.html.MouseEvent;
import js.html.TouchEvent;

class UINumber extends UIElement {
    private var dom:DOMElement;
    private var value:Float;
    private var min:Float;
    private var max:Float;
    private var precision:Int;
    private var step:Float;
    private var unit:String;
    private var nudge:Float;

    public function new(number:Float) {
        super(document.createElement('input'));
        dom = cast element;
        dom.style.cursor = 'ns-resize';
        dom.className = 'Number';
        dom.value = '0.00';
        dom.setAttribute('autocomplete', 'off');

        value = 0;
        min = -Math.POSITIVE_INFINITY;
        max = Math.POSITIVE_INFINITY;
        precision = 2;
        step = 1;
        unit = '';
        nudge = 0.01;

        setValue(number);

        var changeEvent:Event = new Event('change', { bubbles: true, cancelable: true } );

        var distance:Float = 0;
        var onMouseDownValue:Float = 0;

        var pointer:{ x:Float, y:Float } = { x: 0, y: 0 };
        var prevPointer:{ x:Float, y:Float } = { x: 0, y: 0 };

        function onMouseDown(event:MouseEvent) {
            if (document.activeElement == dom) return;
            event.preventDefault();
            distance = 0;
            onMouseDownValue = value;
            prevPointer.x = event.clientX;
            prevPointer.y = event.clientY;
            document.addEventListener('mousemove', onMouseMove);
            document.addEventListener('mouseup', onMouseUp);
        }

        function onMouseMove(event:MouseEvent) {
            var currentValue:Float = value;
            pointer.x = event.clientX;
            pointer.y = event.clientY;
            distance += (pointer.x - prevPointer.x) - (pointer.y - prevPointer.y);
            var newValue:Float = onMouseDownValue + (distance / (event.shiftKey ? 5 : 50)) * step;
            newValue = Math.min(max, Math.max(min, newValue));
            if (currentValue != newValue) {
                setValue(newValue);
                dom.dispatchEvent(changeEvent);
            }
            prevPointer.x = event.clientX;
            prevPointer.y = event.clientY;
        }

        function onMouseUp(event:MouseEvent) {
            document.removeEventListener('mousemove', onMouseMove);
            document.removeEventListener('mouseup', onMouseUp);
            if (Math.abs(distance) < 2) {
                dom.focus();
                dom.select();
            }
        }

        function onTouchStart(event:TouchEvent) {
            if (event.touches.length == 1) {
                distance = 0;
                onMouseDownValue = value;
                prevPointer.x = event.touches[0].pageX;
                prevPointer.y = event.touches[0].pageY;
                document.addEventListener('touchmove', onTouchMove, { passive: false } );
                document.addEventListener('touchend', onTouchEnd);
            }
        }

        function onTouchMove(event:TouchEvent) {
            event.preventDefault();
            var currentValue:Float = value;
            pointer.x = event.touches[0].pageX;
            pointer.y = event.touches[0].pageY;
            distance += (pointer.x - prevPointer.x) - (pointer.y - prevPointer.y);
            var newValue:Float = onMouseDownValue + (distance / (event.shiftKey ? 5 : 50)) * step;
            newValue = Math.min(max, Math.max(min, newValue));
            if (currentValue != newValue) {
                setValue(newValue);
                dom.dispatchEvent(changeEvent);
            }
            prevPointer.x = event.touches[0].pageX;
            prevPointer.y = event.touches[0].pageY;
        }

        function onTouchEnd(event:TouchEvent) {
            if (event.touches.length == 0) {
                document.removeEventListener('touchmove', onTouchMove);
                document.removeEventListener('touchend', onTouchEnd);
            }
        }

        function onChange() {
            setValue(dom.value);
        }

        function onFocus() {
            dom.style.backgroundColor = '';
            dom.style.cursor = '';
        }

        function onBlur() {
            dom.style.backgroundColor = 'transparent';
            dom.style.cursor = 'ns-resize';
        }

        function onKeyDown(event:KeyboardEvent) {
            event.stopPropagation();
            switch (event.code) {
                case 'Enter':
                    dom.blur();
                    break;
                case 'ArrowUp':
                    event.preventDefault();
                    setValue(getValue() + nudge);
                    dom.dispatchEvent(changeEvent);
                    break;
                case 'ArrowDown':
                    event.preventDefault();
                    setValue(getValue() - nudge);
                    dom.dispatchEvent(changeEvent);
                    break;
            }
        }

        onBlur();

        dom.addEventListener('keydown', onKeyDown);
        dom.addEventListener('mousedown', onMouseDown);
        dom.addEventListener('touchstart', onTouchStart, { passive: false } );
        dom.addEventListener('change', onChange);
        dom.addEventListener('focus', onFocus);
        dom.addEventListener('blur', onBlur);
    }

    public function getValue():Float {
        return value;
    }

    public function setValue(value:Float):UINumber {
        if (value != undefined) {
            value = parseFloat(value);
            if (value < min) value = min;
            if (value > max) value = max;
            this.value = value;
            dom.value = value.toFixed(precision);
            if (unit != '') dom.value += ' ' + unit;
        }
        return this;
    }

    public function setPrecision(precision:Int):UINumber {
        this.precision = precision;
        return this;
    }

    public function setStep(step:Float):UINumber {
        this.step = step;
        return this;
    }

    public function setNudge(nudge:Float):UINumber {
        this.nudge = nudge;
        return this;
    }

    public function setRange(min:Float, max:Float):UINumber {
        this.min = min;
        this.max = max;
        return this;
    }

    public function setUnit(unit:String):UINumber {
        this.unit = unit;
        setValue(value);
        return this;
    }
}