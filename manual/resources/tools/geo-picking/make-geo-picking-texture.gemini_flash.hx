import haxe.io.Bytes;
import js.html.CanvasElement;
import js.html.Document;
import js.html.ImageData;
import js.html.Window;
import js.lib.Array;
import js.lib.Promise;
import js.lib.String;
import js.lib.TypeError;
import js.lib.console;
import js.lib.setTimeout;
import js.node.fs;

class CountryInfo {
	public var name:String;
	public var min:Array<Float>;
	public var max:Array<Float>;
	public var area:Float;
	public var lat:Float;
	public var lon:Float;
	public var population:Dynamic;

	public function new(name:String) {
		this.name = name;
	}
}

class CountryData {
	public var color:Array<Int>;
	public var id:Int;

	public function new(color:Array<Int>, id:Int) {
		this.color = color;
		this.id = id;
	}
}

class GeoHandler {
	public function new() {}

	public function handle(ctx:js.html.CanvasRenderingContext2D, geo:Dynamic, drawFn:js.html.CanvasRenderingContext2D->Void):Void {
		throw new TypeError("Can't handle geometry type: " + geo.type);
	}
}

class MultiPolygonHandler extends GeoHandler {
	public function new() : Void {
		super();
	}

	override public function handle(ctx:js.html.CanvasRenderingContext2D, geo:Dynamic, drawFn:js.html.CanvasRenderingContext2D->Void):Void {
		var coordinates = cast(geo.coordinates, Array<Array<Array<Float>>>);
		for (polygon in coordinates) {
			ctx.beginPath();
			for (ring in polygon) {
				for (p in ring) {
					minMax(p);
				}
				ctx.moveTo(ring[0][0], ring[0][1]);
				for (i in 0...ring.length) {
					ctx.lineTo(ring[i][0], ring[i][1]);
				}
				ctx.closePath();
			}
			drawFn(ctx);
		}
	}
}

class PolygonHandler extends GeoHandler {
	public function new() : Void {
		super();
	}

	override public function handle(ctx:js.html.CanvasRenderingContext2D, geo:Dynamic, drawFn:js.html.CanvasRenderingContext2D->Void):Void {
		var coordinates = cast(geo.coordinates, Array<Array<Array<Float>>>);
		ctx.beginPath();
		for (ring in coordinates) {
			for (p in ring) {
				minMax(p);
			}
			ctx.moveTo(ring[0][0], ring[0][1]);
			for (i in 0...ring.length) {
				ctx.lineTo(ring[i][0], ring[i][1]);
			}
			ctx.closePath();
		}
		drawFn(ctx);
	}
}

class ShapefileReader {
	private var _file:Bytes;

	public function new(file:Bytes) {
		this._file = file;
	}

	public function read():Promise<ShapefileRecord> {
		return new Promise(function(resolve, reject) {
			resolve(null);
		});
	}
}

class ShapefileRecord {
	public var done:Bool;
	public var value:Dynamic;

	public function new(done:Bool, value:Dynamic) {
		this.done = done;
		this.value = value;
	}
}

class Shapefile {
	public static function open(path:String):Promise<ShapefileReader> {
		return new Promise(function(resolve, reject) {
			var file = fs.readFileSync(path);
			resolve(new ShapefileReader(file));
		});
	}
}

var size = 4096;
var pickCtx:js.html.CanvasRenderingContext2D = cast(Document.window.document.querySelector('#pick').getContext('2d'), js.html.CanvasRenderingContext2D);
pickCtx.canvas.width = size;
pickCtx.canvas.height = size;
var outlineCtx:js.html.CanvasRenderingContext2D = cast(Document.window.document.querySelector('#outline').getContext('2d'), js.html.CanvasRenderingContext2D);
outlineCtx.canvas.width = size;
outlineCtx.canvas.height = size;
outlineCtx.translate(outlineCtx.canvas.width / 2, outlineCtx.canvas.height / 2);
outlineCtx.scale(outlineCtx.canvas.width / 360, outlineCtx.canvas.height / -180);
outlineCtx.strokeStyle = '#FFF';
var workCtx:js.html.CanvasRenderingContext2D = cast(Document.window.document.createElement('canvas').getContext('2d'), js.html.CanvasRenderingContext2D);
workCtx.canvas.width = size;
workCtx.canvas.height = size;
var id = 1;
var countryData:Map<String, CountryData> = new Map();
var countriesById:Array<CountryInfo> = [];
var min:Array<Float> = [10000, 10000];
var max:Array<Float> = [-10000, -10000];
var geoHandlers:Map<String, GeoHandler> = new Map();
geoHandlers.set('MultiPolygon', new MultiPolygonHandler());
geoHandlers.set('Polygon', new PolygonHandler());

function resetMinMax() {
	min = [10000, 10000];
	max = [-10000, -10000];
}

function minMax(p:Array<Float>) {
	min[0] = Math.min(min[0], p[0]);
	min[1] = Math.min(min[1], p[1]);
	max[0] = Math.max(max[0], p[0]);
	max[1] = Math.max(max[1], p[1]);
}

function fill(ctx:js.html.CanvasRenderingContext2D) {
	ctx.fill('evenodd');
}

// function stroke(ctx:js.html.CanvasRenderingContext2D) {
//   ctx.save();
//   ctx.setTransform(1, 0, 0, 1, 0, 0);
//   ctx.stroke();
//   ctx.restore();
// }

