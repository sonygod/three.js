package three.js.playground.libs;

import js.html.DOMElement;
import js.html.Event;
import js.html.MouseEvent;

class ContextMenu extends Menu {
    private var _lastButtonClick:DOMElement;
    private var _onButtonClick:Event->Void;
    private var _onButtonMouseOver:Event->Void;
    private var target:DOMElement;

    public function new(?target:DOMElement) {
        super('context');

        this.events.context = [];

        _lastButtonClick = null;

        _onButtonClick = function(e:Event = null) {
            var button:DOMElement = e != null ? cast e.target : null;
            if (_lastButtonClick != null) {
                _lastButtonClick.parentElement.classList.remove('active');
            }
            _lastButtonClick = button;
            if (button != null) {
                if (subMenus.exists(button)) {
                    subMenus.get(button)._onButtonClick();
                }
                button.parentElement.classList.add('active');
            }
        };

        _onButtonMouseOver = function(e:MouseEvent) {
            var button:DOMElement = e.target;
            if (subMenus.exists(button) && _lastButtonClick != button) {
                _onButtonClick();
            }
        };

        addEventListener('context', function() {
            dispatchEventList(events.context, this);
        });

        setTarget(target);
    }

    public function openFrom(dom:DOMElement) {
        var rect = dom.getBoundingClientRect();
        return open(rect.x + (rect.width / 2), rect.y + (rect.height / 2));
    }

    public function open(x:Float = pointer.x, y:Float = pointer.y) {
        if (lastContext != null) {
            lastContext.hide();
        }
        lastContext = this;
        setPosition(x, y);
        document.body.appendChild(dom);
        return show();
    }

    public function setWidth(width:Float) {
        dom.style.width = numberToPX(width);
        return this;
    }

    public function setPosition(x:Float, y:Float) {
        var dom:DOMElement = this.dom;
        dom.style.left = numberToPX(x);
        dom.style.top = numberToPX(y);
        return this;
    }

    public function setTarget(?target:DOMElement) {
        if (target != null) {
            var onContextMenu = function(e:MouseEvent) {
                e.preventDefault();
                if (e.pointerType != 'mouse' || (e.pageX == 0 && e.pageY == 0)) return;
                dispatchEvent(new Event('context'));
                open();
            };
            this.target = target;
            target.addEventListener('contextmenu', onContextMenu, false);
        }
        return this;
    }

    public function show() {
        if (!opened) {
            dom.style.left = '';
            dom.style.transform = '';
        }
        var domRect = dom.getBoundingClientRect();
        var offsetX = Math.min(window.innerWidth - (domRect.x + domRect.width + 10), 0);
        var offsetY = Math.min(window.innerHeight - (domRect.y + domRect.height + 10), 0);

        if (opened) {
            if (offsetX < 0) offsetX = -domRect.width;
            if (offsetY < 0) offsetY = -domRect.height;
            setPosition(domRect.x + offsetX, domRect.y + offsetY);
        } else {
            // flip submenus
            if (offsetX < 0) dom.style.left = '-100%';
            if (offsetY < 0) dom.style.transform = 'translateY( calc( 32px - 100% ) )';
        }
        return super.show();
    }

    public function hide() {
        if (opened) {
            lastContext = null;
        }
        return super.hide();
    }

    public function add(button:DOMElement, ?submenu:SubMenu) {
        button.addEventListener('click', _onButtonClick);
        button.addEventListener('mouseover', _onButtonMouseOver);
        return super.add(button, submenu);
    }

    public var opened(get, never):Bool;

    private function get_opened():Bool {
        return lastContext == this;
    }
}