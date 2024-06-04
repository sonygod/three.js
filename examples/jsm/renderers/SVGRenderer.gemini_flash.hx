import three.Box2;
import three.Camera;
import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Object3D;
import three.SRGBColorSpace;
import three.Vector3;
import three.renderers.Projector;
import three.renderers.RenderableFace;
import three.renderers.RenderableLine;
import three.renderers.RenderableSprite;

class SVGObject extends Object3D {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		super();
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight);

			_centroid.copy(v1.positionWorld).add(v2.positionWorld).add(v3.positionWorld).divideScalar(3);

			calculateLight(_lights, _centroid, element.normalModel, _color);

			_color.multiply(_diffuseColor).add(material.emissive);
		} else if (material.isMeshNormalMaterial) {
			_normal.copy(element.normalModel).applyMatrix3(_normalViewMatrix).normalize();

			_color.setRGB(_normal.x, _normal.y, _normal.z).multiplyScalar(0.5).addScalar(0.5);
		}

		if (material.wireframe) {
			style = 'fill:none;stroke:' + _color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.wireframeLinewidth + ';stroke-linecap:' + material.wireframeLinecap + ';stroke-linejoin:' + material.wireframeLinejoin;
		} else {
			style = 'fill:' + _color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	// Hide anti-alias gaps
	private function expand(v1:Vector3, v2:Vector3, pixels:Float) {
		var x = v2.x - v1.x;
		var y = v2.y - v1.y;
		var det = x * x + y * y;

		if (det == 0) return;

		var idet = pixels / Math.sqrt(det);

		x *= idet;
		y *= idet;

		v2.x += x;
		v2.y += y;
		v1.x -= x;
		v1.y -= y;
	}

	private function addPath(style:String, path:String) {
		if (_currentStyle == style) {
			_currentPath += path;
		} else {
			flushPath();

			_currentStyle = style;
			_currentPath = path;
		}
	}

	private function flushPath() {
		if (_currentPath != "") {
			_svgNode = getPathNode(_pathCount++);
			_svgNode.setAttribute('d', _currentPath);
			_svgNode.setAttribute('style', _currentStyle);
			_svg.appendChild(_svgNode);
		}

		_currentPath = "";
		_currentStyle = "";
	}

	private function getPathNode(id:Int) {
		if (_svgPathPool[id] == null) {
			_svgPathPool[id] = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'path');

			if (_quality == 0) {
				_svgPathPool[id].setAttribute('shape-rendering', 'crispEdges'); //optimizeSpeed
			}

			return _svgPathPool[id];
		}

		return _svgPathPool[id];
	}
}

class SVGObject {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight
import three.Box2;
import three.Camera;
import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Object3D;
import three.SRGBColorSpace;
import three.Vector3;
import three.renderers.Projector;
import three.renderers.RenderableFace;
import three.renderers.RenderableLine;
import three.renderers.RenderableSprite;

class SVGObject extends Object3D {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		super();
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight);

			_centroid.copy(v1.positionWorld).add(v2.positionWorld).add(v3.positionWorld).divideScalar(3);

			calculateLight(_lights, _centroid, element.normalModel, _color);

			_color.multiply(_diffuseColor).add(material.emissive);
		} else if (material.isMeshNormalMaterial) {
			_normal.copy(element.normalModel).applyMatrix3(_normalViewMatrix).normalize();

			_color.setRGB(_normal.x, _normal.y, _normal.z).multiplyScalar(0.5).addScalar(0.5);
		}

		if (material.wireframe) {
			style = 'fill:none;stroke:' + _color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.wireframeLinewidth + ';stroke-linecap:' + material.wireframeLinecap + ';stroke-linejoin:' + material.wireframeLinejoin;
		} else {
			style = 'fill:' + _color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	// Hide anti-alias gaps
	private function expand(v1:Vector3, v2:Vector3, pixels:Float) {
		var x = v2.x - v1.x;
		var y = v2.y - v1.y;
		var det = x * x + y * y;

		if (det == 0) return;

		var idet = pixels / Math.sqrt(det);

		x *= idet;
		y *= idet;

		v2.x += x;
		v2.y += y;
		v1.x -= x;
		v1.y -= y;
	}

	private function addPath(style:String, path:String) {
		if (_currentStyle == style) {
			_currentPath += path;
		} else {
			flushPath();

			_currentStyle = style;
			_currentPath = path;
		}
	}

	private function flushPath() {
		if (_currentPath != "") {
			_svgNode = getPathNode(_pathCount++);
			_svgNode.setAttribute('d', _currentPath);
			_svgNode.setAttribute('style', _currentStyle);
			_svg.appendChild(_svgNode);
		}

		_currentPath = "";
		_currentStyle = "";
	}

	private function getPathNode(id:Int) {
		if (_svgPathPool[id] == null) {
			_svgPathPool[id] = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'path');

			if (_quality == 0) {
				_svgPathPool[id].setAttribute('shape-rendering', 'crispEdges'); //optimizeSpeed
			}

			return _svgPathPool[id];
		}

		return _svgPathPool[id];
	}
}

