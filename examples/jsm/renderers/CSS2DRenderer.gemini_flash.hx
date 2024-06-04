import three.math.Matrix4;
import three.math.Vector2;
import three.math.Vector3;
import three.core.Object3D;
import three.core.EventDispatcher;

class CSS2DObject extends Object3D {

	public var element:Dynamic;
	public var center:Vector2;
	public var isCSS2DObject:Bool;

	public function new(element:Dynamic = js.Lib.document.createElement("div")) {
		super();
		this.isCSS2DObject = true;
		this.element = element;
		js.Lib.setProperty(element, "style", {position: "absolute", userSelect: "none"});
		js.Lib.setProperty(element, "setAttribute", ["draggable", false]);
		this.center = new Vector2(0.5, 0.5);
		this.addEventListener("removed", function(event) {
			this.traverse(function(object) {
				if (js.Lib.isOfType(object.element, js.html.Element) && js.Lib.getProperty(object.element, "parentNode") != null) {
					js.Lib.getProperty(object.element, "parentNode").removeChild(object.element);
				}
			});
		});
	}

	public function copy(source:CSS2DObject, recursive:Bool):CSS2DObject {
		super.copy(source, recursive);
		this.element = js.Lib.getProperty(source.element, "cloneNode", [true]);
		this.center = source.center;
		return this;
	}
}

class CSS2DRenderer extends EventDispatcher {

	private var _width:Float;
	private var _height:Float;
	private var _widthHalf:Float;
	private var _heightHalf:Float;
	private var domElement:Dynamic;
	private var cache:Dynamic;

	public function new(parameters:Dynamic = {}) {
		super();
		var _this = this;
		var domElement = parameters.element != null ? parameters.element : js.Lib.document.createElement("div");
		js.Lib.setProperty(domElement, "style", {overflow: "hidden"});
		this.domElement = domElement;
		this.cache = {objects: new WeakMap()};

		this.getSize = function() {
			return {width: _width, height: _height};
		};

		this.render = function(scene:Object3D, camera:Object3D) {
			if (js.Lib.getProperty(scene, "matrixWorldAutoUpdate") == true) scene.updateMatrixWorld();
			if (js.Lib.getProperty(camera, "parent") == null && js.Lib.getProperty(camera, "matrixWorldAutoUpdate") == true) camera.updateMatrixWorld();
			var _viewMatrix = new Matrix4();
			_viewMatrix.copy(camera.matrixWorldInverse);
			var _viewProjectionMatrix = new Matrix4();
			_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);
			renderObject(scene, scene, camera);
			zOrder(scene);
		};

		this.setSize = function(width:Float, height:Float) {
			_width = width;
			_height = height;
			_widthHalf = _width / 2;
			_heightHalf = _height / 2;
			js.Lib.setProperty(domElement, "style", {width: width + "px", height: height + "px"});
		};

		function hideObject(object:Object3D) {
			if (js.Lib.isOfType(object, CSS2DObject)) js.Lib.setProperty(object.element, "style", {display: "none"});
			for (var i = 0; i < object.children.length; i++) {
				hideObject(object.children[i]);
			}
		}

		function renderObject(object:Object3D, scene:Object3D, camera:Object3D) {
			if (object.visible == false) {
				hideObject(object);
				return;
			}
			if (js.Lib.isOfType(object, CSS2DObject)) {
				var _vector = new Vector3();
				_vector.setFromMatrixPosition(object.matrixWorld);
				_vector.applyMatrix4(_viewProjectionMatrix);
				var visible = (_vector.z >= -1 && _vector.z <= 1) && (object.layers.test(camera.layers) == true);
				var element = object.element;
				js.Lib.setProperty(element, "style", {display: visible == true ? "" : "none"});
				if (visible == true) {
					object.onBeforeRender(_this, scene, camera);
					js.Lib.setProperty(element, "style", {transform: "translate(" + (-100 * object.center.x) + "%," + (-100 * object.center.y) + "%)" + "translate(" + (_vector.x * _widthHalf + _widthHalf) + "px," + (-_vector.y * _heightHalf + _heightHalf) + "px)"});
					if (js.Lib.getProperty(element, "parentNode") != domElement) {
						domElement.appendChild(element);
					}
					object.onAfterRender(_this, scene, camera);
				}
				var objectData = {distanceToCameraSquared: getDistanceToSquared(camera, object)};
				js.Lib.getProperty(_this.cache.objects, "set", [object, objectData]);
			}
			for (var i = 0; i < object.children.length; i++) {
				renderObject(object.children[i], scene, camera);
			}
		}

		function getDistanceToSquared(object1:Object3D, object2:Object3D) {
			var _a = new Vector3();
			_a.setFromMatrixPosition(object1.matrixWorld);
			var _b = new Vector3();
			_b.setFromMatrixPosition(object2.matrixWorld);
			return _a.distanceToSquared(_b);
		}

		function filterAndFlatten(scene:Object3D) {
			var result = [];
			scene.traverseVisible(function(object) {
				if (js.Lib.isOfType(object, CSS2DObject)) result.push(object);
			});
			return result;
		}

		function zOrder(scene:Object3D) {
			var sorted = filterAndFlatten(scene).sort(function(a:CSS2DObject, b:CSS2DObject) {
				if (a.renderOrder != b.renderOrder) {
					return b.renderOrder - a.renderOrder;
				}
				var distanceA = js.Lib.getProperty(_this.cache.objects, "get", [a]).distanceToCameraSquared;
				var distanceB = js.Lib.getProperty(_this.cache.objects, "get", [b]).distanceToCameraSquared;
				return distanceA - distanceB;
			});
			var zMax = sorted.length;
			for (var i = 0; i < sorted.length; i++) {
				js.Lib.setProperty(sorted[i].element, "style", {zIndex: zMax - i});
			}
		}
	}
}