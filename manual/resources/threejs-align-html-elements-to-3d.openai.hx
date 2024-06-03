package three.js.manual.resources;

import js.html.CanvasElement;
import js.Browser;
import js.html.CanvasRenderingContext2D;

class ThreeJsAlignHtmlElementsTo3d {
	// ...

	function outlineText(ctx:CanvasRenderingContext2D, msg:String, x:Float, y:Float) {
		ctx.strokeText(msg, x, y);
		ctx.fillText(msg, x, y);
	}

	function arrow(ctx:CanvasRenderingContext2D, x1:Float, y1:Float, x2:Float, y2:Float, start:Bool, end:Bool, size:Int = 1) {
		// ...
	}

	function arrowHead(ctx:CanvasRenderingContext2D, x:Float, y:Float, rot:Float, size:Int) {
		// ...
	}

	class DegRadHelper {
		var obj:Dynamic;
		var prop:String;

		public function new(obj:Dynamic, prop:String) {
			this.obj = obj;
			this.prop = prop;
		}

		public var value(get, set):Float;

		function get_value():Float {
			return THREE.MathUtils.radToDeg(this.obj[this.prop]);
		}

		function set_value(v:Float):Float {
			this.obj[this.prop] = THREE.MathUtils.degToRad(v);
			return v;
		}
	}

	function dot(x1:Float, y1:Float, x2:Float, y2:Float):Float {
		return x1 * x2 + y1 * y2;
	}

	function distance(x1:Float, y1:Float, x2:Float, y2:Float):Float {
		const dx = x1 - x2;
		const dy = y1 - y2;
		return Math.sqrt(dx * dx + dy * dy);
	}

	function normalize(x:Float, y:Float):Array<Float> {
		const l = distance(0, 0, x, y);
		if (l > 0.00001) {
			return [x / l, y / l];
		} else {
			return [0, 0];
		}
	}

	function resizeCanvasToDisplaySize(canvas:CanvasElement, pixelRatio:Int = 1):Bool {
		const width = canvas.clientWidth * pixelRatio | 0;
		const height = canvas.clientHeight * pixelRatio | 0;
		const needResize = canvas.width != width || canvas.height != height;
		if (needResize) {
			canvas.width = width;
			canvas.height = height;
		}
		return needResize;
	}

	class Diagram {
		public function create(info:Dynamic) {
			const elem = info.elem;
			const div = Browser.document.createElement('div');
			div.style.position = 'relative';
			div.style.width = '100%';
			div.style.height = '100%';
			elem.appendChild(div);

			const canvas = Browser.document.createElement('canvas');
			div.appendChild(canvas);
			const ctx:CanvasRenderingContext2D = canvas.getContext('2d');
			ctx.save();

			const settings = {
				rotation: 0.3
			};

			const gui = new js.Lib.GUI({ autoPlace: false });
			gui.add(new DegRadHelper(settings, 'rotation'), 'value', -180, 180).name('rotation').onChange(render);
			gui.domElement.style.position = 'absolute';
			gui.domElement.style.top = '0';
			gui.domElement.style.right = '0';
			div.appendChild(gui.domElement);

			const darkColors = {
				globe: 'green',
				camera: '#AAA',
				base: '#DDD',
				label: '#0FF'
			};

			const lightColors = {
				globe: '#0C0',
				camera: 'black',
				base: '#000',
				label: 'blue'
			};

			const darkMatcher = Browser.matchMedia('(prefers-color-scheme: dark)');
			darkMatcher.addEventListener('change', render);

			function render() {
				// ...
			}

			render();
			Browser.window.addEventListener('resize', render);
		}
	}

	function advanceText(ctx:CanvasRenderingContext2D, color:String, str:String) {
		ctx.fillStyle = color;
		ctx.fillText(str, 0, 0);
		ctx.translate(ctx.measureText(str).width, 0);
	}

	var diagrams = {
		dotProduct: new Diagram()
	};

	Browser.document.querySelectorAll('[data-diagram]').forEach(function(base) {
		const name = base.getAttribute('data-diagram');
		const info = diagrams[name];
		if (info == null) {
			throw new js.Error('no diagram $name');
		}
		info.create({ elem: base });
	});
}