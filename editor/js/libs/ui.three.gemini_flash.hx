import three.extras.loaders.KTX2Loader;
import three.extras.loaders.RGBELoader;
import three.extras.loaders.TGALoader;
import three.extras.postprocessing.Pass;
import three.math.Vector2;
import three.math.Vector3;
import three.textures.Texture;
import three.textures.DataTexture;
import three.textures.CompressedTexture;
import three.materials.MeshBasicMaterial;
import three.renderers.WebGLRenderer;
import three.scenes.Scene;
import three.core.Object3D;
import three.core.Object3D;
import three.core.Geometry;
import three.core.Mesh;
import three.core.BufferGeometry;
import three.core.BufferAttribute;

import ui.UISpan;
import ui.UIDiv;
import ui.UIRow;
import ui.UIButton;
import ui.UICheckbox;
import ui.UIText;
import ui.UINumber;
import commands.MoveObjectCommand;

class UITexture extends UISpan {

	public var texture:Texture;
	public var onChangeCallback:Dynamic->Void;

	public function new(editor:Dynamic) {
		super();

		var scope = this;

		var form = new Element('form');

		var input = new Element('input');
		input.type = 'file';
		input.addEventListener('change', function(event:Dynamic) {
			loadFile(event.target.files[0]);
		});
		form.appendChild(input);

		var canvas = new Element('canvas');
		canvas.width = 32;
		canvas.height = 16;
		canvas.style.cursor = 'pointer';
		canvas.style.marginRight = '5px';
		canvas.style.border = '1px solid #888';
		canvas.addEventListener('click', function() {
			input.click();
		});
		canvas.addEventListener('drop', function(event:Dynamic) {
			event.preventDefault();
			event.stopPropagation();
			loadFile(event.dataTransfer.files[0]);
		});
		this.dom.appendChild(canvas);

		function loadFile(file:Dynamic) {
			var extension = file.name.split('.').pop().toLowerCase();
			var reader = new FileReader();

			var hash = '${file.lastModified}_${file.size}_${file.name}';

			if (cache.has(hash)) {
				var texture = cache.get(hash);

				scope.setValue(texture);

				if (scope.onChangeCallback != null) scope.onChangeCallback(texture);

			} else if (extension == 'hdr' || extension == 'pic') {
				reader.addEventListener('load', function(event:Dynamic) {
					// assuming RGBE/Radiance HDR image format

					var loader = new RGBELoader();
					loader.load(event.target.result, function(hdrTexture:Texture) {
						hdrTexture.sourceFile = file.name;

						cache.set(hash, hdrTexture);

						scope.setValue(hdrTexture);

						if (scope.onChangeCallback != null) scope.onChangeCallback(hdrTexture);

					});

				});

				reader.readAsDataURL(file);

			} else if (extension == 'tga') {
				reader.addEventListener('load', function(event:Dynamic) {

					var loader = new TGALoader();
					loader.load(event.target.result, function(texture:Texture) {

						texture.colorSpace = Texture.SRGBColorSpace;
						texture.sourceFile = file.name;

						cache.set(hash, texture);

						scope.setValue(texture);

						if (scope.onChangeCallback != null) scope.onChangeCallback(texture);


					});

				}, false);

				reader.readAsDataURL(file);

			} else if (extension == 'ktx2') {
				reader.addEventListener('load', function(event:Dynamic) {

					var arrayBuffer = event.target.result;
					var blobURL = URL.createObjectURL(new Blob([arrayBuffer]));
					var ktx2Loader = new KTX2Loader();
					ktx2Loader.setTranscoderPath('../../examples/jsm/libs/basis/');
					editor.signals.rendererDetectKTX2Support.dispatch(ktx2Loader);

					ktx2Loader.load(blobURL, function(texture:Texture) {

						texture.colorSpace = Texture.SRGBColorSpace;
						texture.sourceFile = file.name;
						texture.needsUpdate = true;

						cache.set(hash, texture);

						scope.setValue(texture);

						if (scope.onChangeCallback != null) scope.onChangeCallback(texture);
						ktx2Loader.dispose();

					});

				});

				reader.readAsArrayBuffer(file);

			} else if (file.type.match('image.*')) {
				reader.addEventListener('load', function(event:Dynamic) {

					var image = new Element('img');
					image.addEventListener('load', function() {

						var texture = new Texture(this);
						texture.sourceFile = file.name;
						texture.needsUpdate = true;

						cache.set(hash, texture);

						scope.setValue(texture);

						if (scope.onChangeCallback != null) scope.onChangeCallback(texture);

					}, false);

					image.src = event.target.result;

				}, false);

				reader.readAsDataURL(file);

			}

			form.reset();

		}

		this.texture = null;
		this.onChangeCallback = null;

	}

