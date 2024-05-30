import js.Browser.window;
import js.html.Document;
import js.html.Element;
import js.html.HTMLElement;
import js.html.SVGElement;
import js.html.SVGPathElement;

class SVGObject extends js.three.Object3D {
    public isSVGObject:Bool;
    public node:SVGElement;

    public function new(node:SVGElement) {
        super();
        this.isSVGObject = true;
        this.node = node;
    }
}

class SVGRenderer {
    private _renderData:js.three.RenderData;
    private _elements:Array<js.three.Renderable>;
    private _lights:Array<js.three.Light>;
    private _svgWidth:Int;
    private _svgHeight:Int;
    private _svgWidthHalf:Float;
    private _svgHeightHalf:Float;
    private _v1:js.three.Vector3;
    private _v2:js.three.Vector3;
    private _v3:js.three.Vector3;
    private _svgNode:SVGPathElement;
    private _pathCount:Int;
    private _precision:Null<Float>;
    private _quality:Int;
    private _currentPath:String;
    private _currentStyle:String;
    private _this:SVGRenderer;
    private _clipBox:js.three.Box2;
    private _elemBox:js.three.Box2;
    private _color:js.three.Color;
    private _diffuseColor:js.three.Color;
    private _ambientLight:js.three.Color;
    private _directionalLights:js.three.Color;
    private _pointLights:js.three.Color;
    private _clearColor:js.three.Color;
    private _vector3:js.three.Vector3;
    private _centroid:js.three.Vector3;
    private _normal:js.three.Vector3;
    private _normalViewMatrix:js.three.Matrix3;
    private _viewMatrix:js.three.Matrix4;
    private _viewProjectionMatrix:js.three.Matrix4;
    private _svgPathPool:Array<SVGPathElement>;
    private _projector:js.three.Projector;
    private _svg:SVGElement;
    public domElement:SVGElement;
    public autoClear:Bool;
    public sortObjects:Bool;
    public sortElements:Bool;
    public overdraw:Float;
    public outputColorSpace:js.three.ColorSpace;
    public info:Dynamic;

    public function new() {
        _renderData = null;
        _elements = [];
        _lights = [];
        _svgWidth = 0;
        _svgHeight = 0;
        _svgWidthHalf = 0.0;
        _svgHeightHalf = 0.0;
        _v1 = new js.three.Vector3();
        _v2 = new js.three.Vector3();
        _v3 = new js.three.Vector3();
        _svgNode = null;
        _pathCount = 0;
        _precision = null;
        _quality = 1;
        _currentPath = "";
        _currentStyle = "";
        _this = this;
        _clipBox = new js.three.Box2();
        _elemBox = new js.three.Box2();
        _color = new js.three.Color();
        _diffuseColor = new js.three.Color();
        _ambientLight = new js.three.Color();
        _directionalLights = new js.three.Color();
        _pointLights = new js.three.Color();
        _clearColor = new js.three.Color();
        _vector3 = new js.three.Vector3();
        _centroid = new js.three.Vector3();
        _normal = new js.three.Vector3();
        _normalViewMatrix = new js.three.Matrix3();
        _viewMatrix = new js.three.Matrix4();
        _viewProjectionMatrix = new js.three.Matrix4();
        _svgPathPool = [];
        _projector = new js.three.Projector();
        _svg = window.document.createElementNS("http://www.w3.org/2000/svg", "svg");
        domElement = _svg;
        autoClear = true;
        sortObjects = true;
        sortElements = true;
        overdraw = 0.5;
        outputColorSpace = js.three.SRGBColorSpace;
        info = {
            render: {
                vertices: 0,
                faces: 0
            }
        };
    }

    public function setQuality(quality:String):Void {
        switch (quality) {
            case "high":
                _quality = 1;
                break;
            case "low":
                _quality = 0;
                break;
        }
    }

    public function setClearColor(color:js.three.Color):Void {
        _clearColor.copy(color);
    }

