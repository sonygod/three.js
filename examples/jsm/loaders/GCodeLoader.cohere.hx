import h3d.BufferGeometry;
import h3d.FileLoader;
import h3d.Float32BufferAttribute;
import h3d.Group;
import h3d.LineBasicMaterial;
import h3d.LineSegments;
import h3d.Loader;

class GCodeLoader extends Loader {
    public var splitLayer:Bool;

    public function new(manager:Manager) {
        super(manager);
        splitLayer = false;
    }

    public function load(url:String, onLoad:T, onProgress:T, onError:T):Void {
        var scope = this;
        var loader = new FileLoader(scope.manager);
        loader.path = scope.path;
        loader.requestHeader = scope.requestHeader;
        loader.withCredentials = scope.withCredentials;
        loader.load(url, function(text) {
            try {
                onLoad(scope.parse(text));
            } catch(e) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace.error(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:String):Group {
        var state = { x: 0, y: 0, z: 0, e: 0, f: 0, extruding: false, relative: false };
        var layers = [];
        var currentLayer:Dynamic = null;

        var pathMaterial = new LineBasicMaterial({ color: 0xFF0000 });
        pathMaterial.name = 'path';

        var extrudingMaterial = new LineBasicMaterial({ color: 0x00FF00 });
        extrudingMaterial.name = 'extruded';

        function newLayer(line) {
            currentLayer = { vertex: [], pathVertex: [], z: line.z };
            layers.push(currentLayer);
        }

        function addSegment(p1, p2) {
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

        function delta(v1, v2) {
            return state.relative ? v2 : v2 - v1;
        }

        function absolute(v1, v2) {
            return state.relative ? v1 + v2 : v2;
        }

        var lines = data.replace(/;.+/g, '').split('\n');
        for (i in 0...lines.length) {
            var tokens = lines[i].split(' ');
            var cmd = tokens[0].toUpperCase();
            var args = {};
            for (t in 1...tokens.length) {
                var token = tokens[t];
                if (token[0] != null) {
                    var key = token[0].toLowerCase();
                    var value = Std.parseFloat(token.substring(1));
                    args[key] = value;
                }
            }
            if (cmd == 'G0' || cmd == 'G1') {
                var line = {
                    x: args.x != null ? absolute(state.x, args.x) : state.x,
                    y: args.y != null ? absolute(state.y, args.y) : state.y,
                    z: args.z != null ? absolute(state.z, args.z) : state.z,
                    e: args.e != null ? absolute(state.e, args.e) : state.e,
                    f: args.f != null ? absolute(state.f, args.f) : state.f,
                };
                if (delta(state.e, line.e) > 0) {
                    state.extruding = delta(state.e, line.e) > 0;
                    if (currentLayer == null || line.z != currentLayer.z) {
                        newLayer(line);
                    }
                }
                addSegment(state, line);
                state = line;
            } else if (cmd == 'G2' || cmd == 'G3') {
                // G2/G3 - Arc Movement (G2 clock wise and G3 counter clock wise)
                // console.warn('THREE.GCodeLoader: Arc command not supported');
            } else if (cmd == 'G90') {
                // G90: Set to Absolute Positioning
                state.relative = false;
            } else if (cmd == 'G91') {
                // G91: Set to Relative Positioning
                state.relative = true;
            } else if (cmd == 'G92') {
                // G92: Set Position
                var line = state;
                line.x = args.x != null ? args.x : line.x;
                line.y = args.y != null ? args.y : line.y;
                line.z = args.z != null ? args.z : line.z;
                line.e = args.e != null ? args.e : line.e;
            } else {
                // console.warn('THREE.GCodeLoader: Command not supported:', cmd);
            }
        }

        function addObject(vertex, extruding, i) {
            var geometry = new BufferGeometry();
            geometry.setAttribute('position', new Float32BufferAttribute(vertex, 3));
            var segments = new LineSegments(geometry, extruding ? extrudingMaterial : pathMaterial);
            segments.name = 'layer' + i;
            object.add(segments);
        }

        var object = new Group();
        object.name = 'gcode';

        if (splitLayer) {
            for (l in 0...layers.length) {
                var layer = layers[l];
                addObject(layer.vertex, true, l);
                addObject(layer.pathVertex, false, l);
            }
        } else {
            var vertex = [];
            var pathVertex = [];
            for (l in 0...layers.length) {
                var layer = layers[l];
                var layerVertex = layer.vertex;
                var layerPathVertex = layer.pathVertex;
                for (v in 0...layerVertex.length) {
                    vertex.push(layerVertex[v]);
                }
                for (v in 0...layerPathVertex.length) {
                    pathVertex.push(layerPathVertex[v]);
                }
            }
            addObject(vertex, true, layers.length);
            addObject(pathVertex, false, layers.length);
        }

        object.rotation.set(-Math.PI / 2, 0, 0);

        return object;
    }
}