	public function getValue():Texture {
		return this.texture;
	}

	public function setValue(texture:Texture) {
		var canvas = this.dom.children[0];
		var context = canvas.getContext('2d');

		// Seems like context can be null if the canvas is not visible
		if (context != null) {

			// Always clear the context before set new texture, because new texture may has transparency
			context.clearRect(0, 0, canvas.width, canvas.height);

		}

		if (texture != null) {

			var image = texture.image;

			if (image != null && image.width > 0) {

				canvas.title = texture.sourceFile;
				var scale = canvas.width / image.width;

				if (texture.isDataTexture || texture.isCompressedTexture) {

					var canvas2 = renderToCanvas(texture);
					context.drawImage(canvas2, 0, 0, image.width * scale, image.height * scale);

				} else {

					context.drawImage(image, 0, 0, image.width * scale, image.height * scale);

				}

			} else {

				canvas.title = texture.sourceFile + ' (error)';

			}

		} else {

			canvas.title = 'empty';

		}

		this.texture = texture;

	}

	public function setColorSpace(colorSpace:Int):UITexture {
		var texture = this.getValue();

		if (texture != null) {
			texture.colorSpace = colorSpace;
		}

		return this;
	}

	public function onChange(callback:Dynamic->Void):UITexture {
		this.onChangeCallback = callback;

		return this;
	}

}

class UIOutliner extends UIDiv {

	public var scene:Scene;
	public var editor:Dynamic;
	public var options:Array<UIDiv>;
	public var selectedIndex:Int;
	public var selectedValue:Dynamic;

	public function new(editor:Dynamic) {
		super();

		this.dom.className = 'Outliner';
		this.dom.tabIndex = 0;	// keyup event is ignored without setting tabIndex

		var scope = this;

		// hack
		this.scene = editor.scene;

		// Prevent native scroll behavior
		this.dom.addEventListener('keydown', function(event:Dynamic) {

			switch (event.code) {

				case 'ArrowUp':
				case 'ArrowDown':
					event.preventDefault();
					event.stopPropagation();
					break;

			}

		});

		// Keybindings to support arrow navigation
		this.dom.addEventListener('keyup', function(event:Dynamic) {

			switch (event.code) {

				case 'ArrowUp':
					scope.selectIndex(scope.selectedIndex - 1);
					break;
				case 'ArrowDown':
					scope.selectIndex(scope.selectedIndex + 1);
					break;

			}

		});

		this.editor = editor;

		this.options = [];
		this.selectedIndex = - 1;
		this.selectedValue = null;

	}

	public function selectIndex(index:Int) {
		if (index >= 0 && index < this.options.length) {
			this.setValue(this.options[index].value);

			var changeEvent = new Event('change', {bubbles: true, cancelable: true});
			this.dom.dispatchEvent(changeEvent);

		}
	}

	public function setOptions(options:Array<UIDiv>):UIOutliner {
		var scope = this;

		while (scope.dom.children.length > 0) {
			scope.dom.removeChild(scope.dom.firstChild);
		}

		function onClick() {
			scope.setValue(this.value);

			var changeEvent = new Event('change', {bubbles: true, cancelable: true});
			scope.dom.dispatchEvent(changeEvent);

		}

		// Drag

		var currentDrag:UIDiv;

		function onDrag() {
			currentDrag = this;
		}

		function onDragStart(event:Dynamic) {
			event.dataTransfer.setData('text', 'foo');
		}

		function onDragOver(event:Dynamic) {
			if (this == currentDrag) return;

			var area = event.offsetY / this.clientHeight;

			if (area < 0.25) {
				this.className = 'option dragTop';
			} else if (area > 0.75) {
				this.className = 'option dragBottom';
			} else {
				this.className = 'option drag';
			}

		}

		function onDragLeave() {
			if (this == currentDrag) return;

			this.className = 'option';
		}

		function onDrop(event:Dynamic) {
			if (this == currentDrag || currentDrag == null) return;

			this.className = 'option';

			var scene = scope.scene;
			var object = scene.getObjectById(currentDrag.value);

			var area = event.offsetY / this.clientHeight;

			if (area < 0.25) {
				var nextObject = scene.getObjectById(this.value);
				moveObject(object, nextObject.parent, nextObject);

			} else if (area > 0.75) {
				var nextObject:Object3D, parent:Object3D;

				if (this.nextSibling != null) {
					nextObject = scene.getObjectById(this.nextSibling.value);
					parent = nextObject.parent;

				} else {
					// end of list (no next object)

					nextObject = null;
					parent = scene.getObjectById(this.value).parent;

				}

				moveObject(object, parent, nextObject);

			} else {
				var parentObject = scene.getObjectById(this.value);
				moveObject(object, parentObject);

			}

		}

		function moveObject(object:Object3D, newParent:Object3D, nextObject:Object3D) {
			if (nextObject == null) nextObject = null;

			var newParentIsChild = false;

			object.traverse(function(child:Object3D) {
				if (child == newParent) newParentIsChild = true;
			});

			if (newParentIsChild) return;

			var editor = scope.editor;
			editor.execute(new MoveObjectCommand(editor, object, newParent, nextObject));

			var changeEvent = new Event('change', {bubbles: true, cancelable: true});
			scope.dom.dispatchEvent(changeEvent);

		}

		//

		scope.options = [];

		for (i in 0...options.length) {
			var div = options[i];
			div.className = 'option';
			scope.dom.appendChild(div);

			scope.options.push(div);

			div.addEventListener('click', onClick);

			if (div.draggable == true) {
				div.addEventListener('drag', onDrag);
				div.addEventListener('dragstart', onDragStart); // Firefox needs this

				div.addEventListener('dragover', onDragOver);
				div.addEventListener('dragleave', onDragLeave);
				div.addEventListener('drop', onDrop);

			}


		}

		return this;
	}

