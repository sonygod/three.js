import three.Matrix4;
import three.Object3D;
import three.Vector2;
import three.Vector3;

class CSS2DObject extends Object3D {

    public var element:DomElement;
    public var center:Vector2;

    public function new(element:DomElement = null) {
        super();

        this.isCSS2DObject = true;

        if (element == null) {
            this.element = new DomElement("div");
        } else {
            this.element = element;
        }

        this.element.style.setProperty("position", "absolute");
        this.element.style.setProperty("userSelect", "none");

        this.element.setAttribute("draggable", false);

        this.center = new Vector2(0.5, 0.5);

        this.addEventListener("removed", function() {
            this.traverse(function(object:CSS2DObject) {
                if (Std.is(object.element, DomElement) && object.element.parentNode != null) {
                    object.element.parentNode.removeChild(object.element);
                }
            });
        });
    }

    @override
    public function copy(source:CSS2DObject, recursive:Bool):this {
        super.copy(source, recursive);

        this.element = source.element.cloneNode(true);
        this.center = source.center;

        return this;
    }
}

var _vector:Vector3 = new Vector3();
var _viewMatrix:Matrix4 = new Matrix4();
var _viewProjectionMatrix:Matrix4 = new Matrix4();
var _a:Vector3 = new Vector3();
var _b:Vector3 = new Vector3();

class CSS2DRenderer {

    private var _width:Int;
    private var _height:Int;
    private var _widthHalf:Int;
    private var _heightHalf:Int;
    private var cache:Dynamic;
    public var domElement:DomElement;

    public function new(parameters:Dynamic = null) {
        if (parameters == null) parameters = {};

        this.cache = { objects: new haxe.ds.WeakMap<CSS2DObject, Dynamic>() };

        if (parameters.element != null) {
            this.domElement = parameters.element;
        } else {
            this.domElement = new DomElement("div");
        }

        this.domElement.style.setProperty("overflow", "hidden");
    }

    public function getSize():Dynamic {
        return { width: this._width, height: this._height };
    }

    public function render(scene:Object3D, camera:Camera) {
        if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
        if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

        _viewMatrix.copy(camera.matrixWorldInverse);
        _viewProjectionMatrix.multiplyMatrices(camera.projectionMatrix, _viewMatrix);

        this.renderObject(scene, scene, camera);
        this.zOrder(scene);
    }

    public function setSize(width:Int, height:Int) {
        this._width = width;
        this._height = height;

        this._widthHalf = this._width / 2;
        this._heightHalf = this._height / 2;

        this.domElement.style.setProperty("width", width + "px");
        this.domElement.style.setProperty("height", height + "px");
    }

    private function hideObject(object:Object3D) {
        if (object.isCSS2DObject) object.element.style.setProperty("display", "none");

        for (object in object.children) {
            this.hideObject(object);
        }
    }

    private function renderObject(object:CSS2DObject, scene:Object3D, camera:Camera) {
        if (!object.visible) {
            this.hideObject(object);
            return;
        }

        if (object.isCSS2DObject) {
            _vector.setFromMatrixPosition(object.matrixWorld);
            _vector.applyMatrix4(_viewProjectionMatrix);

            var visible:Bool = (_vector.z >= -1 && _vector.z <= 1) && (object.layers.test(camera.layers));

            var element:DomElement = object.element;
            element.style.setProperty("display", visible ? "" : "none");

            if (visible) {
                object.onBeforeRender(this, scene, camera);

                var transform:String = "translate(" + (-100 * object.center.x) + "%," + (-100 * object.center.y) + "%)";
                transform += "translate(" + (_vector.x * this._widthHalf + this._widthHalf) + "px," + (-_vector.y * this._heightHalf + this._heightHalf) + "px)";
                element.style.setProperty("transform", transform);

                if (element.parentNode != this.domElement) {
                    this.domElement.appendChild(element);
                }

                object.onAfterRender(this, scene, camera);
            }

            var objectData:Dynamic = {
                distanceToCameraSquared: this.getDistanceToSquared(camera, object)
            };

            this.cache.objects.set(object, objectData);
        }

        for (object in object.children) {
            this.renderObject(object, scene, camera);
        }
    }

    private function getDistanceToSquared(object1:Object3D, object2:Object3D):Float {
        _a.setFromMatrixPosition(object1.matrixWorld);
        _b.setFromMatrixPosition(object2.matrixWorld);

        return _a.distanceToSquared(_b);
    }

    private function filterAndFlatten(scene:Object3D):Array<CSS2DObject> {
        var result:Array<CSS2DObject> = [];

        scene.traverseVisible(function(object:CSS2DObject) {
            if (object.isCSS2DObject) result.push(object);
        });

        return result;
    }

    private function zOrder(scene:Object3D) {
        var sorted:Array<CSS2DObject> = this.filterAndFlatten(scene).sort(function(a:CSS2DObject, b:CSS2DObject) {
            if (a.renderOrder != b.renderOrder) {
                return b.renderOrder - a.renderOrder;
            }

            var distanceA:Float = a.cache.objects.get(a).distanceToCameraSquared;
            var distanceB:Float = b.cache.objects.get(b).distanceToCameraSquared;

            return distanceA - distanceB;
        });

        var zMax:Int = sorted.length;

        for (i in 0...sorted.length) {
            sorted[i].element.style.setProperty("zIndex", (zMax - i).toString());
        }
    }
}