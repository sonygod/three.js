import haxe.ds.StringMap;

class UIElement {

	public var dom:Element;

	public function new(dom:Element) {
		this.dom = dom;
	}

	public function add(elements:UIElement):UIElement {
		for (i in 0...elements.length) {
			element = elements[i];
			if (element is UIElement) {
				this.dom.appendChild(element.dom);
			} else {
				console.error("UIElement:", element, "is not an instance of UIElement.");
			}
		}
		return this;
	}

	public function remove(elements:UIElement):UIElement {
		for (i in 0...elements.length) {
			element = elements[i];
			if (element is UIElement) {
				this.dom.removeChild(element.dom);
			} else {
				console.error("UIElement:", element, "is not an instance of UIElement.");
			}
		}
		return this;
	}

	public function clear() {
		while (this.dom.children.length > 0) {
			this.dom.removeChild(this.dom.lastChild);
		}
	}

	public function setId(id:String) {
		this.dom.id = id;
		return this;
	}

	public function getId():String {
		return this.dom.id;
	}

	public function setClass(name:String) {
		this.dom.className = name;
		return this;
	}

	public function addClass(name:String) {
		this.dom.classList.add(name);
		return this;
	}

	public function removeClass(name:String) {
		this.dom.classList.remove(name);
		return this;
	}

	public function setStyle(style:String, array:Array<String>) {
		for (i in 0...array.length) {
			this.dom.style[style] = array[i];
		}
		return this;
	}

	public function setHidden(isHidden:Bool) {
		this.dom.hidden = isHidden;
	}

	public function isHidden():Bool {
		return this.dom.hidden;
	}

	public function setDisabled(value:Bool) {
		this.dom.disabled = value;
		return this;
	}

	public function setTextContent(value:String) {
		this.dom.textContent = value;
		return this;
	}

	public function setInnerHTML(value:String) {
		this.dom.innerHTML = value;
	}

	public function getIndexOfChild(element:UIElement):Int {
		return IndexOf.apply(this.dom.children, element.dom);
	}

}

// properties

var properties:Array<String> = [
	"position", "left", "top", "right", "bottom", "width", "height",
	"display", "verticalAlign", "overflow", "color", "background", "backgroundColor", "opacity",
	"border", "borderLeft", "borderTop", "borderRight", "borderBottom", "borderColor",
	"margin", "marginLeft", "marginTop", "marginRight", "marginBottom",
	"padding", "paddingLeft", "paddingTop", "paddingRight", "paddingBottom",
	"fontSize", "fontWeight", "textAlign", "textDecoration", "textTransform", "cursor", "zIndex"
];

for (property in properties) {
	method = "set" + property.substring(0, 1).toUpperCase() + property.substring(1);
	UIElement.prototype[method] = function () {
		this.setStyle(property, arguments);
		return this;
	};
}

// events

var events:Array<String> = [
	'KeyUp', 'KeyDown', 'MouseOver', 'MouseOut', 'Click', 'DblClick', 'Change', 'Input'
];

for (event in events) {
	method = 'on' + event;
	UIElement.prototype[method] = function (callback:Void -> Void) {
		this.dom.addEventListener(event.toLowerCase(), callback.bind(this));
		return this;
	};
}

class UISpan extends UIElement {

	public function new() {
		super(haxe.Js.createDOM("span", null));
	}

}

class UIDiv extends UIElement {

	public function new() {
		super(haxe.Js.createDOM("div", null));
	}

}

class UIRow extends UIDiv {

	public function new() {
		super();
		this.dom.className = "Row";
	}

}

class UIPanel extends UIDiv {

	public function new() {
		super();
		this.dom.className = "Panel";
	}

}

class UIText extends UISpan {

	public function new(text:String) {
		super();
		this.dom.className = "Text";
		this.dom.style.cursor = "default";
		this.dom.style.display = "inline-block";
		this.setValue(text);
	}

	public function getValue():String {
		return this.dom.textContent;
	}

	public function setValue(value:String) {
		if (value != undefined) {
			this.dom.textContent = value;
		}
		return this;
	}

}

class UIInput extends UIElement {

	public function new(text:String) {
		super(haxe.Js.createDOM("input", null));
		this.dom.className = "Input";
		this.dom.style.padding = "2px";
		this.dom.style.border = "1px solid transparent";
		this.dom.setAttribute("autocomplete", "off");
		this.dom.addEventListener("keydown", function (event:Dynamic) { event.stopPropagation(); });
		this.setValue(text);
	}

	public function getValue():String {
		return this.dom.value;
	}

	public