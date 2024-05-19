package three.js.playground.libs;

import js.html.TextArea;
import js.html.Event;

class TextInput extends Input {
    public function new(innerText:String = '') {
        var dom:TextArea = cast document.createElement('textarea');
        super(dom);

        dom.innerText = innerText;

        dom.classList.add('f-scroll');

        dom.onblur = function() {
            this.dispatchEvent(new Event('blur'));
        };

        dom.onchange = function() {
            this.dispatchEvent(new Event('change'));
        };

        dom.onkeyup = function(e) {
            if (e.key == 'Enter') {
                e.target.blur();
            }
            e.stopPropagation();
            this.dispatchEvent(new Event('change'));
        };
    }
}