package three.js.editor.js.libs;

import js.html.ButtonElement;
import js.html.Document;

class UIButton extends UIElement {

	public function new(value:String) {
		super(cast Document.createElement("button"));
		
		this.dom.className = 'Button';
		this.dom.textContent = value;
	}

}