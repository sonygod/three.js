package three.js.playground.libs;

import js.html.Document;
import js.html.Element;
import js.html.Event;
import js.html.Node;
import js.html.Touch;
import js.html.TouchEvent;
import js.html.MouseEvent;

class Element extends Serializer {
    public var isElement:Bool;

    public var dom:Element;
    public var inputs:Array<Input>;
    public var links:Array<Link>;
    public var events:Dynamic;

    public var lioDOM:Element;
    public var rioDOM:Element;

    public var node:Node;
    public var style:String;
    public var color:Int;
    public var object:Dynamic;
    public var objectCallback:Dynamic;

    public var enabledInputs:Bool;
    public var visible:Bool;

    public function new(draggable:Bool = false) {
        super();

        isElement = true;

        dom = Document.createElement('f-element');
        dom.element = this;

        dom.ontouchstart = dom.onmousedown = function(e) {
            e.stopPropagation();
        };

        dom.addEventListener('mouseup', onSelect);
        dom.addEventListener('mouseover', onSelect);
        dom.addEventListener('mouseout', onSelect);
        dom.addEventListener('touchmove', onSelect);
        dom.addEventListener('touchend', onSelect);

        inputs = [];
        links = [];

        events = {
            'connect': [],
            'connectChildren': [],
            'valid': []
        };

        node = null;
        style = '';
        color = null;
        object = null;
        objectCallback = null;

        enabledInputs = true;
        visible = true;

        lioDOM = _createIO('lio');
        rioDOM = _createIO('rio');

        dom.classList.add('input-${Link.InputDirection}');

        addEventListener('connect', function() {
            dispatchEventList(events.connect, this);
        });

        addEventListener('connectChildren', function() {
            dispatchEventList(events.connectChildren, this);
        });
    }

    public function setAttribute(name:String, value:String):Element {
        dom.setAttribute(name, value);
        return this;
    }

    public function onValid(callback:Void->Void):Element {
        events.valid.push(callback);
        return this;
    }

    public function onConnect(callback:Void->Void, childrens:Bool = false):Element {
        events.connect.push(callback);
        if (childrens) events.connectChildren.push(callback);
        return this;
    }

    public function setObjectCallback(callback:Void->Void):Element {
        objectCallback = callback;
        return this;
    }

    public function setObject(value:Dynamic):Element {
        object = value;
        return this;
    }

    public function getObject(output:Dynamic = null):Dynamic {
        return objectCallback != null ? objectCallback(output) : object;
    }

    public function setVisible(value:Bool):Element {
        visible = value;
        dom.style.display = value ? '' : 'none';
        return this;
    }

    public function getVisible():Bool {
        return visible;
    }

    public function setEnabledInputs(value:Bool):Element {
        const dom:Element = this.dom;
        if (!enabledInputs) dom.classList.remove('inputs-disable');
        if (!value) dom.classList.add('inputs-disable');
        enabledInputs = value;
        return this;
    }

    public function getEnabledInputs():Bool {
        return enabledInputs;
    }

    public function setColor(color:Int):Element {
        dom.style.backgroundColor = numberToHex(color);
        color = null;
        return this;
    }

    public function getColor():Int {
        if (color == null) {
            const css = window.getComputedStyle(dom);
            color = css.getPropertyValue('background-color');
        }
        return color;
    }

    public function setStyle(style:String):Element {
        const dom:Element = this.dom;
        if (this.style != '') dom.classList.remove(this.style);
        if (style != '') dom.classList.add(style);
        this.style = style;
        color = null;
        return this;
    }

    public function setInput(length:Int):Element {
        if (Link.InputDirection == 'left') {
            return setLIO(length);
        } else {
            return setRIO(length);
        }
    }

    public function setInputColor(color:Int):Element {
        if (Link.InputDirection == 'left') {
            return setLIOColor(color);
        } else {
            return setRIOColor(color);
        }
    }

    public function setOutput(length:Int):Element {
        if (Link.InputDirection == 'left') {
            return setRIO(length);
        } else {
            return setLIO(length);
        }
    }

    public function setOutputColor(color:Int):Element {
        if (Link.InputDirection == 'left') {
            return setRIOColor(color);
        } else {
            return setLIOColor(color);
        }
    }

    public function get_inputLength():Int {
        if (Link.InputDirection == 'left') {
            return lioLength;
        } else {
            return rioLength;
        }
    }

