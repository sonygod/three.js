package three.js.editor.js.libs;

import js.html.DOMElement;

class UIBreak extends UIElement {

	public function new() {
		super(DOMElement.document.createElement('br'));
		cast(this.dom, js.html.HTMLBRElement).className = 'Break';
	}

}