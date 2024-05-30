import three.Vector3;
import three.Quaternion;
import three.Matrix4;
import three.Object3D;

class CSS3DObject extends Object3D {

	public var isCSS3DObject:Bool = true;
	public var element:Dynamic;

	public function new(element:Dynamic = js.Browser.document.createElement('div')) {
		super();
		this.element = element;
		this.element.style.position = 'absolute';
		this.element.style.pointerEvents = 'auto';
		this.element.style.userSelect = 'none';
		this.element.setAttribute('draggable', false);
		this.addEventListener(Event.REMOVED, function() {
			this.traverse(function(object:Dynamic) {
				if (object.element instanceof js.html.Element && object.element.parentNode !== null) {
					object.element.parentNode.removeChild(object.element);
				}
			});
		});
	}

	public function copy(source:CSS3DObject, recursive:Bool):CSS3DObject {
		super.copy(source, recursive);
		this.element = source.element.cloneNode(true);
		return this;
	}
}

class CSS3DSprite extends CSS3DObject {

	public var isCSS3DSprite:Bool = true;
	public var rotation2D:Float = 0;

	public function new(element:Dynamic) {
		super(element);
	}

	public function copy(source:CSS3DSprite, recursive:Bool):CSS3DSprite {
		super.copy(source, recursive);
		this.rotation2D = source.rotation2D;
		return this;
	}
}

class CSS3DRenderer {

	public var domElement:Dynamic;

