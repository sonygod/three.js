import js.html.CanvasElement;
import js.html.DivElement;
import js.html.Document;
import js.html.Window;
import js.lib.Array;
import js.lib.Math;
import js.lib.Object;
import js.lib.String;

class DegRadHelper {
	public var obj:Dynamic;
	public var prop:String;

	public function new(obj:Dynamic, prop:String) {
		this.obj = obj;
		this.prop = prop;
	}

	public function get_value():Float {
		return Math.radToDeg(obj[prop]);
	}

	public function set_value(v:Float):Float {
		obj[prop] = Math.degToRad(v);
		return v;
	}
}

class Diagrams {

	public static function dotProduct(info:Dynamic):Void {
		var elem = info.elem;
		var div = Document.window.document.createElement('div');
		div.style.position = 'relative';
		div.style.width = '100%';
		div.style.height = '100%';
		elem.appendChild(div);

		var ctx = Document.window.document.createElement('canvas').getContext('2d');
		div.appendChild(ctx.canvas);
		var settings = {
			rotation: 0.3
		};

		var gui = new GUI({autoPlace: false});
		gui.add(new DegRadHelper(settings, 'rotation'), 'value', -180, 180).name('rotation').onChange(render);
		gui.domElement.style.position = 'absolute';
		gui.domElement.style.top = '0';
		gui.domElement.style.right = '0';
		div.appendChild(gui.domElement);

		var darkColors = {
			globe: 'green',
			camera: '#AAA',
			base: '#DDD',
			label: '#0FF'
		};
		var lightColors = {
			globe: '#0C0',
			camera: 'black',
			base: '#000',
			label: 'blue'
		};

		var darkMatcher = Window.matchMedia('(prefers-color-scheme: dark)');
		darkMatcher.addEventListener('change', render);

		function render() {
			var rotation = settings.rotation;
			var isDarkMode = darkMatcher.matches;
			var colors = isDarkMode ? darkColors : lightColors;

			var pixelRatio = Window.devicePixelRatio;
			resizeCanvasToDisplaySize(ctx.canvas, pixelRatio);

			ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
			ctx.save();
			{
				var width = ctx.canvas.width / pixelRatio;
				var height = ctx.canvas.height / pixelRatio;
				var min = Math.min(width, height);
				var half = min / 2;

				var r = half * 0.4;
				var x = r * Math.sin(-rotation);
				var y = r * Math.cos(-rotation);

				var camDX = x - 0;
				var camDY = y - (half - 40);

				var labelDir = normalize(x, y);
				var camToLabelDir = normalize(camDX, camDY);

				var dp = dot(camToLabelDir[0], camToLabelDir[1], labelDir[0], labelDir[1]);

				ctx.scale(pixelRatio, pixelRatio);
				ctx.save();
				{
					ctx.translate(width / 2, height / 2);
					ctx.beginPath();
					ctx.arc(0, 0, half * 0.4, 0, Math.PI * 2);
					ctx.fillStyle = colors.globe;
					ctx.fill();

					ctx.save();
					{
						ctx.fillStyle = colors.camera;
						ctx.translate(0, half);
						ctx.fillRect(-15, -30, 30, 30);
						ctx.beginPath();
						ctx.moveTo(0, -25);
						ctx.lineTo(-25, -50);
						ctx.lineTo(25, -50);
						ctx.closePath();
						ctx.fill();
					}
					ctx.restore();

					ctx.save();
					{
						ctx.lineWidth = 4;
						ctx.strokeStyle = colors.camera;
						ctx.fillStyle = colors.camera;
						arrow(ctx, 0, half - 40, x, y, false, true, 2);

						ctx.save();
						{
							ctx.strokeStyle = colors.label;
							ctx.fillStyle = colors.label;
							arrow(ctx, 0, 0, x, y, false, true, 2);
						}
						ctx.restore();

						ctx.lineWidth = 3;
						ctx.strokeStyle = 'black';
						ctx.fillStyle = dp < 0 ? 'white' : 'red';
						ctx.font = '20px sans-serif';
						ctx.textAlign = 'center';
						ctx.textBaseline = 'middle';
						outlineText(ctx, 'label', x, y);
					}
					ctx.restore();
				}
				ctx.restore();

				ctx.lineWidth = 3;
				ctx.font = '24px sans-serif';
				ctx.strokeStyle = 'black';
				ctx.textAlign = 'left';
				ctx.textBaseline = 'middle';
				ctx.save();
				{
					ctx.translate(width / 4, 80);
					var textColor = dp < 0 ? colors.base : 'red';
					advanceText(ctx, textColor, 'dot( ');
					ctx.save();
					{
						ctx.fillStyle = colors.camera;
						ctx.strokeStyle = colors.camera;
						ctx.rotate(Math.atan2(camDY, camDX));
						arrow(ctx, -8, 0, 8, 0, false, true, 1);
					}
					ctx.restore();
					advanceText(ctx, textColor, ' ,  ');
					ctx.save();
					{
						ctx.fillStyle = colors.label;
						ctx.strokeStyle = colors.label;
						ctx.rotate(rotation + Math.PI * 0.5);
						arrow(ctx, -8, 0, 8, 0, false, true, 1);
					}
					ctx.restore();
					advanceText(ctx, textColor, ' ) = ' + dp.toFixed(2));
				}
				ctx.restore();
			}
			ctx.restore();
		}

		render();
		Window.addEventListener('resize', render);
	}