	public function getValue():Dynamic {
		return this.selectedValue;
	}

	public function setValue(value:Dynamic):UIOutliner {
		for (i in 0...this.options.length) {
			var element = this.options[i];

			if (element.value == value) {
				element.classList.add('active');

				// scroll into view

				var y = element.offsetTop - this.dom.offsetTop;
				var bottomY = y + element.offsetHeight;
				var minScroll = bottomY - this.dom.offsetHeight;

				if (this.dom.scrollTop > y) {
					this.dom.scrollTop = y;
				} else if (this.dom.scrollTop < minScroll) {
					this.dom.scrollTop = minScroll;
				}

				this.selectedIndex = i;

			} else {
				element.classList.remove('active');
			}
		}

		this.selectedValue = value;

		return this;
	}

}

class UIPoints extends UISpan {

	public var pointsList:UIDiv;
	public var pointsUI:Array<{row:UIDiv, lbl:UIText, x:UINumber, y:UINumber, z:UINumber}>;
	public var lastPointIdx:Int;
	public var onChangeCallback:Dynamic->Void;

	public function new() {
		super();

		this.dom.style.display = 'inline-block';

		this.pointsList = new UIDiv();
		this.add(this.pointsList);

		this.pointsUI = [];
		this.lastPointIdx = 0;
		this.onChangeCallback = null;

		this.update = function() { // bind lexical this
			if (this.onChangeCallback != null) {
				this.onChangeCallback();
			}
		};

	}

	public function onChange(callback:Dynamic->Void):UIPoints {
		this.onChangeCallback = callback;

		return this;
	}

	public function clear() {
		for (i in 0...this.pointsUI.length) {
			if (this.pointsUI[i] != null) {
				this.deletePointRow(i, true);
			}
		}

		this.lastPointIdx = 0;
	}

	public function deletePointRow(idx:Int, dontUpdate:Bool = false) {
		if (this.pointsUI[idx] == null) return;

		this.pointsList.remove(this.pointsUI[idx].row);

		this.pointsUI.splice(idx, 1);

		if (dontUpdate == false) {
			this.update();
		}

		this.lastPointIdx--;
	}

}

class UIPoints2 extends UIPoints {

	public function new() {
		super();

		var row = new UIRow();
		this.add(row);

		var addPointButton = new UIButton('+');
		addPointButton.onClick(function() {
			if (this.pointsUI.length == 0) {
				this.pointsList.add(this.createPointRow(0, 0));
			} else {
				var point = this.pointsUI[this.pointsUI.length - 1];

				this.pointsList.add(this.createPointRow(point.x.getValue(), point.y.getValue()));
			}

			this.update();
		});
		row.add(addPointButton);
	}

	public function getValue():Array<Vector2> {
		var points = [];

		var count = 0;

		for (i in 0...this.pointsUI.length) {
			var pointUI = this.pointsUI[i];

			if (pointUI == null) continue;

			points.push(new Vector2(pointUI.x.getValue(), pointUI.y.getValue()));
			count++;
			pointUI.lbl.setValue(count);
		}

		return points;
	}

	public function setValue(points:Array<Vector2>):UIPoints2 {
		this.clear();

		for (i in 0...points.length) {
			var point = points[i];
			this.pointsList.add(this.createPointRow(point.x, point.y));
		}

		this.update();
		return this;
	}