    public function setPixelRatio():Void {
        // TODO: Implement setPixelRatio
    }

    public function setSize(width:Int, height:Int):Void {
        _svgWidth = width;
        _svgHeight = height;
        _svgWidthHalf = _svgWidth / 2.0;
        _svgHeightHalf = _svgHeight / 2.0;
        _svg.setAttribute("viewBox", "-" + _svgWidthHalf + " " + "-" + _svgHeightHalf + " " + _svgWidth + " " + _svgHeight);
        _svg.setAttribute("width", Std.string(_svgWidth));
        _svg.setAttribute("height", Std.string(_svgHeight));
        _clipBox.min.set(-_svgWidthHalf, -_svgHeightHalf);
        _clipBox.max.set(_svgWidthHalf, _svgHeightHalf);
    }

    public function getSize():Dynamic {
        return { width: _svgWidth, height: _svgHeight };
    }

    public function setPrecision(precision:Float):Void {
        _precision = precision;
    }

    private function removeChildNodes():Void {
        _pathCount = 0;
        while (_svg.childNodes.length > 0) {
            _svg.removeChild(_svg.childNodes[0]);
        }
    }

    private function convert(c:Float):String {
        return _precision != null ? Std.string(c.toFixed(_precision)) : Std.string(c);
    }

    public function clear():Void {
        removeChildNodes();
        _svg.style.backgroundColor = _clearColor.getStyle(outputColorSpace);
    }

