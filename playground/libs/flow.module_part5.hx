package three.js.playground.libs;

import js.html.Element;
import js.html.Event;

class Input extends Serializer {
    private var dom:Element;
    private var element:Element;
    private var extra:Dynamic;
    private var tagColor:String;
    private var property:String;
    private var events:Map<String, Array<Event -> Void>>;

    public function new(dom:Element) {
        super();
        this.dom = dom;
        this.element = null;
        this.extra = null;
        this.tagColor = null;
        this.property = null;
        this.events = new Map<String, Array<Event -> Void>>();
        this.events.set('change', new Array<Event -> Void>());
        this.events.set('click', new Array<Event -> Void>());

        this.addEventListener('change', function(_) {
            dispatchEventList(this.events.get('change'), this);
        });

        this.addEventListener('click', function(_) {
            dispatchEventList(this.events.get('click'), this);
        });
    }

    public function setExtra(value:Dynamic):Input {
        this.extra = value;
        return this;
    }

    public function getExtra():Dynamic {
        return this.extra;
    }

    public function setProperty(name:String):Input {
        this.property = name;
        return this;
    }

    public function getProperty():String {
        return this.property;
    }

    public function setTagColor(color:String):Input {
        this.tagColor = color;
        this.dom.style.setProperty('border-left', '2px solid ${color}');
        return this;
    }

    public function getTagColor():String {
        return this.tagColor;
    }

    public function setToolTip(text:String):Input {
        var div = document.createElement('f-tooltip');
        div.innerText = text;
        this.dom.appendChild(div);
        return this;
    }

    public function onChange(callback:Event -> Void):Input {
        this.events.get('change').push(callback);
        return this;
    }

    public function onClick(callback:Event -> Void):Input {
        this.events.get('click').push(callback);
        return this;
    }

    public function setReadOnly(value:Bool):Input {
        this.getInput().readOnly = value;
        return this;
    }

    public function getReadOnly():Bool {
        return this.getInput().readOnly;
    }

    public function setValue(value:String, dispatch:Bool = true):Input {
        this.getInput().value = value;
        if (dispatch) this.dispatchEvent(new Event('change'));
        return this;
    }

    public function getValue():String {
        return this.getInput().value;
    }

    public function getInput():Element {
        return this.dom;
    }

    public function serialize(data:Dynamic) {
        data.value = this.getValue();
    }

    public function deserialize(data:Dynamic) {
        this.setValue(data.value);
    }
}