	public function createPointRow(x:Float, y:Float):UIDiv {
		var pointRow = new UIDiv();
		var lbl = new UIText(this.lastPointIdx + 1).setWidth('20px');
		var txtX = new UINumber(x).setWidth('30px').onChange(this.update);
		var txtY = new UINumber(y).setWidth('30px').onChange(this.update);

		var scope = this;
		var btn = new UIButton('-').onClick(function() {
			if (scope.isEditing) return;

			var idx = scope.pointsList.getIndexOfChild(pointRow);
			scope.deletePointRow(idx);
		});

		this.pointsUI.push({row: pointRow, lbl: lbl, x: txtX, y: txtY});
		this.lastPointIdx++;
		pointRow.add(lbl, txtX, txtY, btn);

		return pointRow;
	}

}

class UIPoints3 extends UIPoints {

	public function new() {
		super();

		var row = new UIRow();
		this.add(row);

		var addPointButton = new UIButton('+');
		addPointButton.onClick(function() {
			if (this.pointsUI.length == 0) {
				this.pointsList.add(this.createPointRow(0, 0, 0));
			} else {
				var point = this.pointsUI[this.pointsUI.length - 1];

				this.pointsList.add(this.createPointRow(point.x.getValue(), point.y.getValue(), point.z.getValue()));
			}

			this.update();
		});
		row.add(addPointButton);
	}

	public function getValue():Array<Vector3> {
		var points = [];
		var count = 0;

		for (i in 0...this.pointsUI.length) {
			var pointUI = this.pointsUI[i];

			if (pointUI == null) continue;

			points.push(new Vector3(pointUI.x.getValue(), pointUI.y.getValue(), pointUI.z.getValue()));
			count++;
			pointUI.lbl.setValue(count);
		}

		return points;
	}

	public function setValue(points:Array<Vector3>):UIPoints3 {
		this.clear();

		for (i in 0...points.length) {
			var point = points[i];
			this.pointsList.add(this.createPointRow(point.x, point.y, point.z));
		}

		this.update();
		return this;
	}

	public function createPointRow(x:Float, y:Float, z:Float):UIDiv {
		var pointRow = new UIDiv();
		var lbl = new UIText(this.lastPointIdx + 1).setWidth('20px');
		var txtX = new UINumber(x).setWidth('30px').onChange(this.update);
		var txtY = new UINumber(y).setWidth('30px').onChange(this.update);
		var txtZ = new UINumber(z).setWidth('30px').onChange(this.update);

		var scope = this;
		var btn = new UIButton('-').onClick(function() {
			if (scope.isEditing) return;

			var idx = scope.pointsList.getIndexOfChild(pointRow);
			scope.deletePointRow(idx);
		});

		this.pointsUI.push({row: pointRow, lbl: lbl, x: txtX, y: txtY, z: txtZ});
		this.lastPointIdx++;
		pointRow.add(lbl, txtX, txtY, txtZ, btn);

		return pointRow;
	}

}

class UIBoolean extends UISpan {

	public var checkbox:UICheckbox;
	public var text:UIText;

	public function new(boolean:Bool, text:String) {
		super();

		this.setMarginRight('4px');

		this.checkbox = new UICheckbox(boolean);
		this.text = new UIText(text).setMarginLeft('3px');

		this.add(this.checkbox);
		this.add(this.text);
	}

	public function getValue():Bool {
		return this.checkbox.getValue();
	}

	public function setValue(value:Bool):UIBoolean {
		return this.checkbox.setValue(value);
	}

}

var renderer:WebGLRenderer;
var fsQuad:Pass;

function renderToCanvas(texture:Texture):Element {
	if (renderer == null) {
		renderer = new WebGLRenderer();
	}

	if (fsQuad == null) {
		fsQuad = new Pass(new MeshBasicMaterial());
	}

	var image = texture.image;

	renderer.setSize(image.width, image.height, false);

	fsQuad.material.map = texture;
	fsQuad.render(renderer);

	return renderer.domElement;
}

var cache = new Map();

class Event {
	public function new(type:String, init:Dynamic) {
		// Empty
	}
}

class Blob {
	public function new(parts:Array<Dynamic>) {
		// Empty
	}
}

class URL {
	public static function createObjectURL(blob:Blob):String {
		return '';
	}
}

class FileReader {
	public function new() {
		// Empty
	}

	public function addEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false) {
		// Empty
	}

	public function readAsDataURL(file:Dynamic) {
		// Empty
	}

	public function readAsArrayBuffer(file:Dynamic) {
		// Empty
	}
}

