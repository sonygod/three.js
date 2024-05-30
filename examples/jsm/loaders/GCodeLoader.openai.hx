package three.js.loaders;

import three.js.loaders.BufferGeometry;
import three.js.loaders.FileLoader;
import three.js.loaders.Float32BufferAttribute;
import three.js.loaders.Group;
import three.js.loaders.LineBasicMaterial;
import three.js.loaders.LineSegments;
import three.js.loaders.Loader;

/**
 * GCodeLoader is used to load gcode files usually used for 3D printing or CNC applications.
 *
 * Gcode files are composed by commands used by machines to create objects.
 *
 * @class GCodeLoader
 * @param {Manager} manager Loading manager.
 */

class GCodeLoader extends Loader {

    public var splitLayer:Bool;

    public function new(manager:Manager) {
        super(manager);
        splitLayer = false;
    }

    public function load(url:String, onLoad:Dynamic->Void, onProgress:Float->Void, onError:Error->Void) {
        var scope:GCodeLoader = this;
        var loader:FileLoader = new FileLoader(scope.manager);
        loader.setPath(scope.path);
        loader.setRequestHeader(scope.requestHeader);
        loader.setWithCredentials(scope.withCredentials);
        loader.load(url, function(text:String) {
            try {
                onLoad(scope.parse(text));
            } catch (e:Error) {
                if (onError != null) {
                    onError(e);
                } else {
                    trace(e);
                }
                scope.manager.itemError(url);
            }
        }, onProgress, onError);
    }

    public function parse(data:String):Group {
        var state:Dynamic = { x: 0, y: 0, z: 0, e: 0, f: 0, extruding: false, relative: false };
        var layers:Array<Dynamic> = [];

        var currentLayer:Dynamic;

        var pathMaterial:LineBasicMaterial = new LineBasicMaterial({ color: 0xFF0000 });
        pathMaterial.name = 'path';

        var extrudingMaterial:LineBasicMaterial = new LineBasicMaterial({ color: 0x00FF00 });
        extrudingMaterial.name = 'extruded';

        function newLayer(line:Dynamic) {
            currentLayer = { vertex: [], pathVertex: [], z: line.z };
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

        var lines:Array<String> = data.replace~/;.+/g, ''/)
            .split('\n');

        for (i in 0...lines.length) {
            var tokens:Array<String> = lines[i].split(' ');
            var cmd:String = tokens[0].toUpperCase();

            var args:Dynamic = {};
            for (token in tokens.slice(1)) {
                if (token.charAt(0) != undefined) {
                    var key:String = token.charAt(0).toLowerCase();
                    var value:Float = Std.parseFloat(token.substring(1));
                    args[key] = value;
                }
            }

            switch (cmd) {
                case 'G0', 'G1':
                    var line:Dynamic = {
                        x: args.x != undefined ? absolute(state.x, args.x) : state.x,
                        y: args.y != undefined ? absolute(state.y, args.y) : state.y,
                        z: args.z != undefined ? absolute(state.z, args.z) : state.z,
                        e: args.e != undefined ? absolute(state.e, args.e) : state.e,
                        f: args.f != undefined ? absolute(state.f, args.f) : state.f,
                    };

                    if (delta(state.e, line.e) > 0) {
                        state.extruding = delta(state.e, line.e) > 0;

                        if (currentLayer == null || line.z != currentLayer.z) {
                            newLayer(line);
                        }
                    }

                    addSegment(state, line);
                    state = line;

                case 'G2', 'G3':
                    // G2/G3 - Arc Movement (G2 clock wise and G3 counter clock wise)
                    trace('THREE.GCodeLoader: Arc command not supported');

                case 'G90':
                    state.relative = false;

                case 'G91':
                    state.relative = true;

                case 'G92':
                    var line:Dynamic = state;
                    line.x = args.x != undefined ? args.x : line.x;
                    line.y = args.y != undefined ? args.y : line.y;
                    line.z = args.z != undefined ? args.z : line.z;
                    line.e = args.e != undefined ? args.e : line.e;

                default:
                    trace('THREE.GCodeLoader: Command not supported: ' + cmd);
            }
        }

        function addObject(vertex:Array<Float>, extruding:Bool, i:Int) {
            var geometry:BufferGeometry = new BufferGeometry();
            geometry.setAttribute('position', new Float32BufferAttribute(vertex, 3));
            var segments:LineSegments = new LineSegments(geometry, extruding ? extrudingMaterial : pathMaterial);
            segments.name = 'layer' + i;
            object.add(segments);
        }

        var object:Group = new Group();
        object.name = 'gcode';

        if (splitLayer) {
            for (i in 0...layers.length) {
                var layer:Dynamic = layers[i];
                addObject(layer.vertex, true, i);
                addObject(layer.pathVertex, false, i);
            }
        } else {
            var vertex:Array<Float> = [];
            var pathVertex:Array<Float> = [];

            for (i in 0...layers.length) {
                var layer:Dynamic = layers[i];
                var layerVertex:Array<Float> = layer.vertex;
                var layerPathVertex:Array<Float> = layer.pathVertex;

                for (j in 0...layerVertex.length) {
                    vertex.push(layerVertex[j]);
                }

                for (j in 0...layerPathVertex.length) {
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