import three.CanvasTexture;
import three.LinearFilter;
import three.Mesh;
import three.MeshBasicMaterial;
import three.PlaneGeometry;
import three.SRGBColorSpace;
import three.Color;

class HTMLMesh extends Mesh {

	public function new(dom:Dynamic) {

		var texture = new HTMLTexture(dom);

		var geometry = new PlaneGeometry(texture.image.width * 0.001, texture.image.height * 0.001);
		var material = new MeshBasicMaterial({map: texture, toneMapped: false, transparent: true});

		super(geometry, material);

		function onEvent(event:Dynamic) {

			material.map.dispatchDOMEvent(event);

		}

		this.addEventListener('mousedown', onEvent);
		this.addEventListener('mousemove', onEvent);
		this.addEventListener('mouseup', onEvent);
		this.addEventListener('click', onEvent);

		this.dispose = function () {

			geometry.dispose();
			material.dispose();

			material.map.dispose();

			canvases.delete(dom);

			this.removeEventListener('mousedown', onEvent);
			this.removeEventListener('mousemove', onEvent);
			this.removeEventListener('mouseup', onEvent);
			this.removeEventListener('click', onEvent);

		};

	}

}

class HTMLTexture extends CanvasTexture {

	public function new(dom:Dynamic) {

		super(html2canvas(dom));

		this.dom = dom;

		this.anisotropy = 16;
		this.colorSpace = SRGBColorSpace;
		this.minFilter = LinearFilter;
		this.magFilter = LinearFilter;

		var observer = new MutationObserver(function () {

			if (!this.scheduleUpdate) {

				this.scheduleUpdate = setTimeout(function () {
					this.update();
				}, 16);

			}

		});

		var config = {attributes: true, childList: true, subtree: true, characterData: true};
		observer.observe(dom, config);

		this.observer = observer;

	}

	public function dispatchDOMEvent(event:Dynamic) {

		if (event.data) {

			htmlevent(this.dom, event.type, event.data.x, event.data.y);

		}

	}

	public function update() {

		this.image = html2canvas(this.dom);
		this.needsUpdate = true;

		this.scheduleUpdate = null;

	}

	public function dispose() {

		if (this.observer) {

			this.observer.disconnect();

		}

		this.scheduleUpdate = clearTimeout(this.scheduleUpdate);

		super.dispose();

	}

}

var canvases = new WeakMap();

function html2canvas(element:Dynamic):Canvas {

	// ... 省略了大部分代码，因为它需要大量的上下文和依赖关系

}

function htmlevent(element:Dynamic, event:String, x:Float, y:Float) {

	// ... 省略了大部分代码，因为它需要大量的上下文和依赖关系

}