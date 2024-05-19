package three.js.playground.libs;

import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.EventTarget;
import js.html.Node;

class Node extends Serializer {
    
    public var dom:Element;
    public var style:String;
    public var canvas:Dynamic;
    public var resizable:Bool;
    public var serializePriority:Int;
    public var elements:Array<Dynamic>;
    public var events:Dynamic;

    public function new() {
        super();
        dom = Document.createElement('f-node');

        var onDown = function(e:Dynamic) {
            var canvas = this.canvas;
            if (canvas != null) {
                canvas.select(this);
            }
        };
        dom.addEventListener('mousedown', onDown, true);
        dom.addEventListener('touchstart', onDown, true);

        _onConnect = function(e:Dynamic) {
            var target = e.target;
            for (element in this.elements) {
                if (element != target) {
                    element.dispatchEvent(new Event('nodeConnect'));
                }
            }
        };

        _onConnectChildren = function(e:Dynamic) {
            var target = e.target;
            for (element in this.elements) {
                if (element != target) {
                    element.dispatchEvent(new Event('nodeConnectChildren'));
                }
            }
        };

        style = '';
        canvas = null;
        resizable = false;
        serializePriority = 0;
        elements = [];
        events = {
            'focus': [],
            'blur': []
        };
        setWidth(300).setPosition(0, 0);
    }

    public function get_baseElement():Dynamic {
        return elements[0];
    }

    public function setAlign(align:Dynamic):Node {
        var dom = this.dom;
        var style = dom.style;
        style.left = '';
        style.top = '';
        style.animation = 'none';

        if (Std.is(align, String)) {
            dom.classList.add(align);
        } else if (align != null) {
            for (name in Reflect.fields(align)) {
                Reflect.setField(style, name, align[name]);
            }
        }
        return this;
    }

    public function setResizable(val:Bool):Node {
        resizable = val;
        if (resizable) {
            dom.classList.add('resizable');
        } else {
            dom.classList.remove('resizable');
        }
        updateSize();
        return this;
    }

    public function onFocus(callback:Dynamic):Node {
        events.focus.push(callback);
        return this;
    }

    public function onBlur(callback:Dynamic):Node {
        events.blur.push(callback);
        return this;
    }

    public function setStyle(style:String):Node {
        var dom = this.dom;
        if (this.style != null) dom.classList.remove(this.style);
        if (style != null) dom.classList.add(style);
        this.style = style;
        return this;
    }

    public function setPosition(x:Float, y:Float):Node {
        var dom = this.dom;
        dom.style.left = numberToPX(x);
        dom.style.top = numberToPX(y);
        return this;
    }

    public function getPosition():{ x:Float, y:Float } {
        var dom = this.dom;
        return {
            x: Std.parseInt(dom.style.left),
            y: Std.parseInt(dom.style.top)
        };
    }

    public function setWidth(val:Float):Node {
        dom.style.width = numberToPX(val);
        updateSize();
        return this;
    }

    public function getWidth():Int {
        return Std.parseInt(dom.style.width);
    }

    public function getHeight():Int {
        return dom.offsetHeight;
    }

    public function getBound():{ x:Float, y:Float, width:Float, height:Float } {
        var pos = getPosition();
        var rect = dom.getBoundingClientRect();
        return {
            x: pos.x,
            y: pos.y,
            width: rect.width,
            height: rect.height
        };
    }

    public function add(element:Dynamic):Node {
        elements.push(element);
        element.node = this;
        element.addEventListener('connect', _onConnect);
        element.addEventListener('connectChildren', _onConnectChildren);
        dom.appendChild(element.dom);
        updateSize();
        return this;
    }

    public function remove(element:Dynamic):Node {
        elements.splice(elements.indexOf(element), 1);
        element.node = null;
        element.removeEventListener('connect', _onConnect);
        element.removeEventListener('connectChildren', _onConnectChildren);
        dom.removeChild(element.dom);
        updateSize();
        return this;
    }

    public function dispose():Void {
        var canvas = this.canvas;
        if (canvas != null) canvas.remove(this);
        for (element in elements) {
            element.dispose();
        }
        dispatchEvent(new Event('dispose'));
    }

    public function isCircular(node:Dynamic):Bool {
        if (node == this) return true;
        var links = getLinks();
        for (link in links) {
            if (link.outputElement.node.isCircular(node)) {
                return true;
            }
        }
        return false;
    }

    public function getLinks():Array<Dynamic> {
        var links = [];
        for (element in elements) {
            links = links.concat(element.links);
        }
        return links;
    }

    public function getColor():Null<Dynamic> {
        return elements.length > 0 ? elements[0].getColor() : null;
    }

    public function updateSize():Void {
        for (element in elements) {
            element.dom.style.width = '';
        }
        if (resizable) {
            var element = elements[elements.length - 1];
            if (element != null) {
                element.dom.style.width = dom.style.width;
            }
        }
    }

    public function serialize(data:Dynamic):Void {
        var pos = getPosition();
        data.x = pos.x;
        data.y = pos.y;
        data.width = getWidth();
        data.elements = [for (element in elements) element.toJSON(data).id];
        data.autoResize = resizable;
        if (style != '') {
            data.style = style;
        }
    }

    public function deserialize(data:Dynamic):Void {
        setPosition(data.x, data.y);
        setWidth(data.width);
        setResizable(data.autoResize);
        if (data.style != null) {
            setStyle(data.style);
        }
        var elements = this.elements;
        if (elements.length > 0) {
            var index = 0;
            for (id in data.elements) {
                data.objects[id] = elements[index++];
            }
        } else {
            for (id in data.elements) {
                add(data.objects[id]);
            }
        }
    }
}