class SVGObject {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight
import three.Box2;
import three.Camera;
import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Object3D;
import three.SRGBColorSpace;
import three.Vector3;
import three.renderers.Projector;
import three.renderers.RenderableFace;
import three.renderers.RenderableLine;
import three.renderers.RenderableSprite;

class SVGObject extends Object3D {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		super();
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight);

			_centroid.copy(v1.positionWorld).add(v2.positionWorld).add(v3.positionWorld).divideScalar(3);

			calculateLight(_lights, _centroid, element.normalModel, _color);

			_color.multiply(_diffuseColor).add(material.emissive);
		} else if (material.isMeshNormalMaterial) {
			_normal.copy(element.normalModel).applyMatrix3(_normalViewMatrix).normalize();

			_color.setRGB(_normal.x, _normal.y, _normal.z).multiplyScalar(0.5).addScalar(0.5);
		}

		if (material.wireframe) {
			style = 'fill:none;stroke:' + _color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.wireframeLinewidth + ';stroke-linecap:' + material.wireframeLinecap + ';stroke-linejoin:' + material.wireframeLinejoin;
		} else {
			style = 'fill:' + _color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	// Hide anti-alias gaps
	private function expand(v1:Vector3, v2:Vector3, pixels:Float) {
		var x = v2.x - v1.x;
		var y = v2.y - v1.y;
		var det = x * x + y * y;

		if (det == 0) return;

		var idet = pixels / Math.sqrt(det);

		x *= idet;
		y *= idet;

		v2.x += x;
		v2.y += y;
		v1.x -= x;
		v1.y -= y;
	}

	private function addPath(style:String, path:String) {
		if (_currentStyle == style) {
			_currentPath += path;
		} else {
			flushPath();

			_currentStyle = style;
			_currentPath = path;
		}
	}

	private function flushPath() {
		if (_currentPath != "") {
			_svgNode = getPathNode(_pathCount++);
			_svgNode.setAttribute('d', _currentPath);
			_svgNode.setAttribute('style', _currentStyle);
			_svg.appendChild(_svgNode);
		}

		_currentPath = "";
		_currentStyle = "";
	}

	private function getPathNode(id:Int) {
		if (_svgPathPool[id] == null) {
			_svgPathPool[id] = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'path');

			if (_quality == 0) {
				_svgPathPool[id].setAttribute('shape-rendering', 'crispEdges'); //optimizeSpeed
			}

			return _svgPathPool[id];
		}

		return _svgPathPool[id];
	}
}

class SVGObject {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight
import three.Box2;
import three.Camera;
import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Object3D;
import three.SRGBColorSpace;
import three.Vector3;
import three.renderers.Projector;
import three.renderers.RenderableFace;
import three.renderers.RenderableLine;
import three.renderers.RenderableSprite;

class SVGObject extends Object3D {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		super();
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight);

			_centroid.copy(v1.positionWorld).add(v2.positionWorld).add(v3.positionWorld).divideScalar(3);

			calculateLight(_lights, _centroid, element.normalModel, _color);

			_color.multiply(_diffuseColor).add(material.emissive);
		} else if (material.isMeshNormalMaterial) {
			_normal.copy(element.normalModel).applyMatrix3(_normalViewMatrix).normalize();

			_color.setRGB(_normal.x, _normal.y, _normal.z).multiplyScalar(0.5).addScalar(0.5);
		}

		if (material.wireframe) {
			style = 'fill:none;stroke:' + _color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.wireframeLinewidth + ';stroke-linecap:' + material.wireframeLinecap + ';stroke-linejoin:' + material.wireframeLinejoin;
		} else {
			style = 'fill:' + _color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	// Hide anti-alias gaps
	private function expand(v1:Vector3, v2:Vector3, pixels:Float) {
		var x = v2.x - v1.x;
		var y = v2.y - v1.y;
		var det = x * x + y * y;

		if (det == 0) return;

		var idet = pixels / Math.sqrt(det);

		x *= idet;
		y *= idet;

		v2.x += x;
		v2.y += y;
		v1.x -= x;
		v1.y -= y;
	}

	private function addPath(style:String, path:String) {
		if (_currentStyle == style) {
			_currentPath += path;
		} else {
			flushPath();

			_currentStyle = style;
			_currentPath = path;
		}
	}

	private function flushPath() {
		if (_currentPath != "") {
			_svgNode = getPathNode(_pathCount++);
			_svgNode.setAttribute('d', _currentPath);
			_svgNode.setAttribute('style', _currentStyle);
			_svg.appendChild(_svgNode);
		}

		_currentPath = "";
		_currentStyle = "";
	}

	private function getPathNode(id:Int) {
		if (_svgPathPool[id] == null) {
			_svgPathPool[id] = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'path');

			if (_quality == 0) {
				_svgPathPool[id].setAttribute('shape-rendering', 'crispEdges'); //optimizeSpeed
			}

			return _svgPathPool[id];
		}

		return _svgPathPool[id];
	}
}

