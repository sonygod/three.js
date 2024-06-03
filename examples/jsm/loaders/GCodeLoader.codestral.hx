import three.BufferGeometry;
import three.FileLoader;
import three.Float32BufferAttribute;
import three.Group;
import three.LineBasicMaterial;
import three.LineSegments;
import three.Loader;

class GCodeLoader extends Loader {
    public var splitLayer:Bool = false;

    public function new(manager:Manager) {
        super(manager);
    }

    public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function (text) {
            try {
                onLoad(scope.parse(text));
            } catch (e:Dynamic) {
                if (onError != null) {
                    onError(e);
                } else {
                    js.Browser.console.error(e);
                }

                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:String):Group {
        var state = { x: 0.0, y: 0.0, z: 0.0, e: 0.0, f: 0.0, extruding: false, relative: false };
        var layers = new Array<Dynamic>();
        var currentLayer:Dynamic = null;

        var pathMaterial = new LineBasicMaterial({ color: 0xFF0000 });
        pathMaterial.name = 'path';

        var extrudingMaterial = new LineBasicMaterial({ color: 0x00FF00 });
        extrudingMaterial.name = 'extruded';

        function newLayer(line:Dynamic) {
            currentLayer = { vertex: new Array<Float>, pathVertex: new Array<Float>, z: line.z };
            layers.push(currentLayer);
        }

        function addSegment(p1:Dynamic, p2:Dynamic) {
            if (currentLayer == null) {
                newLayer(p1);
            }

            if (state.extruding) {
                currentLayer.vertex.push(p1.x, p1.y, p1.z);
                currentLayer.vertex.push(p2.x, p2.y, p2.z);
            } else {
                currentLayer.pathVertex.push(p1.x, p1.y, p1.z);
                currentLayer.pathVertex.push(p2.x, p2.y, p2.z);
            }
        }

        function delta(v1:Float, v2:Float):Float {
            return state.relative ? v2 : v2 - v1;
        }

        function absolute(v1:Float, v2:Float):Float {
            return state.relative ? v1 + v2 : v2;
        }

        var lines = data.replace(/;.+/g, '').split('\n');

        for (var i in 0...lines.length) {
            var tokens = lines[i].split(' ');
            var cmd = tokens[0].toUpperCase();

            var args = new Dynamic();
            for (var j in 1...tokens.length) {
                var token = tokens[j];
                if (token.charAt(0) != null) {
                    var key = token.charAt(0).toLowerCase();
                    var value = Std.parseFloat(token.substring(1));
                    args[key] = value;
                }
            }

            if (cmd == 'G0' || cmd == 'G1') {
                var line = {
                    x: args.hasOwnProperty('x') ? absolute(state.x, args['x']) : state.x,
                    y: args.hasOwnProperty('y') ? absolute(state.y, args['y']) : state.y,
                    z: args.hasOwnProperty('z') ? absolute(state.z, args['z']) : state.z,
                    e: args.hasOwnProperty('e') ? absolute(state.e, args['e']) : state.e,
                    f: args.hasOwnProperty('f') ? absolute(state.f, args['f']) : state.f,
                };

                if (delta(state.e, line.e) > 0) {
                    state.extruding = delta(state.e, line.e) > 0;

                    if (currentLayer == null || line.z != currentLayer.z) {
                        newLayer(line);
                    }
                }

                addSegment(state, line);
                state = line;
            } else if (cmd == 'G90') {
                state.relative = false;
            } else if (cmd == 'G91') {
                state.relative = true;
            } else if (cmd == 'G92') {
                var line = state;
                line.x = args.hasOwnProperty('x') ? args['x'] : line.x;
                line.y = args.hasOwnProperty('y') ? args['y'] : line.y;
                line.z = args.hasOwnProperty('z') ? args['z'] : line.z;
                line.e = args.hasOwnProperty('e') ? args['e'] : line.e;
            }
        }

        function addObject(vertex:Array<Float>, extruding:Bool, i:Int):Void {
            var geometry = new BufferGeometry();
            geometry.setAttribute('position', new Float32BufferAttribute(vertex, 3));
            var segments = new LineSegments(geometry, extruding ? extrudingMaterial : pathMaterial);
            segments.name = 'layer' + i;
            object.add(segments);
        }

        var object = new Group();
        object.name = 'gcode';

        if (this.splitLayer) {
            for (var i in 0...layers.length) {
                var layer = layers[i];
                addObject(layer.vertex, true, i);
                addObject(layer.pathVertex, false, i);
            }
        } else {
            var vertex = new Array<Float>();
            var pathVertex = new Array<Float>();

            for (var i in 0...layers.length) {
                var layer = layers[i];
                var layerVertex = layer.vertex;
                var layerPathVertex = layer.pathVertex;

                for (var j in 0...layerVertex.length) {
                    vertex.push(layerVertex[j]);
                }

                for (var j in 0...layerPathVertex.length) {
                    pathVertex.push(layerPathVertex[j]);
                }
            }

            addObject(vertex, true, layers.length);
            addObject(pathVertex, false, layers.length);
        }

        object.rotation.set(-Math.PI / 2, 0, 0);

        return object;
    }
}