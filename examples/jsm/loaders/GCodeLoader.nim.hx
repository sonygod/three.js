import three.examples.jsm.loaders.GCodeLoader;
import three.examples.jsm.loaders.Loader;
import three.examples.jsm.loaders.FileLoader;
import three.examples.jsm.core.BufferGeometry;
import three.examples.jsm.materials.LineBasicMaterial;
import three.examples.jsm.objects.LineSegments;
import three.examples.jsm.objects.Group;
import three.examples.jsm.math.Vector3;

class GCodeLoader extends Loader {

  public var splitLayer(default, null):Bool;

  public function new(manager:Loader.Manager) {
    super(manager);
    this.splitLayer = false;
  }

  public function load(url:String, onLoad:Dynamic, onProgress:Dynamic, onError:Dynamic) {
    var scope = this;
    var loader = new FileLoader(scope.manager);
    loader.setPath(scope.path);
    loader.setRequestHeader(scope.requestHeader);
    loader.setWithCredentials(scope.withCredentials);
    loader.load(url, function(text) {
      try {
        onLoad(scope.parse(text));
      } catch (e:Dynamic) {
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
    var state = { x: 0, y: 0, z: 0, e: 0, f: 0, extruding: false, relative: false };
    var layers = [];
    var currentLayer;
    var pathMaterial = new LineBasicMaterial({ color: 0xFF0000 });
    pathMaterial.name = 'path';
    var extrudingMaterial = new LineBasicMaterial({ color: 0x00FF00 });
    extrudingMaterial.name = 'extruded';

    function newLayer(line:Vector3) {
      currentLayer = { vertex: [], pathVertex: [], z: line.z };
      layers.push(currentLayer);
    }

    function addSegment(p1:Vector3, p2:Vector3) {
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

    function delta(v1:Float, v2:Float) {
      return state.relative ? v2 : v2 - v1;
    }

    function absolute(v1:Float, v2:Float) {
      return state.relative ? v1 + v2 : v2;
    }

    var lines = data.replace(/;.+/g, '').split('\n');
    for (i in 0...lines.length) {
      var tokens = lines[i].split(' ');
      var cmd = tokens[0].toUpperCase();
      var args = {};
      tokens.splice(1).forEach(function(token) {
        if (token[0] != undefined) {
          var key = token[0].toLowerCase();
          var value = Std.parseFloat(token.substring(1));
          args[key] = value;
        }
      });
      if (cmd == 'G0' || cmd == 'G1') {
        var line = {
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
      } else if (cmd == 'G2' || cmd == 'G3') {
        // G2/G3 - Arc Movement ( G2 clock wise and G3 counter clock wise )
        //console.warn( 'THREE.GCodeLoader: Arc command not supported' );
      } else if (cmd == 'G90') {
        // G90: Set to Absolute Positioning
        state.relative = false;
      } else if (cmd == 'G91') {
        // G91: Set to state.relative Positioning
        state.relative = true;
      } else if (cmd == 'G92') {
        // G92: Set Position
        var line = state;
        line.x = args.x != undefined ? args.x : line.x;
        line.y = args.y != undefined ? args.y : line.y;
        line.z = args.z != undefined ? args.z : line.z;
        line.e = args.e != undefined ? args.e : line.e;
      } else {
        //console.warn( 'THREE.GCodeLoader: Command not supported:' + cmd );
      }
    }

    function addObject(vertex:Array<Float>, extruding:Bool, i:Int) {
      var geometry = new BufferGeometry();
      geometry.setAttribute('position', new Float32BufferAttribute(vertex, 3));
      var segments = new LineSegments(geometry, extruding ? extrudingMaterial : pathMaterial);
      segments.name = 'layer' + i;
      object.add(segments);
    }

    var object = new Group();
    object.name = 'gcode';
    if (this.splitLayer) {
      for (i in 0...layers.length) {
        var layer = layers[i];
        addObject(layer.vertex, true, i);
        addObject(layer.pathVertex, false, i);
      }
    } else {
      var vertex = [],
          pathVertex = [];
      for (i in 0...layers.length) {
        var layer = layers[i];
        var layerVertex = layer.vertex;
        var layerPathVertex = layer.pathVertex;
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