function draw(area:Dynamic) {
	var properties = cast(area.properties, Dynamic);
	var geometry = cast(area.geometry, Dynamic);
	var name = cast(properties.NAME, String);
	console.log(name);

	if (!countryData.exists(name)) {
		var r = (id >> 0) & 0xFF;
		var g = (id >> 8) & 0xFF;
		var b = (id >> 16) & 0xFF;
		countryData.set(name, new CountryData([r, g, b], id++));
		countriesById.push(new CountryInfo(name));
	}

	var countryInfo = countriesById[countryData.get(name).id - 1];

	var handler = geoHandlers.get(geometry.type);
	if (handler == null) {
		throw new TypeError("unknown geometry type.");
	}

	resetMinMax();

	workCtx.save();
	workCtx.clearRect(0, 0, workCtx.canvas.width, workCtx.canvas.height);
	workCtx.fillStyle = '#000';
	workCtx.strokeStyle = '#000';
	workCtx.translate(workCtx.canvas.width / 2, workCtx.canvas.height / 2);
	workCtx.scale(workCtx.canvas.width / 360, workCtx.canvas.height / -180);

	handler.handle(workCtx, geometry, fill);

	workCtx.restore();

	countryInfo.min = min;
	countryInfo.max = max;
	countryInfo.area = cast(properties.AREA, Float);
	countryInfo.lat = cast(properties.LAT, Float);
	countryInfo.lon = cast(properties.LON, Float);
	countryInfo.population = {
		'2005': cast(properties.POP2005, Float)
	};

	//
	var left = Math.floor((min[0] + 180) * workCtx.canvas.width / 360);
	var bottom = Math.floor((-min[1] + 90) * workCtx.canvas.height / 180);
	var right = Math.ceil((max[0] + 180) * workCtx.canvas.width / 360);
	var top = Math.ceil((-max[1] + 90) * workCtx.canvas.height / 180);
	var width = right - left + 1;
	var height = Math.max(1, bottom - top + 1);

	var color = countryData.get(name).color;
	var src = workCtx.getImageData(left, top, width, height);
	for (y in 0...height) {
		for (x in 0...width) {
			var off = (y * width + x) * 4;
			if (src.data[off + 3]) {
				src.data[off + 0] = color[0];
				src.data[off + 1] = color[1];
				src.data[off + 2] = color[2];
				src.data[off + 3] = 255;
			}
		}
	}

	workCtx.putImageData(src, left, top);
	pickCtx.drawImage(workCtx.canvas, 0, 0);

	//    handler(outlineCtx, geometry, stroke);
}

function wait(ms:Int = 0):Promise<Void> {
	return new Promise(function(resolve) {
		setTimeout(resolve, ms);
	});
}

function main() {
	Shapefile.open('TM_WORLD_BORDERS-0.3.shp').then(function(source:ShapefileReader) {
		var areas:Array<Dynamic> = [];
		var i = 0;
		function readNext() {
			source.read().then(function(record:ShapefileRecord) {
				if (record.done) {
					console.log(JSON.stringify(areas));
					console.log('min', min);
					console.log('max', max);
					console.log(JSON.stringify(countriesById, null, 2));

					var pick = pickCtx.getImageData(0, 0, pickCtx.canvas.width, pickCtx.canvas.height);
					var outline = outlineCtx.getImageData(0, 0, outlineCtx.canvas.width, outlineCtx.canvas.height);

					function getId(imageData:ImageData, x:Int, y:Int):Int {
						var off = (((y + imageData.height) % imageData.height) * imageData.width + ((x + imageData.width) % imageData.width)) * 4;
						return imageData.data[off + 0] +
							imageData.data[off + 1] * 256 +
							imageData.data[off + 2] * 256 * 256 +
							imageData.data[off + 3] * 256 * 256 * 256;
					}

					function putPixel(imageData:ImageData, x:Int, y:Int, color:Array<Int>) {
						var off = (y * imageData.width + x) * 4;
						imageData.data.set(color, off);
					}

					for (y in 0...pick.height) {
						for (x in 0...pick.width) {
							var s = getId(pick, x, y);
							var r = getId(pick, x + 1, y);
							var d = getId(pick, x, y + 1);
							var v = 0;
							if (s != r || s != d) {
								v = 255;
							}
							putPixel(outline, x, y, [v, v, v, v]);
						}
					}

					for (y in 0...outline.height) {
						for (x in 0...outline.width) {
							var s = getId(outline, x, y);
							var l = getId(outline, x - 1, y);
							var u = getId(outline, x, y - 1);
							var r = getId(outline, x + 1, y);
							var d = getId(outline, x, y + 1);
							//const rd = getId(outline, x + 1, y + 1);
							var v = s;
							if ((s && r && d) ||
								(s && l && d) ||
								(s && r && u) ||
								(s && l && u)) {
								v = 0;
							}
							putPixel(outline, x, y, [v, v, v, v]);
						}
					}

					outlineCtx.putImageData(outline, 0, 0);
				} else {
					areas.push(record.value);
					draw(record.value);
					if (i % 20 == 19) {
						wait().then(readNext);
					} else {
						readNext();
					}
				}
				i++;
			});
		}
		readNext();
	});
}

main();