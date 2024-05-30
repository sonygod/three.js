import three.Matrix4;
import three.Object3D;
import three.Vector2;
import three.Vector3;

class CSS2DObject extends Object3D {

	public var element:Dynamic;
	public var center:Vector2;

	public function new(element:Dynamic = js.Browser.document.createElement('div')) {
		super();

		this.isCSS2DObject = true;

		this.element = element;

		this.element.style.position = 'absolute';
		this.element.style.userSelect = 'none';

		this.element.setAttribute('draggable', false);

		this.center = new Vector2(0.5, 0.5); // ( 0, 0 ) is the lower left; ( 1, 1 ) is the top right

		this.addEventListener('removed', function () {
			this.traverse(function (object) {
				if (object.element instanceof Element && object.element.parentNode !== null) {
					object.element.parentNode.removeChild(object.element);
				}
			});
		});
	}

	public function copy(source:CSS2DObject, recursive:Bool):CSS2DObject {
		super.copy(source, recursive);

		this.element = js.Browser.document.importNode(source.element, true);

		this.center = source.center;

		return this;
	}
}

//

var _vector = new Vector3();
var _viewMatrix = new Matrix4();
var _viewProjectionMatrix = new Matrix4();
var _a = new Vector3();
var _b = new Vector3();

class CSS2DRenderer {

	public var domElement:Dynamic;

	public function new(parameters:Dynamic) {
		var _this = this;

		var _width, _height;
		var _widthHalf, _heightHalf;

		var cache = {
			objects: new js.Lib.WeakMap<Dynamic>()
		};

		var domElement = parameters.element !== null ? parameters.element : js.Browser.document.createElement('div');

		domElement.style.overflow = 'hidden';

		this.domElement = domElement;

		this.getSize = function () {
			return {
				width: _width,
				height: _height
			};
		};

		this.render = function (scene:Dynamic, camera:Dynamic) {
			if (scene.matrixWorldAutoUpdate === true) scene.updateMatrixWorld();
			if (camera.parent === null && camera.matrixWorldAutoUpdate === true) camera.updateMatrixWorld();

			_viewMatrix.copy(camera.matrixWorldInverse);
			_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

			renderObject(scene, scene, camera);
			zOrder(scene);
		};

		this.setSize = function (width:Int, height:Int) {
			_width = width;
			_height = height;

			_widthHalf = _width / 2;
			_heightHalf = _height / 2;

			domElement.style.width = width + 'px';
			domElement.style.height = height + 'px';
		};

		function hideObject(object:Dynamic) {
			if (object.isCSS2DObject) object.element.style.display = 'none';

			for (i in 0...object.children.length) {
				hideObject(object.children[i]);
			}
		}

		function renderObject(object:Dynamic, scene:Dynamic, camera:Dynamic) {
			if (object.visible === false) {
				hideObject(object);
				return;
			}

			if (object.isCSS2DObject) {
				_vector.setFromMatrixPosition(object.matrixWorld);
				_vector.applyMatrix4(_viewProjectionMatrix);

				var visible = (_vector.z >= -1 && _vector.z <= 1) && (object.layers.test(camera.layers) === true);

				var element = object.element;
				element.style.display = visible === true ? '' : 'none';

				if (visible === true) {
					object.onBeforeRender(_this, scene, camera);

					element.style.transform = 'translate(' + (-100 * object.center.x) + '%,' + (-100 * object.center.y) + '%)' + 'translate(' + (_vector.x * _widthHalf + _widthHalf) + 'px,' + (-_vector.y * _heightHalf + _heightHalf) + 'px)';

					if (element.parentNode !== domElement) {
						domElement.appendChild(element);
					}

					object.onAfterRender(_this, scene, camera);
				}

				var objectData = {
					distanceToCameraSquared: getDistanceToSquared(camera, object)
				};

				cache.objects.set(object, objectData);
			}

			for (i in 0...object.children.length) {
				renderObject(object.children[i], scene, camera);
			}
		}

		function getDistanceToSquared(object1:Dynamic, object2:Dynamic) {
			_a.setFromMatrixPosition(object1.matrixWorld);
			_b.setFromMatrixPosition(object2.matrixWorld);

			return _a.distanceToSquared(_b);
		}

		function filterAndFlatten(scene:Dynamic) {
			var result = [];

			scene.traverseVisible(function (object) {
				if (object.isCSS2DObject) result.push(object);
			});

			return result;
		}

		function zOrder(scene:Dynamic) {
			var sorted = filterAndFlatten(scene).sort(function (a:Dynamic, b:Dynamic) {
				if (a.renderOrder !== b.renderOrder) {
					return b.renderOrder - a.renderOrder;
				}

				var distanceA = cache.objects.get(a).distanceToCameraSquared;
				var distanceB = cache.objects.get(b).distanceToCameraSquared;

				return distanceA - distanceB;
			});

			var zMax = sorted.length;

			for (i in 0...sorted.length) {
				sorted[i].element.style.zIndex = zMax - i;
			}
		}
	}
}