    public function get_outputLength():Int {
        if (Link.InputDirection == 'left') {
            return rioLength;
        } else {
            return lioLength;
        }
    }

    public function setLIOColor(color:Int):Element {
        lioDOM.style.borderColor = numberToHex(color);
        return this;
    }

    public function setLIO(length:Int):Element {
        lioLength = length;
        lioDOM.style.visibility = length > 0 ? '' : 'hidden';
        if (length > 0) {
            dom.classList.add('lio');
            dom.prepend(lioDOM);
        } else {
            dom.classList.remove('lio');
            lioDOM.remove();
        }
        return this;
    }

    public function getLIOColor():String {
        return lioDOM.style.borderColor;
    }

    public function setRIOColor(color:Int):Element {
        rioDOM.style.borderColor = numberToHex(color);
        return this;
    }

    public function getRIOColor():String {
        return rioDOM.style.borderColor;
    }

    public function setRIO(length:Int):Element {
        rioLength = length;
        rioDOM.style.visibility = length > 0 ? '' : 'hidden';
        if (length > 0) {
            dom.classList.add('rio');
            dom.prepend(rioDOM);
        } else {
            dom.classList.remove('rio');
            rioDOM.remove();
        }
        return this;
    }

    public function add(input:Input):Element {
        inputs.push(input);
        input.element = this;
        inputsDOM.append(input.dom);
        return this;
    }

    public function setHeight(val:Int):Element {
        dom.style.height = numberToPX(val);
        return this;
    }

    public function getHeight():Int {
        return parseInt(dom.style.height);
    }

    public function connect(element:Element = null):Bool {
        if (disconnectDOM != null) {
            // remove the current input
            disconnectDOM.dispatchEvent(new Event('disconnect'));
        }

        if (element != null) {
            element = element.baseElement || element;

            if (dispatchEventList(events.valid, this, element, 'connect') == false) {
                return false;
            }

            const link:Link = new Link(this, element);
            links.push(link);

            if (disconnectDOM == null) {
                disconnectDOM = Document.createElement('f-disconnect');
                disconnectDOM.innerHTML = Element.icons.unlink ? '<i class="${Element.icons.unlink}"></i>' : '✖';

                dom.append(disconnectDOM);

                const onDisconnect:Void->Void = function() {
                    links = [];
                    dom.removeChild(disconnectDOM);

                    disconnectDOM.removeEventListener('mousedown', onClick, true);
                    disconnectDOM.removeEventListener('touchstart', onClick, true);
                    disconnectDOM.removeEventListener('disconnect', onDisconnect, true);

                    element.removeEventListener('connect', onConnect);
                    element.removeEventListener('connectChildren', onConnect);
                    element.removeEventListener('nodeConnect', onConnect);
                    element.removeEventListener('nodeConnectChildren', onConnect);
                    element.removeEventListener('dispose', onDispose);
                };

                const onConnect:Void->Void = function() {
                    dispatchEvent(new Event('connectChildren'));
                };

                const onDispose:Void->Void = function() {
                    connect();
                };

                const onClick:Event->Void = function(e) {
                    e.stopPropagation();
                    connect();
                };

                disconnectDOM.addEventListener('mousedown', onClick, true);
                disconnectDOM.addEventListener('touchstart', onClick, true);
                disconnectDOM.addEventListener('disconnect', onDisconnect, true);

                element.addEventListener('connect', onConnect);
                element.addEventListener('connectChildren', onConnect);
                element.addEventListener('nodeConnect', onConnect);
                element.addEventListener('nodeConnectChildren', onConnect);
                element.addEventListener('dispose', onDispose);
            }
        }

        dispatchEvent(new Event('connect'));

        return true;
    }

    public function dispose():Void {
        dispatchEvent(new Event('dispose'));
    }

    public function getInputByProperty(property:String):Input {
        for (input in inputs) {
            if (input.getProperty() == property) {
                return input;
            }
        }
        return null;
    }

    public function serialize(data:Dynamic):Void {
        const inputs:Array<Dynamic> = [];
        const properties:Array<Dynamic> = [];
        const links:Array<Dynamic> = [];

        for (input in inputs) {
            const id:String = input.toJSON(data).id;
            const property:String = input.getProperty();

            inputs.push(id);

            if (property != null) {
                properties.push({ property: property, id: id });
            }
        }

        for (link in links) {
            if (link.inputElement != null && link.outputElement != null) {
                links.push(link.outputElement.toJSON(data).id);
            }
        }

        if (inputLength > 0) data.inputLength = inputLength;
        if (outputLength > 0) data.outputLength = outputLength;

        if (inputs.length > 0) data.inputs = inputs;
        if (properties.length > 0) data.properties = properties;
        if (links.length > 0) data.links = links;

        if (style != '') data.style = style;

        data.height = getHeight();
    }

