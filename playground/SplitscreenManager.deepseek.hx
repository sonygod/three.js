class SplitscreenManager {

	var editor:Dynamic;
	var renderer:Dynamic;
	var composer:Dynamic;
	var gutter:Dynamic;
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
		var nodeDOM = this.editor.domElement;
		var rendererContainer = this.renderer.domElement.parentNode;
		if (value) {
			this.addGutter(rendererContainer, nodeDOM);
		} else {
			this.removeGutter(rendererContainer, nodeDOM);
		}
	}

	public function addGutter(rendererContainer:Dynamic, nodeDOM:Dynamic) {
		rendererContainer.style['z-index'] = 20;
		this.gutter = js.Browser.document.createElement('f-gutter');
		nodeDOM.parentNode.appendChild(this.gutter);
		var onGutterMovement = function() {
			var offset = this.gutterOffset;
			this.gutter.style['left'] = 100 * offset + '%';
			rendererContainer.style['left'] = 100 * offset + '%';
			rendererContainer.style['width'] = 100 * (1 - offset) + '%';
			nodeDOM.style['width'] = 100 * offset + '%';
		};
		this.gutter.addEventListener('mousedown', function() {
			this.gutterMoving = true;
		});
		js.Browser.document.addEventListener('mousemove', function(event:Dynamic) {
			if (this.gutter && this.gutterMoving) {
				this.gutterOffset = Math.max(0, Math.min(1, event.clientX / js.Browser.window.innerWidth));
				onGutterMovement();
			}
		});
		js.Browser.document.addEventListener('mouseup', function() {
			this.gutterMoving = false;
		});
		onGutterMovement();
	}

	public function removeGutter(rendererContainer:Dynamic, nodeDOM:Dynamic) {
		rendererContainer.style['z-index'] = 0;
		this.gutter.remove();
		this.gutter = null;
		rendererContainer.style['left'] = '0%';
		rendererContainer.style['width'] = '100%';
		nodeDOM.style['width'] = '100%';
	}
}