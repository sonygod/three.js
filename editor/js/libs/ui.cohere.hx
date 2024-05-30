class UIElement {
    public var dom:Dynamic;

    public function new(dom:Dynamic) {
        this.dom = dom;
    }

    public function add(...args) {
        for (arg in args) {
            if (Type.enumIndex(arg) == UIElement) {
                this.dom.appendChild($cast(arg, UIElement).dom);
            } else {
                trace("UIElement: " + Std.string(arg) + " is not an instance of UIElement.");
            }
        }
        return this;
    }

    public function remove(...args) {
        for (arg in args) {
            if (Type.enumIndex(arg) == UIElement) {
                this.dom.removeChild($cast(arg, UIElement).dom);
            } else {
                trace("UIElement: " + Std.string(arg) + " is not an instance of UIElement.");
            }
        }
        return this;
    }

    public function clear() {
        while (this.dom.children.length > 0) {
            this.dom.removeChild(this.dom.lastChild);
        }
    }

    public function setId(id:String) {
        this.dom.id = id;
        return this;
    }

    public function getId():String {
        return this.dom.id;
    }

    public function setClass(name:String) {
        this.dom.className = name;
        return this;
    }

    public function addClass(name:String) {
        this.dom.classList.add(name);
        return this;
    }

    public function removeClass(name:String) {
        this.dom.classList.remove(name);
        return this;
    }

    public function setStyle(style:String, array:Array<String>) {
        for (i in 0...array.length) {
            this.dom.style[style] = array[i];
        }
        return this;
    }

    public function setHidden(isHidden:Bool) {
        this.dom.hidden = isHidden;
    }

    public function isHidden():Bool {
        return this.dom.hidden;
    }

    public function setDisabled(value:Bool) {
        this.dom.disabled = value;
        return this;
    }

    public function setTextContent(value:String) {
        this.dom.textContent = value;
        return this;
    }

    public function setInnerHTML(value:String) {
        this.dom.innerHTML = value;
    }

    public function getIndexOfChild(element:UIElement):Int {
        return this.dom.children.indexOf(element.dom);
    }
}

class UISpan extends UIElement {
    public function new() {
        super(document.createElement("span"));
    }
}

class UIDiv extends UIElement {
    public function new() {
        super(document.createElement("div"));
    }
}

class UIRow extends UIDiv {
    public function new() {
        super();
        this.dom.className = "Row";
    }
}

class UIPanel extends UIDiv {
    public function new() {
        super();
        this.dom.className = "Panel";
    }
}

class UIText extends UISpan {
    public function new(text:String) {
        super();
        this.dom.className = "Text";
        this.dom.style.cursor = "default";
        this.dom.style.display = "inline-block";
        this.setValue(text);
    }

    public function getValue():String {
        return this.dom.textContent;
    }

    public function setValue(value:String) {
        if (value != null) {
            this.dom.textContent = value;
        }
        return this;
    }
}

class UIInput extends UIElement {
    public function new(text:String) {
        super(document.createElement("input"));
        this.dom.className = "Input";
        this.dom.style.padding = "2px";
        this.dom.style.border = "1px solid transparent";
        this.dom.setAttribute("autocomplete", "off");
        this.dom.addEventListener("keydown", function(event) {
            event.stopPropagation();
        });
        this.setValue(text);
    }

    public function getValue():String {
        return this.dom.value;
    }

    public function setValue(value:String) {
        this.dom.value = value;
        return this;
    }
}

class UITextArea extends UIElement {
    public function new() {
        super(document.createElement("textarea"));
        this.dom.className = "TextArea";
        this.dom.style.padding = "2px";
        this.dom.spellcheck = false;
        this.dom.setAttribute("autocomplete", "off");
        this.dom.addEventListener("keydown", function(event) {
            event.stopPropagation();
            if (event.code == "Tab") {
                event.preventDefault();
                var cursor = this.selectionStart;
                this.value = this.value.substring(0, cursor) + "\t" + this.value.substring(cursor);
                this.selectionStart = cursor + 1;
                this.selectionEnd = this.selectionStart;
            }
        });
    }

    public function getValue():String {
        return this.dom.value;
    }

