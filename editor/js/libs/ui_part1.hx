Here is the equivalent Haxe code for the provided JavaScript code:
```
package three.js.editor.js.libs;

class UIElement {
    public var dom:js.html.DOMElement;

    public function new(dom:js.html.DOMElement) {
        this.dom = dom;
    }

    public function add(args:Array<Dynamic>):UIElement {
        for (arg in args) {
            if (Std.isOfType(arg, UIElement)) {
                dom.appendChild(cast(arg, UIElement).dom);
            } else {
                trace('UIElement:', arg, 'is not an instance of UIElement.');
            }
        }
        return this;
    }

    public function remove(args:Array<Dynamic>):UIElement {
        for (arg in args) {
            if (Std.isOfType(arg, UIElement)) {
                dom.removeChild(cast(arg, UIElement).dom);
            } else {
                trace('UIElement:', arg, 'is not an instance of UIElement.');
            }
        }
        return this;
    }

    public function clear():Void {
        while (dom.children.length > 0) {
            dom.removeChild(dom.lastChild);
        }
    }

    public function setId(id:String):UIElement {
        dom.id = id;
        return this;
    }

    public function getId():String {
        return dom.id;
    }

    public function setClass(name:String):UIElement {
        dom.className = name;
        return this;
    }

    public function addClass(name:String):UIElement {
        dom.classList.add(name);
        return this;
    }

    public function removeClass(name:String):UIElement {
        dom.classList.remove(name);
        return this;
    }

    public function setStyle(style:String, array:Array<String>):UIElement {
        for (value in array) {
            Reflect.setField(dom.style, style, value);
        }
        return this;
    }

    public function setHidden(isHidden:Bool):Void {
        dom.hidden = isHidden;
    }

    public function isHidden():Bool {
        return dom.hidden;
    }

    public function setDisabled(value:Bool):UIElement {
        dom.disabled = value;
        return this;
    }

    public function setTextContent(value:String):UIElement {
        dom.textContent = value;
        return this;
    }

    public function setInnerHTML(value:String):Void {
        dom.innerHTML = value;
    }

    public function getIndexOfChild(element:UIElement):Int {
        return Lambda.indexOf(cast dom.children, element.dom);
    }
}
```
Note that I've used the `js.html` package to access the DOM elements, and `Reflect` to set the style properties dynamically. I've also used `Std.isOfType` to check if an object is an instance of `UIElement`, and `cast` to cast the object to `UIElement` when necessary. Additionally, I've used `Lambda.indexOf` to find the index of a child element in the `dom.children` array.