    public function render(scene:js.three.Scene, camera:js.three.Camera):Void {
        if (!Std.is(camera, js.three.Camera)) {
            throw "THREE.SVGRenderer.render: camera is not an instance of Camera.";
        }

        var background = scene.background;

        if (background != null && background.isColor) {
            removeChildNodes();
            _svg.style.backgroundColor = background.getStyle(outputColorSpace);
        } else if (autoClear) {
            clear();
        }

        _this.info.render.vertices = 0;
        _this.info.render.faces = 0;

        _viewMatrix.copy(camera.matrixWorldInverse);
        _viewProjectionMatrix.multiply(_viewMatrix, camera.projectionMatrix);

        _renderData = _projector.projectScene(scene, camera, sortObjects, sortElements);
        _elements = _renderData.elements;
        _lights = _renderData.lights;

        _normalViewMatrix.getNormalMatrix(camera.matrixWorldInverse);

        calculateLights(_lights);

        _currentPath = "";
        _currentStyle = "";

        for (e in 0..._elements.length) {
            var element = _elements[e];
            var material = element.material;

            if (material == null || material.opacity == 0) {
                continue;
            }

            _elemBox.makeEmpty();

            if (Std.is(element, js.three.RenderableSprite)) {
                _v1 = element;
                _v1.x *= _svgWidthHalf;
                _v1.y *= -_svgHeightHalf;
                renderSprite(_v1, element, material);
            } else if (Std.is(element, js.three.RenderableLine)) {
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
            } else if (Std.is(element, js.three.RenderableFace)) {
                _v1 = element.v1;
                _v2 = element.v2;
                _v3 = element.v3;

                if (_v1.positionScreen.z < -1 || _v1.positionScreen.z > 1) {
                    continue;
                }
                if (_v2.positionScreen.z < -1 || _v2.positionScreen.z > 1) {
                    continue;
                }
                if (_v3.positionScreen.z < -1 || _v3.positionScreen.z > 1) {
                    continue;
                }

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

        flushPath();

        scene.traverseVisible(function (object) {
            if (Std.is(object, SVGObject)) {
                _vector3.setFromMatrixPosition(object.matrixWorld);
                _vector3.applyMatrix4(_viewProjectionMatrix);

                if (_vector3.z < -1 || _vector3.z > 1) {
                    return;
                }

                var x = _vector3.x * _svgWidthHalf;
                var y = -_vector3.y * _svgHeightHalf;

                var node = object.node;
                node.setAttribute("transform", "translate(" + x + "," + y + ")");

                _svg.appendChild(node);
            }
        });
    }

    private function calculateLights(lights:Array<js.three.Light>):Void {
        _ambientLight.setRGB(0, 0, 0);
        _directionalLights.setRGB(0, 0, 0);
        _pointLights.setRGB(0, 0, 0);

        for (l in 0...lights.length) {
            var light = lights[l];
            var lightColor = light.color;

            if (Std.is(light, js.three.AmbientLight)) {
                _ambientLight.r += lightColor.r;
                _ambientLight.g += lightColor.g;
                _ambientLight.b += lightColor.b;
            } else if (Std.is(light, js.three.DirectionalLight)) {
                _directionalLights.r += lightColor.r;
                _directionalLights.g += lightColor.g;
                _directionalLights.b += lightColor.b;
            } else if (Std.is(light, js.three.PointLight)) {
                _pointLights.r += lightColor.r;
                _pointLights.g += lightColor.g;
                _pointLights.b += lightColor.b;
            }
        }
    }

    private function calculateLight(lights:Array<js.three.Light>, position:js.three.Vector3, normal:js.three.Vector3, color:js.three.Color):Void {
        for (l in 0...lights.length) {
            var light = lights[l];
            var lightColor = light.color;

            if (Std.is(light, js.three.DirectionalLight)) {
                var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld).normalize();
                var amount = normal.dot(lightPosition);

                if (amount <= 0) {
                    continue;
                }

                amount *= light.intensity;

                color.r += lightColor.r * amount;
                color.g += lightColor.g * amount;
                color.b += lightColor.b * amount;
            } else if (Std.is(light, js.three.PointLight)) {
                var lightPosition = _vector3.setFromMatrixPosition(light.matrixWorld);
                var amount = normal.dot(_vector3.sub(lightPosition, position).normalize());

                if (amount <= 0) {
                    continue;
                }

                amount *= light.distance == 0 ? 1 : 1 - Math.min(position.distanceTo(lightPosition) / light.distance, 1);

                if (amount == 0) {
                    continue;
                }

                amount *= light.intensity;

                color.r += lightColor.r * amount;
                color.g += lightColor.g * amount;
                color.b += lightColor.b * amount;
            }
        }
    }

    private function renderSprite(v1:js.three.Vector3, element:js.three.RenderableSprite, material:js.three.Material):Void {
        var scaleX = element.scale.x * _svgWidthHalf;
        var scaleY = element.scale.y * _svgHeightHalf;

        if (Std.is(material, js.three.PointsMaterial)) {
            scaleX *= material.size;
            scaleY *= material.size;
        }

        var path = "M" + convert(v1.x - scaleX * 0.5) + "," + convert(v1.y - scaleY * 0.5) + "h" + convert(scaleX) + "v" + convert(scaleY) + "h" + convert(-scaleX) + "z";
        var style = "";

        if (Std.is(material, js.three.SpriteMaterial) || Std.is(material, js.three.PointsMaterial)) {
            style = "fill:" + material.color.getStyle(outputColorSpace) + ";fill-opacity:" + material.opacity;
        }

        addPath(style, path);
    }

    private function renderLine(v1:js.three.Vector3, v2:js.three.Vector3, material:js.three.Material):Void {
        var path = "M" + convert(v1.positionScreen.x) + "," + convert(v1.positionScreen.y) + "L" + convert(v2.positionScreen.x) + "," + convert(v2.positionScreen.y);

        if (Std.is(material, js.three.LineBasicMaterial)) {
            var style = "fill:none;stroke:" + material.color.getStyle(outputColorSpace) + ";stroke-opacity:" + material.opacity + ";stroke-width:" + material.linewidth + ";stroke-linecap:" + material.linecap;

            if (Std.is(material, js.three.LineDashedMaterial)) {
                style += ";stroke-dasharray:" + material.dashSize + "," + material.gapSize;
            }

            addPath(style, path);
        }
    }

    private function renderFace3(v1:js.three.Vector3, v2:js.three.Vector3, v3:js.three.Vector3, element:js.three.RenderableFace, material:js.three.Material):Void {
        _this.info.render.vertices += 3;
        _this.info.render.faces++;

        var path = "M" + convert(v1.positionScreen.x) + "," + convert(v1.positionScreen.y) + "L" + convert(v2.positionScreen.x) + "," + convert(v2.positionScreen.y) + "L" + convert(v3.positionScreen.x) + "," + convert(v3.positionScreen.y) + "z";
        var style = "";

        if (Std.is(material, js.three.MeshBasicMaterial)) {
            _color.copy(material.color);

            if (material.vertexColors) {
                _color.multiply(element.color);
            }
        } else if (Std.is(material, js.three.MeshLambertMaterial) || Std.is(material, js.three.MeshPhongMaterial) || Std.is(material, js.three.MeshStandardMaterial)) {
            _diffuseColor.copy(material.color);

            if (material.vertexColors) {
                _diffuseColor.multiply(element.color);
            }

            _color.copy(_ambientLight);

            _centroid.copy(v1.positionWorld).add(v2.positionWorld).add(v3.positionWorld).divideScalar(3);

            calculateLight(_lights, _centroid, element.normalModel, _color);

            _color.multiply(_diffuseColor).add(material.emissive);
        } else if (Std.is(material, js.three.MeshNormalMaterial)) {
            _normal.
            copy(element.normalModel).applyMatrix3(_normalViewMatrix).normalize();

            _color.setRGB(_normal.x, _normal.y, _normal.z).multiplyScalar(0.5).addScalar(0.5);
        }

        if (material.wireframe) {
            style = "fill:none;stroke:" + _color.getStyle(outputColorSpace) + ";stroke-opacity:" + material.opacity + ";stroke-width:" + material.wireframeLinewidth + ";stroke-linecap:" + material.wireframeLinecap + ";stroke-linejoin:" + material.wireframeLinejoin;
        } else {
            style = "fill:" + _color.getStyle(outputColorSpace) + ";fill-opacity:" + material.opacity;
        }

        addPath(style, path);
    }

    // Hide anti-alias gaps

    private function expand(v1:js.three.Vector3, v2:js.three.Vector3, pixels:Float):Void {
        var x = v2.x - v1.x;
        var y = v2.y - v1.y;
        var det = x * x + y * y;

        if (det == 0) {
            return;
        }

        var idet = pixels / Math.sqrt(det);

        x *= idet;
        y *= idet;

        v2.x += x;
        v2.y += y;
        v1.x -= x;
        v1.y -= y;
    }

    private function addPath(style:String, path:String):Void {
        if (_currentStyle == style) {
            _currentPath += path;
        } else {
            flushPath();

            _currentStyle = style;
            _currentPath = path;
        }
    }

    private function flushPath():Void {
        if (_currentPath != "") {
            _svgNode = getPathNode(_pathCount++);
            _svgNode.setAttribute("d", _currentPath);
            _svgNode.setAttribute("style", _currentStyle);
            _svg.appendChild(_svgNode);
        }

        _currentPath = "";
        _currentStyle = "";
    }

    private function getPathNode(id:Int):SVGPathElement {
        if (_svgPathPool[id] == null) {
            _svgPathPool[id] = window.document.createElementNS("http://www.w3.org/2000/svg", "path");

            if (_quality == 0) {
                _svgPathPool[id].setAttribute("shape-rendering", "crispEdges"); //optimizeSpeed
            }

            return _svgPathPool[id];
        }

        return _svgPathPool[id];
    }
}

class SVGObjectExport {
    public static function SVGObject():SVGObject;
    public static function SVGRenderer():SVGRenderer;
}