    public function deserialize(data:Dynamic):Void {
        if (data.inputLength != null) setInput(data.inputLength);
        if (data.outputLength != null) setOutput(data.outputLength);

        if (data.properties != null) {
            for ({ id: String, property: String } in data.properties) {
                data.objects[id] = getInputByProperty(property);
            }
        } else if (data.inputs != null) {
            const inputs:Array<Input> = this.inputs;

            if (inputs.length > 0) {
                var index:Int = 0;
                for (id in data.inputs) {
                    data.objects[id] = inputs[index++];
                }
            } else {
                for (id in data.inputs) {
                    add(data.objects[id]);
                }
            }
        }

        if (data.links != null) {
            for (id in data.links) {
                connect(data.objects[id]);
            }
        }

        if (data.style != null) setStyle(data.style);

        if (data.height != null) setHeight(data.height);
    }

    public function getLinkedObject(output:Dynamic = null):Dynamic {
        const linkedElement:Element = getLinkedElement();

        return linkedElement != null ? linkedElement.getObject(output) : null;
    }

    public function getLinkedElement():Element {
        const link:Link = getLink();

        return link != null ? link.outputElement : null;
    }

    public function getLink():Link {
        return links[0];
    }

    private function _createIO(type:String):Element {
        const dom:Element = this.dom;

        const ioDOM:Element = Document.createElement('f-io');
        ioDOM.style.visibility = 'hidden';
        ioDOM.className = type;

        const onConnectEvent:Event->Void = function(e) {
            e.preventDefault();
            e.stopPropagation();

            selected = null;

            const nodeDOM:Element = node.dom;

            nodeDOM.classList.add('io-connect');

            ioDOM.classList.add('connect');
            dom.classList.add('select');

            const defaultOutput:String = Link.InputDirection == 'left' ? 'lio' : 'rio';

            const link:Link = type == defaultOutput ? new Link(this) : new Link(null, this);
            const previewLink:Link = new Link(link.inputElement, link.outputElement);

            links.push(link);

            draggableDOM(e, function(data) {
                if (previewLink.outputElement != null) previewLink.outputElement.dom.classList.remove('invalid');

                if (previewLink.inputElement != null) previewLink.inputElement.dom.classList.remove('invalid');

                previewLink.inputElement = link.inputElement;
                previewLink.outputElement = link.outputElement;

                if (type == defaultOutput) {
                    previewLink.outputElement = selected;
                } else {
                    previewLink.inputElement = selected;
                }

                const isInvalid:Bool = previewLink.inputElement != null && previewLink.outputElement != null &&
                    previewLink.inputElement.inputLength > 0 && previewLink.outputElement.outputLength > 0 &&
                    dispatchEventList(previewLink.inputElement.events.valid, previewLink.inputElement, previewLink.outputElement, data.dragging ? 'dragging' : 'dragged') == false;

                if (data.dragging && isInvalid) {
                    if (type == defaultOutput) {
                        if (previewLink.outputElement != null) previewLink.outputElement.dom.classList.add('invalid');
                    } else {
                        if (previewLink.inputElement != null) previewLink.inputElement.dom.classList.add('invalid');
                    }

                    return;
                }

                if (!data.dragging) {
                    nodeDOM.classList.remove('io-connect');

                    ioDOM.classList.remove('connect');
                    dom.classList.remove('select');

                    links.splice(links.indexOf(link), 1);

                    if (selected != null && !isInvalid) {
                        link.inputElement = previewLink.inputElement;
                        link.outputElement = previewLink.outputElement;

                        // check if is an is circular link

                        if (link.outputElement.node.isCircular(link.inputElement.node)) {
                            return;
                        }

                        if (link.inputElement.inputLength > 0 && link.outputElement.outputLength > 0) {
                            link.inputElement.connect(link.outputElement);
                        }
                    }
                }
            }, { className: 'connecting' });

        ioDOM.addEventListener('mousedown', onConnectEvent, true);
        ioDOM.addEventListener('touchstart', onConnectEvent, true);

        return ioDOM;
    }
}