class Element {
	public function new(type:String) {
		// Empty
	}

	public function appendChild(child:Element) {
		// Empty
	}

	public function removeChild(child:Element) {
		// Empty
	}

	public function get children():Array<Element> {
		return [];
	}

	public function get firstChild():Element {
		return null;
	}

	public function get nextSibling():Element {
		return null;
	}

	public function get clientHeight():Int {
		return 0;
	}

	public function get offsetTop():Int {
		return 0;
	}

	public function get offsetHeight():Int {
		return 0;
	}

	public function get value():Dynamic {
		return null;
	}

	public function get style():Dynamic {
		return null;
	}

	public function set draggable(value:Bool) {
		// Empty
	}

	public function get draggable():Bool {
		return false;
	}

	public function set className(value:String) {
		// Empty
	}

	public function get className():String {
		return '';
	}

	public function addEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false) {
		// Empty
	}

	public function getContext(type:String):Dynamic {
		return null;
	}

	public function get files():Array<Dynamic> {
		return [];
	}

	public function get target():Dynamic {
		return null;
	}

	public function set title(value:String) {
		// Empty
	}

	public function set src(value:String) {
		// Empty
	}

	public function click() {
		// Empty
	}

	public function clearRect(x:Int, y:Int, width:Int, height:Int) {
		// Empty
	}

	public function drawImage(image:Dynamic, x:Int, y:Int, width:Int, height:Int) {
		// Empty
	}

	public function reset() {
		// Empty
	}

	public function getIndexOfChild(child:UIDiv):Int {
		return 0;
	}

	public function set scrollTop(value:Int) {
		// Empty
	}

	public function get scrollTop():Int {
		return 0;
	}
}

class Map {
	public function new() {
		// Empty
	}

	public function has(key:String):Bool {
		return false;
	}

	public function get(key:String):Dynamic {
		return null;
	}

	public function set(key:String, value:Dynamic) {
		// Empty
	}
}

class Dynamic {
	public function new() {
		// Empty
	}

	public function dispose() {
		// Empty
	}

	public function dispatch(arg:Dynamic) {
		// Empty
	}

	public function setTranscoderPath(arg:String) {
		// Empty
	}

	public function load(arg:String, onload:Dynamic->Void) {
		// Empty
	}

	public function get indexOfChild():Int {
		return 0;
	}

	public function get getObjectById():Object3D {
		return null;
	}

	public function get isDataTexture():Bool {
		return false;
	}

	public function get isCompressedTexture():Bool {
		return false;
	}

	public function get sourceFile():String {
		return '';
	}

	public function get image():Dynamic {
		return null;
	}

	public function get width():Int {
		return 0;
	}

	public function get height():Int {
		return 0;
	}

	public function get needsUpdate():Bool {
		return false;
	}

	public function set needsUpdate(value:Bool) {
		// Empty
	}

	public function get colorSpace():Int {
		return 0;
	}

	public function set colorSpace(value:Int) {
		// Empty
	}

	public function get parent():Object3D {
		return null;
	}

	public function get scene():Scene {
		return null;
	}

	public function get isEditing():Bool {
		return false;
	}

	public function execute(arg:MoveObjectCommand) {
		// Empty
	}

	public function add(arg:UIDiv) {
		// Empty
	}

	public function remove(arg:UIDiv) {
		// Empty
	}

	public function setWidth(arg:String) {
		// Empty
	}

	public function setMarginLeft(arg:String) {
		// Empty
	}

	public function setMarginRight(arg:String) {
		// Empty
	}

	public function onClick(arg:Dynamic->Void) {
		// Empty
	}

	public function setValue(arg:Dynamic) {
		// Empty
	}

	public function getValue():Dynamic {
		return null;
	}

	public function traverse(arg:Object3D->Void) {
		// Empty
	}

	public function get dom():Element {
		return null;
	}
}

class String {
	public function split(delimiter:String):Array<String> {
		return [];
	}

	public function toLowerCase():String {
		return '';
	}

	public function match(pattern:String):Array<String> {
		return [];
	}
}

class Bool {
	public function new() {
		// Empty
	}
}

class Int {
	public function new() {
		// Empty
	}
}

class Float {
	public function new() {
		// Empty
	}
}

class Array<T> {
	public function new() {
		// Empty
	}

	public function length(arg:Int):T {
		return null;
	}

	public function push(arg:T) {
		// Empty
	}

	public function splice(arg:Int, arg2:Int) {
		// Empty
	}
}

export { UITexture, UIOutliner, UIPoints, UIPoints2, UIPoints3, UIBoolean };