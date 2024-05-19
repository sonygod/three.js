package three.js.playground.libs;

import js.html.Event;
import js.html.EventTarget;
import js.html.Document;
import js.html.Element;
import js.WeakMap;

class Menu extends EventTarget {
    var dom:Element;
    var listDOM:Element;
    var visible:Bool;
    var align:String;
    var subMenus:WeakMap<Dynamic, Dynamic>;
    var domButtons:WeakMap<Dynamic, Dynamic>;
    var buttons:Array<Dynamic>;
    var events:Dynamic;

    public function new(className:String) {
        super();
        dom = Document.createDivElement('f-menu');
        dom.className = className + ' bottom left hidden';
        listDOM = Document.createDivElement('f-list');
        dom.appendChild(listDOM);
        this.dom = dom;
        this.listDOM = listDOM;
        visible = false;
        align = 'bottom left';
        subMenus = new WeakMap();
        domButtons = new WeakMap();
        buttons = [];
        events = {};
    }

    public function onContext(callback:Void->Void) {
        if (!events.context) events.context = [];
        events.context.push(callback);
        return this;
    }

    public function setAlign(align:String) {
        removeDOMClass(dom, this.align);
        addDOMClass(dom, align);
        this.align = align;
        return this;
    }

    public function getAlign() {
        return align;
    }

    public function show() {
        dom.classList.remove('hidden');
        visible = true;
        dispatchEvent(new Event('show'));
        return this;
    }

    public function hide() {
        dom.classList.add('hidden');
        dispatchEvent(new Event('hide'));
        visible = false;
        return this;
    }

    public function add(button:Dynamic, submenu:Null<Dynamic> = null) {
        var liDOM = Document.createDivElement('f-item');
        if (submenu != null) {
            liDOM.classList.add('submenu');
            liDOM.appendChild(submenu.dom);
            subMenus.set(button, submenu);
            button.dom.addEventListener('mouseover', function() submenu.show());
            button.dom.addEventListener('mouseout', function() submenu.hide());
        }
        liDOM.appendChild(button.dom);
        buttons.push(button);
        domButtons.set(button, liDOM);
        listDOM.appendChild(liDOM);
        return this;
    }

    public function clear() {
        buttons = [];
        subMenus = new WeakMap();
        domButtons = new WeakMap();
        while (listDOM.firstChild != null) {
            listDOM.removeChild(listDOM.firstChild);
        }
    }
}