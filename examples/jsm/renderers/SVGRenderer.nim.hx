import three.js.examples.jsm.renderers.Projector;
import three.js.examples.jsm.renderers.RenderableFace;
import three.js.examples.jsm.renderers.RenderableLine;
import three.js.examples.jsm.renderers.RenderableSprite;

class SVGObject extends three.js.examples.jsm.core.Object3D {

	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		super();
		this.node = node;
	}

}

class SVGRenderer {

	public var domElement:Dynamic;
	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;
	public var overdraw:Float = 0.5;
	public var outputColorSpace:Dynamic;
	public var info:Dynamic;

	public function new() {
		var _renderData:Dynamic, _elements:Dynamic, _lights:Dynamic,
			_svgWidth:Float, _svgHeight:Float, _svgWidthHalf:Float, _svgHeightHalf:Float,

			_v1:Dynamic, _v2:Dynamic, _v3:Dynamic,

			_svgNode:Dynamic,
			_pathCount:Int = 0,

			_precision:Dynamic,
			_quality:Int = 1,

			_currentPath:String, _currentStyle:String;

		var _this = this,
			_clipBox = new three.js.examples.jsm.core.Box2(),
			_elemBox = new three.js.examples.jsm.core.Box2(),

			_color = new three.js.examples.jsm.core.Color(),
			_diffuseColor = new three.js.examples.jsm.core.Color(),
			_ambientLight = new three.js.examples.jsm.core.Color(),
			_directionalLights = new three.js.examples.jsm.core.Color(),
			_pointLights = new three.js.examples.jsm.core.Color(),
			_clearColor = new three.js.examples.jsm.core.Color(),

			_vector3 = new three.js.examples.jsm.core.Vector3(), // Needed for PointLight
			_centroid = new three.js.examples.jsm.core.Vector3(),
			_normal = new three.js.examples.jsm.core.Vector3(),
			_normalViewMatrix = new three.js.examples.jsm.core.Matrix3(),

			_viewMatrix = new three.js.examples.jsm.core.Matrix4(),
			_viewProjectionMatrix = new three.js.examples.jsm.core.Matrix4(),

			_svgPathPool:Array<Dynamic> = [],

			_projector = new Projector(),
			_svg = js.Browser.document.createElementNS( 'http://www.w3.org/2000/svg', 'svg' );

		this.domElement = _svg;

		this.setQuality = function(quality:String) {
			switch (quality) {
				case 'high': _quality = 1; break;
				case 'low': _quality = 0; break;
			}
		};

		this.setClearColor = function(color:Dynamic) {
			_clearColor.set(color);
		};

		this.setPixelRatio = function() {};

		this.setSize = function(width:Float, height:Float) {
			_svgWidth = width; _svgHeight = height;
			_svgWidthHalf = _svgWidth / 2; _svgHeightHalf = _svgHeight / 2;

			_svg.setAttribute('viewBox', ( - _svgWidthHalf ) + ' ' + ( - _svgHeightHalf ) + ' ' + _svgWidth + ' ' + _svgHeight);
			_svg.setAttribute('width', _svgWidth);
			_svg.setAttribute('height', _svgHeight);

			_clipBox.min.set( - _svgWidthHalf, - _svgHeightHalf );
			_clipBox.max.set( _svgWidthHalf, _svgHeightHalf );
		};

		this.getSize = function() {
			return {
				width: _svgWidth,
				height: _svgHeight
			};
		};

		this.setPrecision = function(precision:Dynamic) {
			_precision = precision;
		};

		this.clear = function() {
			removeChildNodes();
			_svg.style.backgroundColor = _clearColor.getStyle(_this.outputColorSpace);
		};

		this.render = function(scene:Dynamic, camera:Dynamic) {
			// ...
		};

		function removeChildNodes() {
			// ...
		}

		function convert(c:Float):Float {
			return _precision !== null ? c.toFixed(_precision) : c;
		}

		function calculateLights(lights:Dynamic) {
			// ...
		}

		function calculateLight(lights:Dynamic, position:Dynamic, normal:Dynamic, color:Dynamic) {
			// ...
		}

		function renderSprite(v1:Dynamic, element:Dynamic, material:Dynamic) {
			// ...
		}

		function renderLine(v1:Dynamic, v2:Dynamic, material:Dynamic) {
			// ...
		}

		function renderFace3(v1:Dynamic, v2:Dynamic, v3:Dynamic, element:Dynamic, material:Dynamic) {
			// ...
		}

		function expand(v1:Dynamic, v2:Dynamic, pixels:Float) {
			// ...
		}

		function addPath(style:String, path:String) {
			// ...
		}

		function flushPath() {
			// ...
		}

		function getPathNode(id:Int) {
			// ...
		}

	}

}

export { SVGObject, SVGRenderer };