    public function setValue(value:String) {
        this.dom.value = value;
        return this;
    }
}

class UISelect extends UIElement {
    public function new() {
        super(document.createElement("select"));
        this.dom.className = "Select";
        this.dom.style.padding = "2px";
        this.dom.setAttribute("autocomplete", "off");
        this.dom.addEventListener("pointerdown", function(event) {
            event.stopPropagation();
        });
    }

    public function setMultiple(boolean:Bool) {
        this.dom.multiple = boolean;
        return this;
    }

    public function setOptions(options:Map<String, String>) {
        var selected = this.dom.value;
        while (this.dom.children.length > 0) {
            this.dom.removeChild(this.dom.firstChild);
        }
        for (key in options) {
            var option = document.createElement("option");
            option.value = key;
            option.innerHTML = options[key];
            this.dom.appendChild(option);
        }
        this.dom.value = selected;
        return this;
    }

    public function getValue():String {
        return this.dom.value;
    }

    public function setValue(value:String) {
        value = Std.string(value);
        if (this.dom.value != value) {
            this.dom.value = value;
        }
        return this;
    }
}

class UICheckbox extends UIElement {
    public function new(boolean:Bool) {
        super(document.createElement("input"));
        this.dom.className = "Checkbox";
        this.dom.type = "checkbox";
        this.dom.addEventListener("pointerdown", function(event) {
            // Workaround for TransformControls blocking events in Viewport.Controls checkboxes
            event.stopPropagation();
        });
        this.setValue(boolean);
    }

    public function getValue():Bool {
        return this.dom.checked;
    }

    public function setValue(value:Bool) {
        if (value != null) {
            this.dom.checked = value;
        }
        return this;
    }
}

class UIColor extends UIElement {
    public function new() {
        super(document.createElement("input"));
        this.dom.className = "Color";
        this.dom.style.width = "32px";
        this.dom.style.height = "16px";
        this.dom.style.border = "0px";
        this.dom.style.padding = "2px";
        this.dom.style.backgroundColor = "transparent";
        this.dom.setAttribute("autocomplete", "off");
        try {
            this.dom.type = "color";
            this.dom.value = "#ffffff";
        } catch (_) {}
    }

    public function getValue():String {
        return this.dom.value;
    }

    public function getHexValue():Int {
        return Std.parseInt(this.dom.value.substring(1), 16);
    }

    public function setValue(value:String) {
        this.dom.value = value;
        return this;
    }

    public function setHexValue(hex:Int) {
        this.dom.value = "#" + ("000000" + hex.toString(16)).substr(-6);
        return this;
    }
}

class UINumber extends UIElement {
    public var value:Float;
    public var min:Float;
    public var max:Float;
    public var precision:Int;
    public var step:Float;
    public var unit:String;
    public var nudge:Float;

