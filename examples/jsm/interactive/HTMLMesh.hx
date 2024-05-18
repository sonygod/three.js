import three.math.Color;
import three.textures.CanvasTexture;
import three.core.Geometry;
import three.core.Mesh;
import three.materials.MeshBasicMaterial;
import three.geometries.PlaneGeometry;
import three.textures.LinearFilter;
import three.core.Object3D;
import js.html.Element;
import js.events.Event;
import js.events.MouseEvent;
import js.events.MutationObserverInit;
import js.events.MutationObserver;

class HTMLMesh extends Mesh {

	private var _texture:HTMLTexture;
	private var _onEvent:Dynamic;

	public function new(dom:Element) {
		super(new PlaneGeometry(0.001 * _texture.image.width, 0.001 * _texture.image.height), new MeshBasicMaterial( { map:_texture, toneMapped:false, transparent:true } ));
		_texture = new HTMLTexture(dom);
		_onEvent = function(event:Dynamic) {
			_texture.dispatchDOMEvent(event);
		};
		addEventListener('mousedown', _onEvent);
		addEventListener('mousemove', _onEvent);
		addEventListener('mouseup', _onEvent);
		addEventListener('click', _onEvent);
	}

	public function dispose() {
		removeEventListener('mousedown', _onEvent);
		removeEventListener('mousemove', _onEvent);
		removeEventListener('mouseup', _onEvent);
		removeEventListener('click', _onEvent);
		_texture.dispose();
	}
}

class HTMLTexture extends CanvasTexture {

	private var _observer:Dynamic;

	public function new(dom:Element) {
		super(hxwebapp.DOM.toCanvas(dom));
		_observer = new MutationObserver(function() {
			if (!_scheduleUpdate) {
				_scheduleUpdate = setTimeout(_update, 16);
			}
		});
		var config:MutationObserverInit = { attributes:true, childList:true, subtree:true, characterData:true };
		_observer.observe(dom, config);
		this.anisotropy = 16;
		this.colorSpace = SRGBColorSpace;
		this.minFilter = LinearFilter;
		this.magFilter = LinearFilter;
	}

	public function dispatchDOMEvent(event:Dynamic) {
		if (event.data != null) {
			htmlevent(this.dom, event.type, event.data.x, event.data.y);
		}
	}

	public function update() {
		this.image = hxwebapp.DOM.toCanvas(this.dom);
		this.needsUpdate = true;
		_scheduleUpdate = null;
	}

	public function dispose() {
		_observer.disconnect();
		_scheduleUpdate = null;
		super.dispose();
	}
}

private var _scheduleUpdate:Float;

private function _update() {
	_texture.update();
}

private function htmlevent(element:Element, event:String, x:Int, y:Int) {
	var mouseEventInit:Dynamic = {
		clientX:(x * element.offsetWidth) + element.offsetLeft,
		clientY:(y * element.offsetHeight) + element.offsetTop,
		view:element.ownerDocument.defaultView
	};
	window.dispatchEvent(new MouseEvent(event, mouseEventInit));
	var rect:Dynamic = element.getBoundingClientRect();
	x = x * rect.width + rect.left;
	y = y * rect.height + rect.top;
	var traverse:Dynamic = function(element:Dynamic) {
		if (element.nodeType !== 3 && element.nodeType !== 8) {
			var rect:Dynamic = element.getBoundingClientRect();
			if (x > rect.left && x < rect.right && y > rect.top && y < rect.bottom) {
				element.dispatchEvent(new MouseEvent(event, mouseEventInit));
				if (element instanceof HTMLInputElement && element.type === 'range' && (event === 'mousedown' || event === 'click')) {
					var [min, max]:[Float, Float] = ['min', 'max'].map(function(property:String) {
						return Float.parseFloat(element[property]);
					});
					var width = rect.width;
					var offsetX = x - rect.x;
					var proportion = offsetX / width;
					element.value = min + (max - min) * proportion;
					element.dispatchEvent(new InputEvent('input', {bubbles:true}));
				}
			}
			for (i in 0...element.childNodes.length) {
				traverse(element.childNodes[i]);
			}
		}
	};
	traverse(element);
}