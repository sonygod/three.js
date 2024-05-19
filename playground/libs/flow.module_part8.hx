package three.js.playground.libs;

import js.html.DOMElement;
import js.html.Document;

class TitleElement extends DraggableElement {
    public var titleDOM:DOMElement;
    public var iconDOM:DOMElement;
    public var toolbarDOM:DOMElement;
    public var buttons:Array<Dynamic>;

    public function new(title:String, draggable:Bool = true) {
        super(draggable);

        var dom:DOMElement = this.dom;
        dom.classList.add('title');

        var dbClick = function() {
            this.node.canvas.focusSelected = !this.node.canvas.focusSelected;
        };

        dom.addEventListener('dblclick', dbClick);

        titleDOM = document.createElement('f-title');
        titleDOM.innerText = title;

        iconDOM = document.createElement('i');

        toolbarDOM = document.createElement('f-toolbar');

        buttons = [];

        dom.appendChild(titleDOM);
        dom.appendChild(iconDOM);
        dom.appendChild(toolbarDOM);
    }

    public function setIcon(value:String):TitleElement {
        iconDOM.className = value;
        return this;
    }

    public function getIcon():String {
        return iconDOM.className;
    }

    public function setTitle(value:String):TitleElement {
        titleDOM.innerText = value;
        return this;
    }

    public function getTitle():String {
        return titleDOM.innerText;
    }

    public function addButton(button:Dynamic):TitleElement {
        buttons.push(button);
        toolbarDOM.appendChild(button.dom);
        return this;
    }

    public function serialize(data:Dynamic):Void {
        super.serialize(data);
        var title = getTitle();
        var icon = getIcon();

        data.title = title;

        if (icon != '') {
            data.icon = icon;
        }
    }

    public function deserialize(data:Dynamic):Void {
        super.deserialize(data);
        setTitle(data.title);

        if (data.icon != null) {
            setIcon(data.icon);
        }
    }
}