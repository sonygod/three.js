package three.js.playground.libs;

import js.html.Element;
import js.html.SpanElement;
import js.html.HTMLElement;

class LabelElement extends Element {
    public var labelDOM:HTMLElement;
    public var inputsDOM:HTMLElement;
    public var spanDOM:SpanElement;
    public var iconDOM:HTMLElement;
    public var serializeLabel:Bool;

    public function new(label:String = '', align:String = '') {
        super();

        labelDOM = document.createElement('f-label');
        inputsDOM = document.createElement('f-inputs');

        spanDOM = document.createElement('span');
        this.spanDOM = spanDOM;
        this.iconDOM = null;

        labelDOM.appendChild(spanDOM);

        dom.appendChild(labelDOM);
        dom.appendChild(inputsDOM);

        serializeLabel = false;

        setLabel(label);
        setAlign(align);
    }

    public function setIcon(value:String):LabelElement {
        if (iconDOM == null) {
            iconDOM = document.createElement('i');
        }
        iconDOM.className = value;
        if (value != '') {
            labelDOM.prepend(iconDOM);
        } else {
            iconDOM.remove();
        }
        return this;
    }

    public function getIcon():String {
        return iconDOM != null ? iconDOM.className : null;
    }

    public function setAlign(align:String) {
        labelDOM.className = align;
    }

    public function setLabel(val:String) {
        spanDOM.innerText = val;
    }

    public function getLabel():String {
        return spanDOM.innerText;
    }

    override public function serialize(data:Dynamic) {
        super.serialize(data);
        if (serializeLabel) {
            var label = getLabel();
            var icon = getIcon();
            Reflect.setField(data, 'label', label);
            if (icon != '') {
                Reflect.setField(data, 'icon', icon);
            }
        }
    }

    override public function deserialize(data:Dynamic) {
        super.deserialize(data);
        if (serializeLabel) {
            setLabel(Reflect.field(data, 'label'));
            if (Reflect.hasField(data, 'icon')) {
                setIcon(Reflect.field(data, 'icon'));
            }
        }
    }
}