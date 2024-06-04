import js.html.Element;
import js.html.Window;
import js.html.MouseEvent;

class SplitscreenManager {

	public var editor:Dynamic;
	public var renderer:Dynamic;
	public var composer:Dynamic;

	public var gutter:Element;
	public var gutterMoving:Bool = false;
	public var gutterOffset:Float = 0.6;

	public function new(editor:Dynamic) {
		this.editor = editor;
		this.renderer = editor.renderer;
		this.composer = editor.composer;
	}

	public function setSplitview(value:Bool) {
		var nodeDOM:Element = this.editor.domElement;
		var rendererContainer:Element = this.renderer.domElement.parentNode;

		if (value) {
			this.addGutter(rendererContainer, nodeDOM);
		} else {
			this.removeGutter(rendererContainer, nodeDOM);
		}
	}

	public function addGutter(rendererContainer:Element, nodeDOM:Element) {
		rendererContainer.style.zIndex = 20;

		this.gutter = new Element("f-gutter");
		nodeDOM.parentNode.appendChild(this.gutter);

		var onGutterMovement = function() {
			var offset = this.gutterOffset;
			this.gutter.style.left = 100 * offset + "%";
			rendererContainer.style.left = 100 * offset + "%";
			rendererContainer.style.width = 100 * (1 - offset) + "%";
			nodeDOM.style.width = 100 * offset + "%";
		};

		this.gutter.addEventListener("mousedown", function(event:MouseEvent) {
			this.gutterMoving = true;
		});

		Window.document.addEventListener("mousemove", function(event:MouseEvent) {
			if (this.gutter && this.gutterMoving) {
				this.gutterOffset = Math.max(0, Math.min(1, event.clientX / Window.innerWidth));
				onGutterMovement();
			}
		});

		Window.document.addEventListener("mouseup", function(event:MouseEvent) {
			this.gutterMoving = false;
		});

		onGutterMovement();
	}

	public function removeGutter(rendererContainer:Element, nodeDOM:Element) {
		rendererContainer.style.zIndex = 0;

		this.gutter.remove();
		this.gutter = null;

		rendererContainer.style.left = "0%";
		rendererContainer.style.width = "100%";
		nodeDOM.style.width = "100%";
	}

}