package;

import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.loaders.FileLoader;
import three.loaders.Loader;
import three.loaders.LoadingManager;
import three.materials.LineBasicMaterial;
import three.math.Vector3;
import three.objects.Group;
import three.objects.LineSegments;
import three.types.BufferAttributeTypes;

/**
 * GCodeLoader is used to load gcode files usually used for 3D printing or CNC applications.
 *
 * Gcode files are composed by commands used by machines to create objects.
 *
 * @class GCodeLoader
 * @param {Manager} manager Loading manager.
 */
class GCodeLoader extends Loader {

	public var splitLayer:Bool = false;

	public function new(manager:LoadingManager = null) {
		super(manager);
	}

	override public function load(url:String, onLoad:Group->Void, ?onProgress:FileLoader->Int->Void, ?onError:Dynamic->Void):Void {
		final scope = this;
		final loader = new FileLoader(manager);

		loader.setPath(path);
		loader.setRequestHeader(requestHeader);
		loader.setWithCredentials(withCredentials);

		loader.load(url,
			function(text:String) {
				try {
					onLoad(scope.parse(text));
				} catch (e:Dynamic) {
					if (onError != null) {
						onError(e);
					} else {
						trace('GCodeLoader: Error parsing data: $e');
					}

					scope.manager.itemError(url);
				}
			},
			onProgress,
			onError
		);
	}

	public function parse(data:String):Group {
		var state = {x: 0., y: 0., z: 0., e: 0., f: 0., extruding: false, relative: false};
		final layers:Array<{vertex: Array<Float>, pathVertex: Array<Float>, z: Float}> = [];

		var currentLayer: {vertex: Array<Float>, pathVertex: Array<Float>, z: Float> = null;

		final pathMaterial = new LineBasicMaterial({color: 0xFF0000});
		pathMaterial.name = 'path';

		final extrudingMaterial = new LineBasicMaterial({color: 0x00FF00});
		extrudingMaterial.name = 'extruded';

		final object = new Group();
		object.name = 'gcode';

		function newLayer(line:Dynamic) {
			currentLayer = {vertex: [], pathVertex: [], z: line.z};
			layers.push(currentLayer);
		}

		//Create lie segment between p1 and p2
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

		final lines = data.replace(/;.+/g, '').split("\n");

		for (i in 0...lines.length) {
			final tokens = lines[i].trim().split(" ");
			final cmd = tokens[0].toUpperCase();

			//Argumments
			final args:Dynamic = {};
			for (j in 1...tokens.length) {
				final token = tokens[j];
				if (token[0] != null) {
					final key = token[0].toLowerCase();
					final value = Std.parseFloat(token.substring(1));
					args[key] = value;
				}
			}

			//Process commands
			//G0/G1 – Linear Movement
			if (cmd == "G0" || cmd == "G1") {
				final line = {
					x: (args.x != null) ? absolute(state.x, args.x) : state.x,
					y: (args.y != null) ? absolute(state.y, args.y) : state.y,
					z: (args.z != null) ? absolute(state.z, args.z) : state.z,
					e: (args.e != null) ? absolute(state.e, args.e) : state.e,
					f: (args.f != null) ? absolute(state.f, args.f) : state.f
				};

				//Layer change detection is or made by watching Z, it's made by watching when we extrude at a new Z position
				if (delta(state.e, line.e) > 0) {
					state.extruding = delta(state.e, line.e) > 0;

					if (currentLayer == null || line.z != currentLayer.z) {
						newLayer(line);
					}
				}

				addSegment(state, line);
				state = line;
			} else if (cmd == "G2" || cmd == "G3") {
				//G2/G3 - Arc Movement ( G2 clock wise and G3 counter clock wise )
				//console.warn( 'THREE.GCodeLoader: Arc command not supported' );
			} else if (cmd == "G90") {
				//G90: Set to Absolute Positioning
				state.relative = false;
			} else if (cmd == "G91") {
				//G91: Set to state.relative Positioning
				state.relative = true;
			} else if (cmd == "G92") {
				//G92: Set Position
				final line = state;
				line.x = (args.x != null) ? args.x : line.x;
				line.y = (args.y != null) ? args.y : line.y;
				line.z = (args.z != null) ? args.z : line.z;
				line.e = (args.e != null) ? args.e : line.e;
			} else {
				//console.warn( 'THREE.GCodeLoader: Command not supported:' + cmd );
			}
		}

		function addObject(vertex:Array<Float>, extruding:Bool, i:Int) {
			final geometry = new BufferGeometry();
			geometry.setAttribute('position', new Float32BufferAttribute(vertex, 3, false));

			final segments = new LineSegments(geometry, extruding ? extrudingMaterial : pathMaterial);
			segments.name = 'layer$i';
			object.add(segments);
		}

		if (splitLayer) {
			for (i in 0...layers.length) {
				final layer = layers[i];
				addObject(layer.vertex, true, i);
				addObject(layer.pathVertex, false, i);
			}
		} else {
			final vertex:Array<Float> = [];
			final pathVertex:Array<Float> = [];

			for (i in 0...layers.length) {
				final layer = layers[i];

				for (j in 0...layer.vertex.length) {
					vertex.push(layer.vertex[j]);
				}

				for (j in 0...layer.pathVertex.length) {
					pathVertex.push(layer.pathVertex[j]);
				}
			}

			addObject(vertex, true, layers.length);
			addObject(pathVertex, false, layers.length);
		}

		object.rotation.set(-Math.PI / 2, 0, 0);

		return object;
	}
}