    public function new(number:Float) {
        super(document.createElement("input"));
        this.dom.style.cursor = "ns-resize";
        this.dom.className = "Number";
        this.dom.value = "0.00";
        this.dom.setAttribute("autocomplete", "off");
        this.value = 0;
        this.min = Float.NEGATIVE_INFINITY;
        this.max = Float.POSITIVE_INFINITY;
        this.precision = 2;
        this.step = 1;
        this.unit = "";
        this.nudge = 0.01;
        this.setValue(number);
        var scope = this;
        var changeEvent = new Event("change", {"bubbles": true, "cancelable": true});
        var distance:Float;
        var onMouseDownValue:Float;
        var pointer = {"x": 0, "y": 0};
        var prevPointer = {"x": 0, "y": 0};
        function onMouseDown(event) {
            if (document.activeElement == scope.dom) return;
            event.preventDefault();
            distance = 0;
            onMouseDownValue = scope.value;
            prevPointer.x = event.clientX;
            prevPointer.y = event.clientY;
            document.addEventListener("mousemove", onMouseMove);
            document.addEventListener("mouseup", onMouseUp);
        }
        function onMouseMove(event) {
            var currentValue = scope.value;
            pointer.x = event.clientX;
            pointer.y = event.clientY;
            distance += (pointer.x - prevPointer.x) - (pointer.y - prevPointer.y);
            var value = onMouseDownValue + (distance / (event.shiftKey ? 5 : 50)) * scope.step;
            value = Math.min(scope.max, Math.max(scope.min, value));
            if (currentValue != value) {
                scope.setValue(value);
                scope.dom.dispatchEvent(changeEvent);
            }
            prevPointer.x = event.clientX;
            prevPointer.y = event.clientY;
        }
        function onMouseUp() {
            document.removeEventListener("mousemove", onMouseMove);
            document.removeEventListener("mouseup", onMouseUp);
            if (Math.abs(distance) < 2) {
                scope.dom.focus();
                scope.dom.select();
            }
        }
        function onTouchStart(event) {
            if (event.touches.length == 1) {
                distance = 0;
                onMouseDownValue = scope.value;
                prevPointer.x = event.touches[0].pageX;
                prevPointer.y = event.touches[0].pageY;
                document.addEventListener("touchmove", onTouchMove, {"passive": false});
                document.addEventListener("touchend", onTouchEnd);
            }
        }
        function onTouchMove(event) {
            event.preventDefault();
            var currentValue = scope.value;
            pointer.x = event.touches[0].pageX;
            pointer.y = event.touches[0].pageY;
            distance += (pointer.x - prevPointer.x) - (pointer.y - prevPointer.y);
            var value = onMouseDownValue + (distance / (event.shiftKey ? 5 : 50)) * scope.step;
            value = Math.min(scope.max, Math.max(scope.min, value));
            if (currentValue != value) {
                scope.setValue(value);
                scope.dom.dispatchEvent(changeEvent);
            }
            prevPointer.x = event.touches[0].pageX;
            prevPointer.y = event.touches[0].pageY;
        }
        function onTouchEnd(event) {
            if (event.touches.length == 0) {
                document.removeEventListener("touchmove", onTouchMove);
                document.removeEventListener("touchend", onTouchEnd);
            }
        }
        function onChange() {
            scope.setValue(scope.dom.value);
        }
        function onFocus() {
            scope.dom.style.backgroundColor = "";
            scope.dom.style.cursor = "";
        }
        function onBlur() {
            scope.dom.style.backgroundColor = "transparent";
            scope.dom.style.cursor = "ns-resize";
        }
        function onKeyDown(event) {
            event.stopPropagation();
            switch (event.code) {
                case "Enter":
                    scope.dom.blur();
                    break;
                case "ArrowUp":
                    event.preventDefault();
                    scope.setValue(scope.getValue() + scope.nudge);
                    scope.dom.dispatchEvent(changeEvent);
                    break;
                case "ArrowDown":
                    event.preventDefault();
                    scope.setValue(scope.getValue() - scope.nudge);
                    scope.dom.dispatchEvent(changeEvent);
                    break;
            }
        }
        onBlur();
        this.dom.addEventListener("keydown", onKeyDown);
        this.dom.addEventListener("mousedown", onMouseDown);
        this.dom.addEventListener("touchstart", onTouchStart, {"passive": false});
        this.dom.addEventListener("change", onChange);
        this.dom.addEventListener("focus", onFocus);
        this.dom.addEventListener("blur", onBlur);
    }

    public function getValue():Float {
        return this.value;
    }

    public function setValue(value:Float) {
        if (value != null) {
            value = Std.parseFloat(value);
            if (value < this.min) value = this.min;
            if (value > this.max) value = this.max;
            this.value = value;
            this.dom.value = value.toFixed(this.precision);
            if (this.unit != "") this.dom.value += " " + this.unit;
        }
        return this;
    }

    public function setPrecision(precision:Int) {
        this.precision = precision;
        return this;
    }

    public function setStep(step:Float) {
        this.step = step;
        return this;
    }

    public function setNudge(nudge:Float) {
        this.nudge = nudge;
        return this;
    }

    public function setRange(min:Float, max:Float) {
        this.min = min;
        this.max = max;
        return this;
    }

    public function setUnit(unit:String) {
        this.unit = unit;
        this.setValue(this.value);
        return this;
    }
}

class UIInteger extends UIElement {
    public var value:Int;
    public var min:Int;
    public var max:Int;
    public var step:Int;
    public var nudge:Int;

