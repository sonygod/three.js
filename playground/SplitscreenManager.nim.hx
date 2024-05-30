import js.html.Element;
import js.html.Node;
import js.html.Window;
import js.html.Event;
import js.html.MouseEvent;
import js.html.Style;

class SplitscreenManager {

	var editor:Dynamic;
	var renderer:Dynamic;
	var composer:Dynamic;

	var gutter:Element;
	var gutterMoving:Bool;
	var gutterOffset:Float;

	public function new(editor:Dynamic) {

		this.editor = editor;
		this.renderer = editor.renderer;
		this.composer = editor.composer;

		this.gutter = null;
		this.gutterMoving = false;
		this.gutterOffset = 0.6;

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

	private function addGutter(rendererContainer:Element, nodeDOM:Element) {

		rendererContainer.style.setProperty("z-index", "20");

		this.gutter = Element.create("f-gutter");

		nodeDOM.parentNode.appendChild(this.gutter);

		var onGutterMovement = function() {

			var offset:Float = this.gutterOffset;

			this.gutter.style.setProperty("left", (100 * offset) + "%");
			rendererContainer.style.setProperty("left", (100 * offset) + "%");
			rendererContainer.style.setProperty("width", (100 * (1 - offset)) + "%");
			nodeDOM.style.setProperty("width", (100 * offset) + "%");

		};

		this.gutter.addEventListener(MouseEvent.MOUSE_DOWN, function(event:Event) {

			this.gutterMoving = true;

		});

		Window.current.addEventListener(MouseEvent.MOUSE_MOVE, function(event:MouseEvent) {

			if (this.gutter != null && this.gutterMoving) {

				this.gutterOffset = Math.max(0, Math.min(1, event.clientX / Window.current.innerWidth));
				onGutterMovement();

			}

		});

		Window.current.addEventListener(MouseEvent.MOUSE_UP, function(event:Event) {

			this.gutterMoving = false;

		});

		onGutterMovement();

	}

	private function removeGutter(rendererContainer:Element, nodeDOM:Element) {

		rendererContainer.style.setProperty("z-index", "0");

		this.gutter.remove();
		this.gutter = null;

		rendererContainer.style.setProperty("left", "0%");
		rendererContainer.style.setProperty("width", "100%");
		nodeDOM.style.setProperty("width", "100%");

	}

}