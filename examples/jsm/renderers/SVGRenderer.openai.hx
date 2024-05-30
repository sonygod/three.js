package three.js.examples.jsm.renderers;

import three_js.Lib;
import three_js.renderers.Projector;
import three_js.renderers.RenderableFace;
import three_js.renderers.RenderableLine;
import three_js.renderers.RenderableSprite;

class SVGObject extends Object3D {
    public var isSVGObject:Bool;
    public var node:Dynamic;

    public function new(node:Dynamic) {
        super();
        isSVGObject = true;
        this.node = node;
    }
}

class SVGRenderer {
    var _renderData:Dynamic;
    var _elements:Array<Dynamic>;
    var _lights:Array<Dynamic>;
    var _svgWidth:Float;
    var _svgHeight:Float;
    var _svgWidthHalf:Float;
    var _svgHeightHalf:Float;
    var _v1:Vector3;
    var _v2:Vector3;
    var _v3:Vector3;
    var _svgNode:Dynamic;
    var _pathCount:Int;
    var _precision:Null<Int>;
    var _quality:Int;
    var _currentColor:Color;
    var _diffuseColor:Color;
    var _ambientLight:Color;
    var _directionalLights:Color;
    var _pointLights:Color;
    var _clearColor:Color;
    var _vector3:Vector3;
    var _centroid:Vector3;
    var _normal:Vector3;
    var _normalViewMatrix:Matrix3;
    var _viewMatrix:Matrix4;
    var _viewProjectionMatrix:Matrix4;
    var _svgPathPool:Array<Dynamic>;
    var _projector:Projector;
    var _svg:Dynamic;

    public var domElement:Dynamic;
    public var autoClear:Bool;
    public var sortObjects:Bool;
    public var sortElements:Bool;
    public var overdraw:Float;
    public var outputColorSpace:SRGBColorSpace;
    public var info:Dynamic;