    public function new(number:Int) {
        super(document.createElement("input"));
        this.dom.style.cursor = "ns-resize";
        this.dom.className = "Number";
        this.dom.value = "0";
        this.dom.setAttribute("autocomplete", "off");
        this.value = 0;
        this.min = Int.NEGATIVE_INFINITY;
        this.max = Int.POSITIVE_INFINITY;
        this.step = 1;
        this.nudge = 1;
        this.setValue(number);
        var scope = this;
        var changeEvent = new Event("change", {"bubbles": true, "cancelable": true});
        var distance:Float;
        var onMouseDownValue:Float;
        var pointer = {"x": 0, "y": 0};
        var prevPointer = {"x": 0, "y": 0};
        function onMouseDown(event) {
            if (document.activeElement == scope.dom) return;
            event.preventDefault();
            distance = 0;
            onMouseDownValue = scope.value;
            prevPointer.x = event.clientX;
            prevPointer.y = event.clientY;
            document.addEventListener("mousemove", onMouseMove);
            document.addEventListener("mouseup", onMouseUp);
        }
        function onMouseMove(event) {
            var currentValue = scope.value;
            pointer.x = event.clientX;
            pointer.y = event.clientY;
            distance += (pointer.x - prevPointer.x) - (pointer.y - prevPointer.y);
            var value = onMouseDownValue + (distance / (event.shiftKey ? 5 : 50)) * scope.step;
            value = Math.min(scope.max, Math.max(scope.min, value)) | 0;
            if (currentValue != value) {
                scope.setValue(value);
                scope.dom.dispatchEvent(changeEvent);
            }
            prevPointer.x = event.clientX;
            prevPointer.y = event.clientY;
        }
        function onMouseUp() {
            document.removeEventListener("mousemove", onMouseMove);
            document.removeEventListener("mouseup", onMouseUp);
            if (Math.abs(distance) < 2) {
                scope.dom.focus();
                scope.dom.select();
            }
        }
        function onChange() {
            scope.setValue(scope.dom.value);
        }
        function onFocus() {
            scope.dom.style.backgroundColor = "";
            scope.dom.style.cursor = "";
        }
        function onBlur() {
            scope.dom.style.backgroundColor = "transparent";
            scope.dom.
            style.cursor = "ns-resize";
        }
        onBlur();
        this.dom.addEventListener("keydown", onKeyDown);
        this.dom.addEventListener("mousedown", onMouseDown);
        this.dom.addEventListener("change", onChange);
        this.dom.addEventListener("focus", onFocus);
        this.dom.addEventListener("blur", onBlur);
    }

    public function getValue():Int {
        return this.value;
    }

    public function setValue(value:Int) {
        if (value != null) {
            value = Std.parseInt(value);
            this.value = value;
            this.dom.value = value;
        }
        return this;
    }

    public function setStep(step:Int) {
        this.step = step;
        return this;
    }

    public function setNudge(nudge:Int) {
        this.nudge = nudge;
        return this;
    }

    public function setRange(min:Int, max:Int) {
        this.min = min;
        this.max = max;
        return this;
    }
}

class UIBreak extends UIElement {
    public function new() {
        super(document.createElement("br"));
        this.dom.className = "Break";
    }
}

class UIHorizontalRule extends UIElement {
    public function new() {
        super(document.createElement("hr"));
        this.dom.className = "HorizontalRule";
    }
}

class UIButton extends UIElement {
    public function new(value:String) {
        super(document.createElement("button"));
        this.dom.className = "Button";
        this.dom.textContent = value;
    }
}

class UIProgress extends UIElement {
    public function new(value:Float) {
        super(document.createElement("progress"));
        this.dom.value = value;
    }

    public function setValue(value:Float) {
        this.dom.value = value;
    }
}

class UITabbedPanel extends UIDiv {
    public var tabs:Array<UITab>;
    public var panels:Array<UIDiv>;
    public var tabsDiv:UIDiv;
    public var panelsDiv:UIDiv;
    public var selected:String;