class SVGObject {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight
import three.Box2;
import three.Camera;
import three.Color;
import three.Matrix3;
import three.Matrix4;
import three.Object3D;
import three.SRGBColorSpace;
import three.Vector3;
import three.renderers.Projector;
import three.renderers.RenderableFace;
import three.renderers.RenderableLine;
import three.renderers.RenderableSprite;

class SVGObject extends Object3D {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		super();
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight);

			_centroid.copy(v1.positionWorld).add(v2.positionWorld).add(v3.positionWorld).divideScalar(3);

			calculateLight(_lights, _centroid, element.normalModel, _color);

			_color.multiply(_diffuseColor).add(material.emissive);
		} else if (material.isMeshNormalMaterial) {
			_normal.copy(element.normalModel).applyMatrix3(_normalViewMatrix).normalize();

			_color.setRGB(_normal.x, _normal.y, _normal.z).multiplyScalar(0.5).addScalar(0.5);
		}

		if (material.wireframe) {
			style = 'fill:none;stroke:' + _color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.wireframeLinewidth + ';stroke-linecap:' + material.wireframeLinecap + ';stroke-linejoin:' + material.wireframeLinejoin;
		} else {
			style = 'fill:' + _color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	// Hide anti-alias gaps
	private function expand(v1:Vector3, v2:Vector3, pixels:Float) {
		var x = v2.x - v1.x;
		var y = v2.y - v1.y;
		var det = x * x + y * y;

		if (det == 0) return;

		var idet = pixels / Math.sqrt(det);

		x *= idet;
		y *= idet;

		v2.x += x;
		v2.y += y;
		v1.x -= x;
		v1.y -= y;
	}

	private function addPath(style:String, path:String) {
		if (_currentStyle == style) {
			_currentPath += path;
		} else {
			flushPath();

			_currentStyle = style;
			_currentPath = path;
		}
	}

	private function flushPath() {
		if (_currentPath != "") {
			_svgNode = getPathNode(_pathCount++);
			_svgNode.setAttribute('d', _currentPath);
			_svgNode.setAttribute('style', _currentStyle);
			_svg.appendChild(_svgNode);
		}

		_currentPath = "";
		_currentStyle = "";
	}

	private function getPathNode(id:Int) {
		if (_svgPathPool[id] == null) {
			_svgPathPool[id] = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'path');

			if (_quality == 0) {
				_svgPathPool[id].setAttribute('shape-rendering', 'crispEdges'); //optimizeSpeed
			}

			return _svgPathPool[id];
		}

		return _svgPathPool[id];
	}
}

class SVGObject {
	public var isSVGObject:Bool = true;
	public var node:Dynamic;

	public function new(node:Dynamic) {
		this.node = node;
	}
}

class SVGRenderer {
	private var _renderData:Dynamic;
	private var _elements:Array<Dynamic>;
	private var _lights:Array<Dynamic>;
	private var _svgWidth:Float;
	private var _svgHeight:Float;
	private var _svgWidthHalf:Float;
	private var _svgHeightHalf:Float;
	private var _v1:Vector3;
	private var _v2:Vector3;
	private var _v3:Vector3;
	private var _svgNode:Dynamic;
	private var _pathCount:Int = 0;
	private var _precision:Null<Float>;
	private var _quality:Int = 1;
	private var _currentPath:String;
	private var _currentStyle:String;
	private var _clipBox:Box2;
	private var _elemBox:Box2;
	private var _color:Color;
	private var _diffuseColor:Color;
	private var _ambientLight:Color;
	private var _directionalLights:Color;
	private var _pointLights:Color;
	private var _clearColor:Color;
	private var _vector3:Vector3;
	private var _centroid:Vector3;
	private var _normal:Vector3;
	private var _normalViewMatrix:Matrix3;
	private var _viewMatrix:Matrix4;
	private var _viewProjectionMatrix:Matrix4;
	private var _svgPathPool:Array<Dynamic>;
	private var _projector:Projector;
	private var _svg:Dynamic;