    public function new() {
        _renderData = null;
        _elements = [];
        _lights = [];
        _svgWidth = 0;
        _svgHeight = 0;
        _svgWidthHalf = 0;
        _svgHeightHalf = 0;
        _v1 = new Vector3();
        _v2 = new Vector3();
        _v3 = new Vector3();
        _svgNode = null;
        _pathCount = 0;
        _precision = null;
        _quality = 1;
        _currentColor = new Color();
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
        _svg = Lib.document.createElementNS('http://www.w3.org/2000/svg', 'svg');

        domElement = _svg;
        autoClear = true;
        sortObjects = true;
        sortElements = true;
        overdraw = 0.5;
        outputColorSpace = SRGBColorSpace;
        info = { render: { vertices: 0, faces: 0 } };

        this.setQuality = function(quality:String) {
            switch (quality) {
                case 'high': _quality = 1;
                case 'low': _quality = 0;
            }
        };

        this.setClearColor = function(color:Color) {
            _clearColor.set(color);
        };

        this.setPixelRatio = function() {};

        this.setSize = function(width:Float, height:Float) {
            _svgWidth = width; _svgHeight = height;
            _svgWidthHalf = _svgWidth / 2; _svgHeightHalf = _svgHeight / 2;

            _svg.setAttribute('viewBox', (-_svgWidthHalf) + ' ' + (-_svgHeightHalf) + ' ' + _svgWidth + ' ' + _svgHeight);
            _svg.setAttribute('width', _svgWidth);
            _svg.setAttribute('height', _svgHeight);

            var _clipBox = new Box2();
            _clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
            _clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
        };

        this.getSize = function() {
            return { width: _svgWidth, height: _svgHeight };
        };

        this.setPrecision = function(precision:Null<Int>) {
            _precision = precision;
        };

        function removeChildNodes() {
            _pathCount = 0;

            while (_svg.childNodes.length > 0) {
                _svg.removeChild(_svg.childNodes[0]);
            }
        }

        function convert(c:Float) {
            return _precision !== null ? Math.round(c * Math.pow(10, _precision)) / Math.pow(10, _precision) : c;
        }

        this.clear = function() {
            removeChildNodes();
            _svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
        };

        this.render = function(scene:Dynamic, camera:Camera) {
            if (!(camera is Camera)) {
                throw new Error('THREE.SVGRenderer.render: camera is not an instance of Camera.');
                return;
            }

            var background = scene.background;

            if (background != null && background.isColor) {
                removeChildNodes();
                _svg.style.backgroundColor = background.getStyle(outputColorSpace);
            } else if (autoClear) {
                this.clear();
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
            _currentPath = '';
            _currentStyle = '';

            for (e in _elements) {
                var element:Dynamic = e;
                var material:Dynamic = element.material;

                if (material == null || material.opacity == 0) continue;

                var _elemBox = new Box2();

                if (Std.is(element, RenderableSprite)) {
                    _v1 = element;
                    _v1.x *= _svgWidthHalf; _v1.y *= -_svgHeightHalf;

                    renderSprite(_v1, element, material);
                } else if (Std.is(element, RenderableLine)) {
                    _v1 = element.v1; _v2 = element.v2;

                    _v1.positionScreen.x *= _svgWidthHalf; _v1.positionScreen.y *= -_svgHeightHalf;
                    _v2.positionScreen.x *= _svgWidthHalf; _v2.positionScreen.y *= -_svgHeightHalf;

                    _elemBox.setFromPoints([_v1.positionScreen, _v2.positionScreen]);

                    if (_clipBox.intersectsBox(_elemBox)) {
                        renderLine(_v1, _v2, material);
                    }
                } else if (Std.is(element, RenderableFace)) {
                    _v1 = element.v1; _v2 = element.v2; _v3 = element.v3;

                    if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) continue;
                    if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) continue;
                    if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) continue;

                    _v1.positionScreen.x *= _svgWidthHalf; _v1.positionScreen.y *= -_svgHeightHalf;
                    _v2.positionScreen.x *= _svgWidthHalf; _v2.positionScreen.y *= -_svgHeightHalf;
                    _v3.positionScreen.x *= _svgWidthHalf; _v3.positionScreen.y *= -_svgHeightHalf;

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
                if (object.isSVGObject) {
                    _vector3.setFromMatrixPosition(object.matrixWorld).applyMatrix4(_viewProjectionMatrix);

                    if (_vector3.z < -1 || _vector3.z > 1) return;

                    var x = _vector3.x * _svgWidthHalf;
                    var y = -_vector3.y * _svgHeightHalf;

                    var node = object.node;
                    node.setAttribute('transform', 'translate(' + x + ',' + y + ')');

                    _svg.appendChild(node);
                }
            });
        };

        function calculateLights(lights:Array<Dynamic>) {
            _ambientLight.setRGB(0, 0, 0);
            _directionalLights.setRGB(0, 0, 0);
            _pointLights.setRGB(0, 0, 0);

            for (l in lights) {
                var light = l;
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

        function calculateLight(lights:Array<Dynamic>, position:Vector3, normal:Vector3, color:Color) {
            for (l in lights) {
                var light = l;
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

        function renderSprite(v1:Vector3, element:Dynamic, material:Dynamic) {
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

        function renderLine(v1:Vector3, v2:Vector3, material:Dynamic) {
            var path = 'M' + convert(v1.x) + ',' + convert(v1.y) + 'L' + convert(v2.x) + ',' + convert(v2.y);

            if (material.isLineBasicMaterial) {
                var style = 'fill:none;stroke:' + material.color.getStyle(outputColorSpace) + ';stroke-opacity:' + material.opacity + ';stroke-width:' + material.linewidth + ';stroke-linecap:' + material.linecap;

                if (material.isLineDashedMaterial) {
                    style += ';stroke-dasharray:' + material.dashSize + ',' + material.gapSize;
                }

                addPath(style, path);
            }
        }

        function renderFace3(v1:Vector3, v2:Vector3, v3:Vector3, element:Dynamic, material:Dynamic) {
            info.render.vertices += 3;
            info.render.faces++;

            var path = 'M' + convert(v1.x) + ',' + convert(v1.y) + 'L' + convert(v2.x) + ',' + convert(v2.y) + 'L' + convert(v3.x) + ',' + convert(v3.y) + 'z';
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

                _centroid.copy(v1).add(v2).add(v3).divideScalar(3);

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
        function expand(v1:Vector3, v2:Vector3, pixels:Float) {
            var x = v2.x - v1.x, y = v2.y - v1.y;
            var det = x * x + y * y;

            if (det == 0) return;

            var idet = pixels / Math.sqrt(det);

            x *= idet; y *= idet;

            v2.x += x; v2.y += y;
            v1.x -= x; v1.y -= y;
        }

        function addPath(style:String, path:String) {
            if (_currentStyle == style) {
                _currentPath += path;
            } else {
                flushPath();

                _currentStyle = style;
                _currentPath = path;
            }
        }

        function flushPath() {
            if (_currentPath != '') {
                _svgNode = getPathNode(_pathCount++);
                _svgNode.setAttribute('d', _currentPath);
                _svgNode.setAttribute('style', _currentStyle);
                _svg.appendChild(_svgNode);

                _currentPath = '';
                _currentStyle = '';
            }
        }

        function getPathNode(id:Int) {
            if (_svgPathPool[id] == null) {
                _svgPathPool[id] = Lib.document.createElementNS('http://www.w3.org/2000/svg', 'path');

                if (_quality == 0) {
                    _svgPathPool[id].setAttribute('shape-rendering', 'crispEdges'); //optimizeSpeed
                }

                return _svgPathPool[id];
            }

            return _svgPathPool[id];
        }
    }
}