	public function new(parameters:Dynamic = {}) {
		var _this = this;
		var _width:Float;
		var _height:Float;
		var _widthHalf:Float;
		var _heightHalf:Float;
		var cache:Dynamic = {
			camera: { style: '' },
			objects: new js.Map()
		};
		this.domElement = parameters.element !== undefined ? parameters.element : js.Browser.document.createElement('div');
		this.domElement.style.overflow = 'hidden';
		var viewElement = js.Browser.document.createElement('div');
		viewElement.style.transformOrigin = '0 0';
		viewElement.style.pointerEvents = 'none';
		this.domElement.appendChild(viewElement);
		var cameraElement = js.Browser.document.createElement('div');
		cameraElement.style.transformStyle = 'preserve-3d';
		viewElement.appendChild(cameraElement);
		this.getSize = function() {
			return {
				width: _width,
				height: _height
			};
		};
		this.render = function(scene:Dynamic, camera:Dynamic) {
			var fov = camera.projectionMatrix.elements[5] * _heightHalf;
			if (camera.view && camera.view.enabled) {
				viewElement.style.transform = 'translate(' + -camera.view.offsetX * (_width / camera.view.width) + 'px, ' + -camera.view.offsetY * (_height / camera.view.height) + 'px)';
				viewElement.style.transform += 'scale(' + camera.view.fullWidth / camera.view.width + ', ' + camera.view.fullHeight / camera.view.height + ')';
			} else {
				viewElement.style.transform = '';
			}
			if (scene.matrixWorldAutoUpdate === true) scene.updateMatrixWorld();
			if (camera.parent === null && camera.matrixWorldAutoUpdate === true) camera.updateMatrixWorld();
			var tx:Float;
			var ty:Float;
			if (camera.isOrthographicCamera) {
				tx = -(camera.right + camera.left) / 2;
				ty = (camera.top + camera.bottom) / 2;
			}
			var scaleByViewOffset = camera.view && camera.view.enabled ? camera.view.height / camera.view.fullHeight : 1;
			var cameraCSSMatrix = camera.isOrthographicCamera ?
				'scale(' + scaleByViewOffset + ')' + 'scale(' + fov + ')' + 'translate(' + epsilon(tx) + 'px,' + epsilon(ty) + 'px)' + getCameraCSSMatrix(camera.matrixWorldInverse) :
				'scale(' + scaleByViewOffset + ')' + 'translateZ(' + fov + 'px)' + getCameraCSSMatrix(camera.matrixWorldInverse);
			var perspective = camera.isPerspectiveCamera ? 'perspective(' + fov + 'px) ' : '';
			var style = perspective + cameraCSSMatrix +
				'translate(' + _widthHalf + 'px,' + _heightHalf + 'px)';
			if (cache.camera.style !== style) {
				cameraElement.style.transform = style;
				cache.camera.style = style;
			}
			renderObject(scene, scene, camera, cameraCSSMatrix);
		};
		this.setSize = function(width:Float, height:Float) {
			_width = width;
			_height = height;
			_widthHalf = _width / 2;
			_heightHalf = _height / 2;
			this.domElement.style.width = width + 'px';
			this.domElement.style.height = height + 'px';
			viewElement.style.width = width + 'px';
			viewElement.style.height = height + 'px';
			cameraElement.style.width = width + 'px';
			cameraElement.style.height = height + 'px';
		};
		function epsilon(value:Float) {
			return Math.abs(value) < 1e-10 ? 0 : value;
		}
		function getCameraCSSMatrix(matrix:Matrix4) {
			var elements = matrix.elements;
			return 'matrix3d(' +
				epsilon(elements[0]) + ',' +
				epsilon(-elements[1]) + ',' +
				epsilon(elements[2]) + ',' +
				epsilon(elements[3]) + ',' +
				epsilon(elements[4]) + ',' +
				epsilon(-elements[5]) + ',' +
				epsilon(elements[6]) + ',' +
				epsilon(elements[7]) + ',' +
				epsilon(elements[8]) + ',' +
				epsilon(-elements[9]) + ',' +
				epsilon(elements[10]) + ',' +
				epsilon(elements[11]) + ',' +
				epsilon(elements[12]) + ',' +
				epsilon(-elements[13]) + ',' +
				epsilon(elements[14]) + ',' +
				epsilon(elements[15]) +
				')';
		}
		function getObjectCSSMatrix(matrix:Matrix4) {
			var elements = matrix.elements;
			var matrix3d = 'matrix3d(' +
				epsilon(elements[0]) + ',' +
				epsilon(elements[1]) + ',' +
				epsilon(elements[2]) + ',' +
				epsilon(elements[3]) + ',' +
				epsilon(-elements[4]) + ',' +
				epsilon(-elements[5]) + ',' +
				epsilon(-elements[6]) + ',' +
				epsilon(-elements[7]) + ',' +
				epsilon(elements[8]) + ',' +
				epsilon(elements[9]) + ',' +
				epsilon(elements[10]) + ',' +
				epsilon(elements[11]) + ',' +
				epsilon(elements[12]) + ',' +
				epsilon(elements[13]) + ',' +
				epsilon(elements[14]) + ',' +
				epsilon(elements[15]) +
				')';
			return 'translate(-50%,-50%)' + matrix3d;
		}
		function hideObject(object:Dynamic) {
			if (object.isCSS3DObject) object.element.style.display = 'none';
			for (i in object.children) {
				hideObject(object.children[i]);
			}
		}
		function renderObject(object:Dynamic, scene:Dynamic, camera:Dynamic, cameraCSSMatrix:String) {
			if (object.visible === false) {
				hideObject(object);
				return;
			}
			if (object.isCSS3DObject) {
				var visible = (object.layers.test(camera.layers) === true);
				var element = object.element;
				element.style.display = visible === true ? '' : 'none';
				if (visible === true) {
					object.onBeforeRender(_this, scene, camera);
					var style:String;
					if (object.isCSS3DSprite) {
						_matrix.copy(camera.matrixWorldInverse);
						_matrix.transpose();
						if (object.rotation2D !== 0) _matrix.multiply(_matrix2.makeRotationZ(object.rotation2D));
						object.matrixWorld.decompose(_position, _quaternion, _scale);
						_matrix.setPosition(_position);
						_matrix.scale(_scale);
						_matrix.elements[3] = 0;
						_matrix.elements[7] = 0;
						_matrix.elements[11] = 0;
						_matrix.elements[15] = 1;
						style = getObjectCSSMatrix(_matrix);
					} else {
						style = getObjectCSSMatrix(object.matrixWorld);
					}
					var cachedObject = cache.objects.get(object);
					if (cachedObject === undefined || cachedObject.style !== style) {
						element.style.transform = style;
						var objectData = { style: style };
						cache.objects.set(object, objectData);
					}
					if (element.parentNode !== cameraElement) {
						cameraElement.appendChild(element);
					}
					object.onAfterRender(_this, scene, camera);
				}
			}
			for (i in object.children) {
				renderObject(object.children[i], scene, camera, cameraCSSMatrix);
			}
		}
	}
}