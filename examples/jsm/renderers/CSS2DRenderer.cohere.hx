package;

import js.Browser.Document;
import js.Browser.Element;
import js.Browser.HTMLElement;
import js.Browser.Window;
import js.three.Matrix4;
import js.three.Object3D;
import js.three.Vector2;
import js.three.Vector3;

class CSS2DObject extends Object3D {
    public var isCSS2DObject:Bool;
    public var element:HTMLElement;
    public var center:Vector2;

    public function new(?element:HTMLElement) {
        super();
        isCSS2DObject = true;
        if (element == null) {
            element = Document.createElement('div');
        }
        this.element = element;
        element.style.position = 'absolute';
        element.style.userSelect = 'none';
        element.setAttribute('draggable', false);
        center = new Vector2(0.5, 0.5);
    }

    public function addEventListener(type:String, listener:Void->Dynamic) {
        #if js
        this.element.addEventListener(type, listener);
        #end
    }

    public function copy(?source:CSS2DObject, ?recursive:Bool) {
        super.copy(source, recursive);
        if (source != null) {
            element = source.element.cloneNode(true);
            center = source.center;
        }
        return this;
    }
}

class CSS2DRenderer {
    private var _width:Int;
    private var _height:Int;
    private var _widthHalf:Int;
    private var _heightHalf:Int;
    private var cache:HashMap<Object3D, { distanceToCameraSquared:Float }>;
    private var domElement:HTMLElement;

    public function new(?parameters:HashMap<String, Dynamic>) {
        var _this = this;
        cache = HashMap();
        domElement = parameters.element as HTMLElement;
        if (domElement == null) {
            domElement = Document.createElement('div');
        }
        domElement.style.overflow = 'hidden';

        function getSize():HashMap<String, Int> {
            return { 'width' : _width, 'height' : _height };
        }

        function render(scene:Object3D, camera:Object3D) {
            if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
            if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

            var _viewMatrix = camera.matrixWorldInverse.clone();
            var _viewProjectionMatrix = camera.projectionMatrix.clone();
            _viewProjectionMatrix.multiply(_viewMatrix);

            renderObject(scene, scene, camera);
            zOrder(scene);
        }

        function setSize(width:Int, height:Int) {
            _width = width;
            _height = height;
            _widthHalf = _width / 2;
            _heightHalf = _height / 2;
            domElement.style.width = _width + 'px';
            domElement.style.height = _height + 'px';
        }

        function hideObject(object:Object3D) {
            if (object is CSS2DObject) {
                object.element.style.display = 'none';
            }
            for (child in object.children) {
                hideObject(child);
            }
        }

        function renderObject(object:Object3D, scene:Object3D, camera:Object3D) {
            if (!object.visible) {
                hideObject(object);
                return;
            }

            if (object is CSS2DObject) {
                var _vector = new Vector3();
                _vector.setFromMatrixPosition(object.matrixWorld);
                _vector.applyMatrix4(_viewProjectionMatrix);

                var visible = (_vector.z >= -1 && _vector.z <= 1) && object.layers.test(camera.layers);

                var element = object.element;
                element.style.display = visible ? '' : 'none';

                if (visible) {
                    object.onBeforeRender(_this, scene, camera);

                    element.style.transform = 'translate(' + (-100 * object.center.x) + '%,' + (-100 * object.center.y) + '%)' + 'translate(' + (_vector.x * _widthHalf + _widthHalf) + 'px,' + (-_vector.y * _heightHalf + _heightHalf) + 'px)';

                    if (element.parentNode != domElement) {
                        domElement.appendChild(element);
                    }

                    object.onAfterRender(_this, scene, camera);
                }

                cache.set(object, { 'distanceToCameraSquared' : getDistanceToSquared(camera, object) });
            }

            for (child in object.children) {
                renderObject(child, scene, camera);
            }
        }

        function getDistanceToSquared(object1:Object3D, object2:Object3D):Float {
            var _a = new Vector3();
            var _b = new Vector3();
            _a.setFromMatrixPosition(object1.matrixWorld);
            _b.setFromMatrixPosition(object2.matrixWorld);
            return _a.distanceToSquared(_b);
        }

        function filterAndFlatten(scene:Object3D):Array<Object3D> {
            var result = [];
            scene.traverseVisible(function (object) {
                if (object is CSS2DObject) result.push(object);
            });
            return result;
        }

        function zOrder(scene:Object3D) {
            var sorted = filterAndFlatten(scene).sort(function (a, b) {
                if (a.renderOrder != b.renderOrder) {
                    return b.renderOrder - a.renderOrder;
                }
                var distanceA = cache.get(a).distanceToCameraSquared;
                var distanceB = cache.get(b).distanceToCameraSquared;
                return distanceA - distanceB;
            });

            var zMax = sorted.length;
            for (i in 0...sorted.length) {
                sorted[i].element.style.zIndex = zMax - i;
            }
        }

        this.getSize = getSize;
        this.render = render;
        this.setSize = setSize;
    }
}

class Exports {
    static function get CSS2DObject() return CSS2DObject;
    static function get CSS2DRenderer() return CSS2DRenderer;
}