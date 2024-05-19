package three.js.playground.libs;

import js.html.ButtonElement;
import js.html.SpanElement;
import js.html.IElement;
import js.Browser;

class ButtonInput extends Input {
    private var spanDOM:SpanElement;
    private var iconDOM:IElement;

    public function new(innterText:String = '') {
        var dom:ButtonElement = Browser.document.createElement('button');
        spanDOM = Browser.document.createElement('span');
        dom.appendChild(spanDOM);
        iconDOM = Browser.document.createElement('i');
        dom.appendChild(iconDOM);

        super(dom);

        spanDOM.InnerText = innterText;

        dom.onmouseover = function(_) {
            this.dispatchEvent(new Event('mouseover'));
        };

        dom.onclick = dom.ontouchstart = iconDOM.onclick = iconDOM.ontouchstart = function(e) {
            e.preventDefault();
            e.stopPropagation();
            this.dispatchEvent(new Event('click'));
        };
    }

    public function setIcon(className:String):ButtonInput {
        iconDOM.className = className;
        return this;
    }

    public function getIcon():String {
        return iconDOM.className;
    }

    public function setValue(val:String):ButtonInput {
        spanDOM.InnerText = val;
        return this;
    }

    public function getValue():String {
        return spanDOM.InnerText;
    }
}