    public function new() {
        super();
        this.dom.className = "TabbedPanel";
        this.tabs = [];
        this.panels = [];
        this.tabsDiv = new UIDiv();
        this.tabsDiv.setClass("Tabs");
        this.panelsDiv = new UIDiv();
        this.panelsDiv.setClass("Panels");
        this.add(this.tabsDiv);
        this.add(this.panelsDiv);
        this.selected = "";
    }

    public function select(id:String) {
        var tab:UITab;
        var panel:UIDiv;
        var scope = this;
        // Deselect current selection
        if (this.selected.length > 0) {
            tab = this.tabs.find(function(item) {
                return item.dom.id == scope.selected;
            });
            panel = this.panels.find(function(item) {
                return item.dom.id == scope.selected;
            });
            if (tab != null) {
                tab.removeClass("selected");
            }
            if (panel != null) {
                panel.setDisplay("none");
            }
        }
        tab = this.tabs.find(function(item) {
            return item.dom.id == id;
        });
        panel = this.panels.find(function(item) {
            return item.dom.id == id;
        });
        if (tab != null) {
            tab.addClass("selected");
        }
        if (panel != null) {
            panel.setDisplay("");
        }
        this.selected = id;
        return this;
    }

    public function addTab(id:String, label:String, items:UIElement) {
        var tab = new UITab(label, this);
        tab.setId(id);
        this.tabs.push(tab);
        this.tabsDiv.add(tab);
        var panel = new UIDiv();
        panel.setId(id);
        panel.add(items);
        panel.setDisplay("none");
        this.panels.push(panel);
        this.panelsDiv.add(panel);
        this.select(id);
    }
}

class UITab extends UIText {
    public var parent:UITabbedPanel;

    public function new(text:String, parent:UITabbedPanel) {
        super(text);
        this.dom.className = "Tab";
        this.parent = parent;
        var scope = this;
        this.dom.addEventListener("click", function() {
            scope.parent.select(scope.dom.id);
        });
    }
}

class UIListbox extends UIDiv {
    public var items:Array<Dynamic>;
    public var listitems:Array<ListboxItem>;
    public var selectedIndex:Int;
    public var selectedValue:String;

    public function new() {
        super();
        this.dom.className = "Listbox";
        this.dom.tabIndex = 0;
        this.items = [];
        this.listitems = [];
        this.selectedIndex = 0;
        this.selectedValue = null;
    }

    public function setItems(items:Array<Dynamic>) {
        if (Type.enumIndex(items) == Array<Dynamic>) {
            this.items = items;
        }
        this.render();
    }

    public function render() {
        while (this.listitems.length > 0) {
            var item = this.listitems.shift();
            item.dom.remove();
        }
        for (i in 0...this.items.length) {
            var item = this.items[i];
            var listitem = new ListboxItem(this);
            listitem.setId(item.id != null ? item.id : "Listbox-" + i);
            listitem.setTextContent(item.name != null ? item.name : item.type);
            this.add(listitem);
        }
    }

    public function add(...args) {
        this.listitems = this.listitems.concat(args);
        UIElement.add.apply(this, args);
    }

    public function selectIndex(index:Int) {
        if (index >= 0 && index < this.items.length) {
            this.setValue(this.listitems[index].getId());
        }
        this.selectedIndex = index;
    }

    public function getValue():String {
        return this.selectedValue;
    }

    public function setValue(value:String) {
        for (i in 0...this.listitems.length) {
            var element = this.listitems[i];
            if (element.getId() == value) {
                element.addClass("active");
            } else {
                element.removeClass("active");
            }
        }
        this.selectedValue = value;
        var changeEvent = new Event("change", {"bubbles": true, "cancelable": true});
        this.dom.dispatchEvent(changeEvent);
    }
}

class ListboxItem extends UIDiv {
    public var parent:UIListbox;

    public function new(parent:UIListbox) {
        super();
        this.dom.className = "ListboxItem";
        this.parent = parent;
        var scope = this;
        function onClick() {
            if (scope.parent != null) {
                scope.parent.setValue(scope.getId());
            }
        }
        this.dom.addEventListener("click", onClick);
    }
}

class UI {
    public static function main() {
        // Your code here
    }
}