	public var domElement:Dynamic;

	public var autoClear:Bool = true;
	public var sortObjects:Bool = true;
	public var sortElements:Bool = true;

	public var overdraw:Float = 0.5;

	public var outputColorSpace:SRGBColorSpace;

	public var info:Dynamic;

	public function new() {
		_renderData = null;
		_elements = [];
		_lights = [];
		_svgWidth = 0.;
		_svgHeight = 0.;
		_svgWidthHalf = 0.;
		_svgHeightHalf = 0.;
		_v1 = new Vector3();
		_v2 = new Vector3();
		_v3 = new Vector3();
		_svgNode = null;
		_precision = null;
		_currentPath = "";
		_currentStyle = "";
		_clipBox = new Box2();
		_elemBox = new Box2();
		_color = new Color();
		_diffuseColor = new Color();
		_ambientLight = new Color();
		_directionalLights = new Color();
		_pointLights = new Color();
		_clearColor = new Color();
		_vector3 = new Vector3();
		_centroid = new Vector3();
		_normal = new Vector3();
		_normalViewMatrix = new Matrix3();
		_viewMatrix = new Matrix4();
		_viewProjectionMatrix = new Matrix4();
		_svgPathPool = [];
		_projector = new Projector();
		_svg = js.Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

		domElement = _svg;

		info = {
			render: {
				vertices: 0,
				faces: 0
			}
		};
	}

	public function setQuality(quality:String) {
		switch (quality) {
		case "high":
			_quality = 1;
			break;
		case "low":
			_quality = 0;
			break;
		}
	}

	public function setClearColor(color:Color) {
		_clearColor.set(color);
	}

	public function setPixelRatio() {
	}

	public function setSize(width:Float, height:Float) {
		_svgWidth = width;
		_svgHeight = height;
		_svgWidthHalf = _svgWidth / 2.;
		_svgHeightHalf = _svgHeight / 2.;

		_svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
		_svg.setAttribute('width', _svgWidth);
		_svg.setAttribute('height', _svgHeight);

		_clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
		_clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
	}

	public function getSize() {
		return {
			width: _svgWidth,
			height: _svgHeight
		};
	}

	public function setPrecision(precision:Null<Float>) {
		_precision = precision;
	}

	private function removeChildNodes() {
		_pathCount = 0;

		while (_svg.childNodes.length > 0) {
			_svg.removeChild(_svg.childNodes[0]);
		}
	}

	private function convert(c:Float) {
		return _precision != null ? c.toFixed(_precision) : c;
	}

	public function clear() {
		removeChildNodes();
		_svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
	}

	public function render(scene:Dynamic, camera:Camera) {
		if (cast camera : Camera == null) {
			js.Lib.console.error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
			return;
		}

		var background = scene.background;

		if (background != null && background.isColor) {
			removeChildNodes();
			_svg.style.backgroundColor = background.getStyle(outputColorSpace);
		} else if (autoClear) {
			clear();
		}

		info.render.vertices = 0;
		info.render.faces = 0;

		_viewMatrix.copy(camera.matrixWorldInverse);
		_viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

		_renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
		_elements = _renderData.elements;
		_lights = _renderData.lights;

		_normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

		calculateLights(_lights);

		// reset accumulated path
		_currentPath = "";
		_currentStyle = "";

		for (e in 0..._elements.length) {
			var element = _elements[e];
			var material = element.material;

			if (material == null || material.opacity == 0) continue;

			_elemBox.makeEmpty();

			if (cast element : RenderableSprite != null) {
				_v1 = element;
				_v1.x *= _svgWidthHalf;
				_v1.y *= -_svgHeightHalf;

				renderSprite(_v1, element, material);
			} else if (cast element : RenderableLine != null) {
				_v1 = element.v1;
				_v2 = element.v2;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderLine(_v1, _v2, material);
				}
			} else if (cast element : RenderableFace != null) {
				_v1 = element.v1;
				_v2 = element.v2;
				_v3 = element.v3;

				if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
				if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
				if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

				_v1.positionScreen.x *= _svgWidthHalf;
				_v1.positionScreen.y *= -_svgHeightHalf;
				_v2.positionScreen.x *= _svgWidthHalf;
				_v2.positionScreen.y *= -_svgHeightHalf;
				_v3.positionScreen.x *= _svgWidthHalf;
				_v3.positionScreen.y *= -_svgHeightHalf;

				if (overdraw > 0) {
					expand(_v1.positionScreen, _v2.positionScreen, overdraw);
					expand(_v2.positionScreen, _v3.positionScreen, overdraw);
					expand(_v3.positionScreen, _v1.positionScreen, overdraw);
				}

				_elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen, _v3.positionScreen]);