	public static function createDiagram(base:DivElement):Void {
		var name = base.dataset.diagram;
		var info = Object.get(Diagrams, name);
		if (info == null) {
			throw "no diagram " + name;
		}
		info( { elem: base } );
	}
}

class GUI {
	public var domElement:DivElement;

	public function new(options:Dynamic) {
		domElement = Document.window.document.createElement('div');
	}

	public function add(obj:Dynamic, prop:String, min:Float, max:Float):Dynamic {
		return this;
	}

	public function name(name:String):Dynamic {
		return this;
	}

	public function onChange(callback:Dynamic):Dynamic {
		return this;
	}
}

function dot(x1:Float, y1:Float, x2:Float, y2:Float):Float {
	return x1 * x2 + y1 * y2;
}

function distance(x1:Float, y1:Float, x2:Float, y2:Float):Float {
	var dx = x1 - x2;
	var dy = y1 - y2;
	return Math.sqrt(dx * dx + dy * dy);
}

function normalize(x:Float, y:Float):Array<Float> {
	var l = distance(0, 0, x, y);
	if (l > 0.00001) {
		return [x / l, y / l];
	} else {
		return [0, 0];
	}
}

function resizeCanvasToDisplaySize(canvas:CanvasElement, pixelRatio:Float = 1):Bool {
	var width = canvas.clientWidth * pixelRatio | 0;
	var height = canvas.clientHeight * pixelRatio | 0;
	var needResize = canvas.width != width || canvas.height != height;
	if (needResize) {
		canvas.width = width;
		canvas.height = height;
	}
	return needResize;
}

function outlineText(ctx:Dynamic, msg:String, x:Float, y:Float):Void {
	ctx.strokeText(msg, x, y);
	ctx.fillText(msg, x, y);
}

function arrow(ctx:Dynamic, x1:Float, y1:Float, x2:Float, y2:Float, start:Bool, end:Bool, size:Float = 1):Void {
	var dx = x1 - x2;
	var dy = y1 - y2;
	var rot = -Math.atan2(dx, dy);
	var len = Math.sqrt(dx * dx + dy * dy);
	ctx.save();
	{
		ctx.translate(x1, y1);
		ctx.rotate(rot);
		ctx.beginPath();
		ctx.moveTo(0, 0);
		ctx.lineTo(0, -(len - 10 * size));
		ctx.stroke();
	}
	ctx.restore();
	if (start) {
		arrowHead(ctx, x1, y1, rot, size);
	}
	if (end) {
		arrowHead(ctx, x2, y2, rot + Math.PI, size);
	}
}

function arrowHead(ctx:Dynamic, x:Float, y:Float, rot:Float, size:Float):Void {
	ctx.save();
	{
		ctx.translate(x, y);
		ctx.rotate(rot);
		ctx.scale(size, size);
		ctx.translate(0, -10);
		ctx.beginPath();
		ctx.moveTo(0, 0);
		ctx.lineTo(-5, -2);
		ctx.lineTo(0, 10);
		ctx.lineTo(5, -2);
		ctx.closePath();
		ctx.fill();
	}
	ctx.restore();
}

function advanceText(ctx:Dynamic, color:String, str:String):Void {
	ctx.fillStyle = color;
	ctx.fillText(str, 0, 0);
	ctx.translate(ctx.measureText(str).width, 0);
}

function main() {
	var diagrams = {
		dotProduct: Diagrams.dotProduct
	};

	Array.forEach(Document.window.document.querySelectorAll('[data-diagram]'), function(base:DivElement) {
		Diagrams.createDiagram(base);
	});
}