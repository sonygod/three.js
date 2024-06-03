import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.Browser;

class Main {
    static function main() {
        var size:Int = 4096;
        var pickCtx:CanvasRenderingContext2D = Browser.document.querySelector("#pick").getContext("2d");
        pickCtx.canvas.width = size;
        pickCtx.canvas.height = size;

        var outlineCtx:CanvasRenderingContext2D = Browser.document.querySelector("#outline").getContext("2d");
        outlineCtx.canvas.width = size;
        outlineCtx.canvas.height = size;
        outlineCtx.translate(outlineCtx.canvas.width / 2, outlineCtx.canvas.height / 2);
        outlineCtx.scale(outlineCtx.canvas.width / 360, outlineCtx.canvas.height / -180);
        outlineCtx.strokeStyle = '#FFF';

        var workCtx:CanvasRenderingContext2D = Browser.document.createElement("canvas").getContext("2d");
        workCtx.canvas.width = size;
        workCtx.canvas.height = size;

        var id:Int = 1;
        var countryData:Map<String, Dynamic> = new Map();
        var countriesById:Array<Dynamic> = [];
        var min:Array<Float> = [10000, 10000];
        var max:Array<Float> = [-10000, -10000];

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

        var geoHandlers:Map<String, (ctx:CanvasRenderingContext2D, geo:Dynamic, drawFn:Void->Void)->Void> = [
            'MultiPolygon' => multiPolygonArea,
            'Polygon' => polygonArea
        ];

        function multiPolygonArea(ctx:CanvasRenderingContext2D, geo:Dynamic, drawFn:Void->Void) {
            var coordinates:Array<Array<Array<Float>>> = geo.coordinates;
            for (polygon in coordinates) {
                ctx.beginPath();
                for (ring in polygon) {
                    ring.forEach(minMax);
                    ctx.moveTo(ring[0][0], ring[0][1]);
                    for (i in 0...ring.length) {
                        ctx.lineTo(ring[i][0], ring[i][1]);
                    }
                    ctx.closePath();
                }
                drawFn();
            }
        }

        function polygonArea(ctx:CanvasRenderingContext2D, geo:Dynamic, drawFn:Void->Void) {
            var coordinates:Array<Array<Float>> = geo.coordinates;
            ctx.beginPath();
            for (ring in coordinates) {
                ring.forEach(minMax);
                ctx.moveTo(ring[0][0], ring[0][1]);
                for (i in 0...ring.length) {
                    ctx.lineTo(ring[i][0], ring[i][1]);
                }
                ctx.closePath();
            }
            drawFn();
        }

        function fill(ctx:CanvasRenderingContext2D) {
            ctx.fill('evenodd');
        }

        function draw(area:Dynamic) {
            var properties:Dynamic = area.properties;
            var geometry:Dynamic = area.geometry;
            var type:String = geometry.type;
            var name:String = properties.NAME;
            trace(name);

            if (!countryData.exists(name)) {
                var r:Int = id & 0xFF;
                var g:Int = (id >> 8) & 0xFF;
                var b:Int = (id >> 16) & 0xFF;

                countryData[name] = {
                    color: [r, g, b],
                    id: id++
                };
                countriesById.push({name: name});
            }

            var countryInfo:Dynamic = countriesById[countryData[name].id - 1];

            var handler:Void->Void = geoHandlers.get(type);
            if (handler == null) {
                throw 'unknown geometry type.';
            }

            resetMinMax();

            workCtx.save();
            workCtx.clearRect(0, 0, workCtx.canvas.width, workCtx.canvas.height);
            workCtx.fillStyle = '#000';
            workCtx.strokeStyle = '#000';
            workCtx.translate(workCtx.canvas.width / 2, workCtx.canvas.height / 2);
            workCtx.scale(workCtx.canvas.width / 360, workCtx.canvas.height / -180);

            handler(workCtx, geometry, fill);

            workCtx.restore();

            countryInfo.min = min;
            countryInfo.max = max;
            countryInfo.area = properties.AREA;
            countryInfo.lat = properties.LAT;
            countryInfo.lon = properties.LON;
            countryInfo.population = {
                '2005': properties.POP2005
            };

            var left:Int = Math.floor((min[0] + 180) * workCtx.canvas.width / 360);
            var bottom:Int = Math.floor((-min[1] + 90) * workCtx.canvas.height / 180);
            var right:Int = Math.ceil((max[0] + 180) * workCtx.canvas.width / 360);
            var top:Int = Math.ceil((-max[1] + 90) * workCtx.canvas.height / 180);
            var width:Int = right - left + 1;
            var height:Int = Math.max(1, bottom - top + 1);

            var color:Array<Int> = countryData[name].color;
            var src:ImageData = workCtx.getImageData(left, top, width, height);
            for (y in 0...height) {
                for (x in 0...width) {
                    var off:Int = (y * width + x) * 4;
                    if (src.data[off + 3] != 0) {
                        src.data[off + 0] = color[0];
                        src.data[off + 1] = color[1];
                        src.data[off + 2] = color[2];
                        src.data[off + 3] = 255;
                    }
                }
            }

            workCtx.putImageData(src, left, top);
            pickCtx.drawImage(workCtx.canvas, 0, 0);
        }

        async function loadShapefile() {
            var source:Shapefile = await Shapefile.open('TM_WORLD_BORDERS-0.3.shp');
            var areas:Array<Dynamic> = [];
            for (i in 0...10000) {
                var {done, value} = await source.read();
                if (done) {
                    break;
                }
                areas.push(value);
                draw(value);
                if (i % 20 == 19) {
                    await wait();
                }
            }

            trace(JSON.stringify(areas));

            trace('min', min);
            trace('max', max);

            trace(JSON.stringify(countriesById, null, 2));

            var pick:ImageData = pickCtx.getImageData(0, 0, pickCtx.canvas.width, pickCtx.canvas.height);
            var outline:ImageData = outlineCtx.getImageData(0, 0, outlineCtx.canvas.width, outlineCtx.canvas.height);

            function getId(imageData:ImageData, x:Int, y:Int) {
                var off:Int = ((y % imageData.height + imageData.height) % imageData.height) * imageData.width + ((x % imageData.width + imageData.width) % imageData.width) * 4;
                return imageData.data[off + 0] +
                       imageData.data[off + 1] * 256 +
                       imageData.data[off + 2] * 256 * 256 +
                       imageData.data[off + 3] * 256 * 256 * 256;
            }

            function putPixel(imageData:ImageData, x:Int, y:Int, color:Array<Int>) {
                var off:Int = y * imageData.width + x * 4;
                imageData.data.set(color, off);
            }

            for (y in 0...pick.height) {
                for (x in 0...pick.width) {
                    var s:Int = getId(pick, x, y);
                    var r:Int = getId(pick, x + 1, y);
                    var d:Int = getId(pick, x, y + 1);
                    var v:Int = 0;
                    if (s != r || s != d) {
                        v = 255;
                    }
                    putPixel(outline, x, y, [v, v, v, v]);
                }
            }

            for (y in 0...outline.height) {
                for (x in 0...outline.width) {
                    var s:Int = getId(outline, x, y);
                    var l:Int = getId(outline, x - 1, y);
                    var u:Int = getId(outline, x, y - 1);
                    var r:Int = getId(outline, x + 1, y);
                    var d:Int = getId(outline, x, y + 1);
                    var v:Int = s;
                    if ((s != 0 && r != 0 && d != 0) ||
                        (s != 0 && l != 0 && d != 0) ||
                        (s != 0 && r != 0 && u != 0) ||
                        (s != 0 && l != 0 && u != 0)) {
                        v = 0;
                    }
                    putPixel(outline, x, y, [v, v, v, v]);
                }
            }

            outlineCtx.putImageData(outline, 0, 0);
        }

        async function wait(ms:Int = 0) {
            return new Promise((resolve:Int->Void) -> Void -> {
                setTimeout(resolve, ms);
            });
        }

        async function run() {
            await loadShapefile();
        }

        run();
    }
}