				if (_clipBox.intersectsBox(_elemBox)) {
					renderFace3(_v1, _v2, _v3, element, material);
				}
			}
		}

		flushPath(); // just to flush last svg:path

		scene.traverseVisible(function(object:Dynamic) {
			if (cast object : SVGObject != null) {
				_vector3.setFromMatrixPosition(object.matrixWorld);
				_vector3.applyMatrix4(_viewProjectionMatrix);

				if (_vector3.z < -1 || _vector3.z > 1) return;

				var x = _vector3.x * _svgWidthHalf;
				var y = -_vector3.y * _svgHeightHalf;

				var node = object.node;
				node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

				_svg.appendChild(node);
			}
		});
	}

	private function calculateLights(lights:Array<Dynamic>) {
		_ambientLight.setRGB(0, 0, 0);
		_directionalLights.setRGB(0, 0, 0);
		_pointLights.setRGB(0, 0, 0);

		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isAmbientLight) {
				_ambientLight.r += lightColor.r;
				_ambientLight.g += lightColor.g;
				_ambientLight.b += lightColor.b;
			} else if (light.isDirectionalLight) {
				_directionalLights.r += lightColor.r;
				_directionalLights.g += lightColor.g;
				_directionalLights.b += lightColor.b;
			} else if (light.isPointLight) {
				_pointLights.r += lightColor.r;
				_pointLights.g += lightColor.g;
				_pointLights.b += lightColor.b;
			}
		}
	}

	private function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
		for (l in 0...lights.length) {
			var light = lights[l];
			var lightColor = light.color;

			if (light.isDirectionalLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();

				var amount = normal.dot(lightPosition);

				if (amount <= 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			} else if (light.isPointLight) {
				var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);

				var amount = normal.dot(_vector3.subVectors(lightPosition, position).normalize());

				if (amount <= 0) continue;

				amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

				if (amount == 0) continue;

				amount *= light.intensity;

				color.r += lightColor.r * amount;
				color.g += lightColor.g * amount;
				color.b += lightColor.b * amount;
			}
		}
	}

	private function renderSprite(v1:Vector3, element:RenderableSprite, material:Dynamic) {
		var scaleX = element.scale.x * _svgWidthHalf;
		var scaleY = element.scale.y * _svgHeightHalf;

		if (material.isPointsMaterial) {
			scaleX *= material.size;
			scaleY *= material.size;
		}

		var path = 'M' + convert(v1.x - scaleX * 0.5) + ',' + convert(v1.y - scaleY * 0.5) + 'h' + convert(scaleX) + 'v' + convert(scaleY) + 'h' + convert(-scaleX) + 'z';
		var style = '';

		if (material.isSpriteMaterial || material.isPointsMaterial) {
			style = 'fill:' + material.color.getStyle(outputColorSpace) + ';fill-opacity:' + material.opacity;
		}

		addPath(style, path);
	}

	private function renderLine(v1:RenderableLine, v2:RenderableLine, material:Dynamic) {
		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y);

		if (material.isLineBasicMaterial) {
			var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

			if (material.isLineDashedMaterial) {
				style = style + ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
			}

			addPath(style, path);
		}
	}

	private function renderFace3(v1:RenderableFace, v2:RenderableFace, v3:RenderableFace, element:RenderableFace, material:Dynamic) {
		info.render.vertices += 3;
		info.render.faces += 1;

		var path = 'M' + convert(v1.positionScreen.x) + ',' + convert(v1.positionScreen.y) + 'L' + convert(v2.positionScreen.x) + ',' + convert(v2.positionScreen.y) + 'L' + convert(v3.positionScreen.x) + ',' + convert(v3.positionScreen.y) + 'z';
		var style = '';

		if (material.isMeshBasicMaterial) {
			_color.copy(material.color);

			if (material.vertexColors) {
				_color.multiply(element.color);
			}
		} else if (material.isMeshLambertMaterial || material.isMeshPhongMaterial || material.isMeshStandardMaterial) {
			_diffuseColor.copy(material.color);

			if (material.vertexColors) {
				_diffuseColor.multiply(element.color);
			}

			_color.copy(_ambientLight