package three.js.examples.jsm.renderers;

import three.Vector2;
import three.Vector3;
import three.Matrix4;
import three.Object3D;

class CSS2DObject extends Object3D {
    public var isCSS2DObject:Bool = true;
    public var element:HTMLElement;
    public var center:Vector2;

    public function new(element:HTMLElement = document.createElement('div')) {
        super();
        this.element = element;
        this.element.style.position = 'absolute';
        this.element.style.userSelect = 'none';
        this.element.setAttribute('draggable', 'false');
        this.center = new Vector2(0.5, 0.5);

        this.addEventListener('removed', function() {
            traverse(function(object) {
                if (object.element != null && object.element.parentNode != null) {
                    object.element.parentNode.removeChild(object.element);
                }
            });
        });
    }

    public function copy(source:CSS2DObject, recursive:Bool):CSS2DObject {
        super.copy(source, recursive);
        this.element = source.element.cloneNode(true);
        this.center = source.center;
        return this;
    }
}

class CSS2DRenderer {
    private var domElement:HTMLElement;
    private var cache:Map<CSS2DObject, { distanceToCameraSquared:Float }> = new Map();
    private var _vector:Vector3 = new Vector3();
    private var _viewMatrix:Matrix4 = new Matrix4();
    private var _viewProjectionMatrix:Matrix4 = new Matrix4();
    private var _a:Vector3 = new Vector3();
    private var _b:Vector3 = new Vector3();

    public function new(parameters:{ element:HTMLElement } = {}) {
        domElement = parameters.element != null ? parameters.element : document.createElement('div');
        domElement.style.overflow = 'hidden';
    }

    public function getSize():{ width:Int, height:Int } {
        return { width: _width, height: _height };
    }

    public function setSize(width:Int, height:Int) {
        _width = width;
        _height = height;
        _widthHalf = _width / 2;
        _heightHalf = _height / 2;
        domElement.style.width = '${width}px';
        domElement.style.height = '${height}px';
    }

    public function render(scene:Object3D, camera:Object3D) {
        if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
        if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
        _viewMatrix.copy(camera.matrixWorldInverse);
        _viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);
        renderObject(scene, scene, camera);
        zOrder(scene);
    }

    private function renderObject(object:Object3D, scene:Object3D, camera:Object3D) {
        if (!object.visible) {
            hideObject(object);
            return;
        }
        if (object.isCSS2DObject) {
            _vector.setFromMatrixPosition(object.matrixWorld);
            _vector.applyMatrix4(_viewProjectionMatrix);
            var visible = _vector.z >= -1 && _vector.z <= 1 && object.layers.test(camera.layers);
            var element:HTMLElement = object.element;
            element.style.display = visible ? '' : 'none';
            if (visible) {
                object.onBeforeRender(this, scene, camera);
                element.style.transform = 'translate(${(-100 * object.center.x)}%,${(-100 * object.center.y)}%) translate(${(_vector.x * _widthHalf + _widthHalf)}px,${(-_vector.y * _heightHalf + _heightHalf)}px)';
                if (element.parentNode != domElement) {
                    domElement.appendChild(element);
                }
                object.onAfterRender(this, scene, camera);
            }
            var objectData = { distanceToCameraSquared: getDistanceToSquared(camera, object) };
            cache.set(object, objectData);
        }
        for (i in 0...object.children.length) {
            renderObject(object.children[i], scene, camera);
        }
    }

    private function getDistanceToSquared(object1:Object3D, object2:Object3D) {
        _a.setFromMatrixPosition(object1.matrixWorld);
        _b.setFromMatrixPosition(object2.matrixWorld);
        return _a.distanceToSquared(_b);
    }

    private function filterAndFlatten(scene:Object3D):Array<CSS2DObject> {
        var result:Array<CSS2DObject> = [];
        scene.traverseVisible(function(object) {
            if (object.isCSS2DObject) result.push(object);
        });
        return result;
    }

    private function zOrder(scene:Object3D) {
        var sorted:Array<CSS2DObject> = filterAndFlatten(scene).sort(function(a, b) {
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

    private function hideObject(object:Object3D) {
        if (object.isCSS2DObject) object.element.style.display = 'none';
        for (i in 0...object.children.length) {
            hideObject(object.children[i]);
        }
    }
}