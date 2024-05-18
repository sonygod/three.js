package three.js.examples.jm.renderers;

import three.Matrix4;
import three.Object3D;
import three.Vector2;
import three.Vector3;

class CSS2DObject extends Object3D {
    public var isCSS2DObject:Bool = true;
    public var element:js.html.Element;
    public var center:Vector2;

    public function new(element:js.html.Element = js.Browser.document.createElement("div")) {
        super();
        this.element = element;
        element.style.position = "absolute";
        element.style.userSelect = "none";
        element.setAttribute("draggable", "false");
        center = new Vector2(0.5, 0.5);
        addEventListener("removed", function() {
            traverse(function(object:Object3D) {
                if (object.element != null && object.element.parentNode != null) {
                    object.element.parentNode.removeChild(object.element);
                }
            });
        });
    }

    override public function copy(source:Object3D, recursive:Bool = true):Object3D {
        super.copy(source, recursive);
        element = source.element.cloneNode(true);
        center = source.center.clone();
        return this;
    }
}

class CSS2DRenderer {
    private var domElement:js.html.Element;
    private var cache:Dynamic = { objects: new WeakMap() };
    private var _vector:Vector3 = new Vector3();
    private var _viewMatrix:Matrix4 = new Matrix4();
    private var _viewProjectionMatrix:Matrix4 = new Matrix4();
    private var _a:Vector3 = new Vector3();
    private var _b:Vector3 = new Vector3();

    public function new(parameters:Dynamic = {}) {
        var _this:CSS2DRenderer = this;
        var _width:Float;
        var _height:Float;
        var _widthHalf:Float;
        var _heightHalf:Float;

        domElement = parameters.element != null ? parameters.element : js.Browser.document.createElement("div");
        domElement.style.overflow = "hidden";

        getSize = function():{ width:Float, height:Float } {
            return { width: _width, height: _height };
        };

        render = function(scene:Object3D, camera:Object3D) {
            if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
            if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
            _viewMatrix.copy(camera.matrixWorldInverse);
            _viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);
            renderObject(scene, scene, camera);
            zOrder(scene);
        };

        setSize = function(width:Float, height:Float) {
            _width = width;
            _height = height;
            _widthHalf = _width / 2;
            _heightHalf = _height / 2;
            domElement.style.width = width + "px";
            domElement.style.height = height + "px";
        };

        function hideObject(object:Object3D) {
            if (object.isCSS2DObject) object.element.style.display = "none";
            for (i in 0...object.children.length) {
                hideObject(object.children[i]);
            }
        }

        function renderObject(object:Object3D, scene:Object3D, camera:Object3D) {
            if (!object.visible) {
                hideObject(object);
                return;
            }
            if (object.isCSS2DObject) {
                _vector.setFromMatrixPosition(object.matrixWorld);
                _vector.applyMatrix4(_viewProjectionMatrix);
                var visible = (_vector.z >= -1 && _vector.z <= 1) && (object.layers.test(camera.layers));
                var element:js.html.Element = object.element;
                element.style.display = visible ? "" : "none";
                if (visible) {
                    object.onBeforeRender(_this, scene, camera);
                    element.style.transform = "translate(" + (-100 * object.center.x) + "%," + (-100 * object.center.y) + "%)" + "translate(" + (_vector.x * _widthHalf + _widthHalf) + "px," + (-_vector.y * _heightHalf + _heightHalf) + "px)";
                    if (element.parentNode != domElement) domElement.appendChild(element);
                    object.onAfterRender(_this, scene, camera);
                }
                var objectData = { distanceToCameraSquared: getDistanceToSquared(camera, object) };
                cache.objects.set(object, objectData);
            }
            for (i in 0...object.children.length) {
                renderObject(object.children[i], scene, camera);
            }
        }

        function getDistanceToSquared(object1:Object3D, object2:Object3D) {
            _a.setFromMatrixPosition(object1.matrixWorld);
            _b.setFromMatrixPosition(object2.matrixWorld);
            return _a.distanceToSquared(_b);
        }

        function filterAndFlatten(scene:Object3D) {
            var result:Array<Object3D> = [];
            scene.traverseVisible(function(object:Object3D) {
                if (object.isCSS2DObject) result.push(object);
            });
            return result;
        }

        function zOrder(scene:Object3D) {
            var sorted:Array<Object3D> = filterAndFlatten(scene).sort(function(a:Object3D, b:Object3D) {
                if (a.renderOrder != b.renderOrder) {
                    return b.renderOrder - a.renderOrder;
                }
                var distanceA:Float = cache.objects.get(a).distanceToCameraSquared;
                var distanceB:Float = cache.objects.get(b).distanceToCameraSquared;
                return distanceA - distanceB;
            });
            var zMax:Int = sorted.length;
            for (i in 0...sorted.length) {
                sorted[i].element.style.zIndex = zMax - i;
            }
        }
    }
}