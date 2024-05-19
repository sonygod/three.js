package three.js.editor.js.libs;

import js.html.Element;
import js.html.Event;
import js.html.MouseEvent;
import js.html.KeyboardEvent;

class UIInteger extends UIElement {
    
    public var value:Int;
    public var min:Int;
    public var max:Int;
    public var step:Int;
    public var nudge:Int;

    public function new(number:Int) {
        super(Element.createInputElement("input"));
        
        dom.style.cursor = "ns-resize";
        dom.className = "Number";
        dom.value = "0";
        dom.autocomplete = "off";
        
        value = 0;
        min = -Math.POSITIVE_INFINITY;
        max = Math.POSITIVE_INFINITY;
        step = 1;
        nudge = 1;
        
        setValue(number);
        
        var scope = this;
        
        var changeEvent = new Event("change", { bubbles: true, cancelable: true });
        
        var distance = 0;
        var onMouseDownValue = 0;
        
        var pointer = { x: 0, y: 0 };
        var prevPointer = { x: 0, y: 0 };
        
        function onMouseDown(event:MouseEvent) {
            if (document.activeElement == dom) return;
            
            event.preventDefault();
            
            distance = 0;
            
            onMouseDownValue = value;
            
            prevPointer.x = event.clientX;
            prevPointer.y = event.clientY;
            
            document.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            document.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
        }
        
        function onMouseMove(event:MouseEvent) {
            var currentValue = value;
            
            pointer.x = event.clientX;
            pointer.y = event.clientY;
            
            distance += (pointer.x - prevPointer.x) - (pointer.y - prevPointer.y);
            
            var newValue = onMouseDownValue + (distance / (event.shiftKey ? 5 : 50)) * step;
            newValue = Math.min(max, Math.max(min, Math.floor(newValue)));
            
            if (currentValue != newValue) {
                setValue(newValue);
                dom.dispatchEvent(changeEvent);
            }
            
            prevPointer.x = event.clientX;
            prevPointer.y = event.clientY;
        }
        
        function onMouseUp(event:MouseEvent) {
            document.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            document.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            
            if (Math.abs(distance) < 2) {
                dom.focus();
                dom.select();
            }
        }
        
        function onChange(event:Event) {
            setValue(dom.value);
        }
        
        function onFocus(event:Event) {
            dom.style.backgroundColor = "";
            dom.style.cursor = "";
        }
        
        function onBlur(event:Event) {
            dom.style.backgroundColor = "transparent";
            dom.style.cursor = "ns-resize";
        }
        
        function onKeyDown(event:KeyboardEvent) {
            event.stopPropagation();
            
            switch (event.code) {
                case "Enter":
                    dom.blur();
                    break;
                case "ArrowUp":
                    event.preventDefault();
                    setValue(getValue() + nudge);
                    dom.dispatchEvent(changeEvent);
                    break;
                case "ArrowDown":
                    event.preventDefault();
                    setValue(getValue() - nudge);
                    dom.dispatchEvent(changeEvent);
                    break;
            }
        }
        
        onBlur(null);
        
        dom.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
        dom.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        dom.addEventListener(Event.CHANGE, onChange);
        dom.addEventListener(FocusEvent.FOCUS, onFocus);
        dom.addEventListener(FocusEvent.BLUR, onBlur);
    }
    
    public function getValue():Int {
        return value;
    }
    
    public function setValue(value:Int):UIInteger {
        if (value != null) {
            value = Std.parseInt(value);
            this.value = value;
            dom.value = Std.string(value);
        }
        return this;
    }
    
    public function setStep(step:Int):UIInteger {
        this.step = Std.parseInt(step);
        return this;
    }
    
    public function setNudge(nudge:Int):UIInteger {
        this.nudge = nudge;
        return this;
    }
    
    public function setRange(min:Int, max:Int):UIInteger {
        this.min = min;
        this.max = max;
        return this;
    }
}