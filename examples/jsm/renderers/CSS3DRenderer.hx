package three.js.examples.jsm.renderers;

import three.Matrix4;
import three.Object3D;
import three.Quaternion;
import three.Vector3;

class CSS3DObject extends Object3D {
    public var isCSS3DObject:Bool = true;
    public var element:js.html.Element;

    public function new(element:js.html.Element = js.Browser.document.createElement('div')) {
        super();
        this.element = element;
        this.element.style.position = 'absolute';
        this.element.style.pointerEvents = 'auto';
        this.element.style.userSelect = 'none';
        this.element.setAttribute('draggable', 'false');

        this.addEventListener('removed', function() {
            this.traverse(function(object:Object3D) {
                if (object.element != null && object.element.parentNode != null) {
                    object.element.parentNode.removeChild(object.element);
                }
            });
        });
    }

    override public function copy(source:Object3D, recursive:Bool = true):Object3D {
        super.copy(source, recursive);
        this.element = source.element.cloneNode(true);
        return this;
    }
}

class CSS3DSprite extends CSS3DObject {
    public var isCSS3DSprite:Bool = true;
    public var rotation2D:Float = 0.0;

    public function new(element:js.html.Element) {
        super(element);
    }

    override public function copy(source:Object3D, recursive:Bool = true):Object3D {
        super.copy(source, recursive);
        this.rotation2D = source.rotation2D;
        return this;
    }
}

class CSS3DRenderer {
    private var _width:Float;
    private var _height:Float;
    private var _widthHalf:Float;
    private var _heightHalf:Float;
    private var cache:Dynamic = {
        camera: { style: '' },
        objects: new WeakMap()
    };
    private var domElement:js.html.Element;
    private var viewElement:js.html.Element;
    private var cameraElement:js.html.Element;

    public function new(parameters:Dynamic = {}) {
        var _this:CSS3DRenderer = this;
        var domElement:js.html.Element = parameters.element != null ? parameters.element : js.Browser.document.createElement('div');
        domElement.style.overflow = 'hidden';

        this.domElement = domElement;

        viewElement = js.Browser.document.createElement('div');
        viewElement.style.transformOrigin = '0 0';
        viewElement.style.pointerEvents = 'none';
        domElement.appendChild(viewElement);

        cameraElement = js.Browser.document.createElement('div');
        cameraElement.style.transformStyle = 'preserve-3d';
        viewElement.appendChild(cameraElement);

        this.getSize = function():{ width:Float, height:Float } {
            return { width: _width, height: _height };
        };

        this.render = function(scene:Object3D, camera:Object3D) {
            var fov:Float = camera.projectionMatrix.elements[5] * _heightHalf;

            if (camera.view != null && camera.view.enabled) {
                viewElement.style.transform = 'translate(' + -camera.view.offsetX * (_width / camera.view.width) + 'px, ' + -camera.view.offsetY * (_height / camera.view.height) + 'px)';
                viewElement.style.transform += ' scale(' + camera.view.fullWidth / camera.view.width + ', ' + camera.view.fullHeight / camera.view.height + ')';
            } else {
                viewElement.style.transform = '';
            }

            if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
            if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();

            var tx:Float, ty:Float;

            if (camera.isOrthographicCamera) {
                tx = -(camera.right + camera.left) / 2;
                ty = (camera.top + camera.bottom) / 2;
            }

            var scaleByViewOffset:Float = camera.view != null && camera.view.enabled ? camera.view.height / camera.view.fullHeight : 1;
            var cameraCSSMatrix:String = camera.isOrthographicCamera ?
                'scale(' + scaleByViewOffset + ')' + 'scale(' + fov + ')' + 'translate(' + epsilon(tx) + 'px,' + epsilon(ty) + 'px)' + getCameraCSSMatrix(camera.matrixWorldInverse) :
                'scale(' + scaleByViewOffset + ')' + 'translateZ(' + fov + 'px)' + getCameraCSSMatrix(camera.matrixWorldInverse);
            var perspective:String = camera.isPerspectiveCamera ? 'perspective(' + fov + 'px) ' : '';

            var style:String = perspective + cameraCSSMatrix + 'translate(' + _widthHalf + 'px,' + _heightHalf + 'px)';
            if (cache.camera.style != style) {
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

            domElement.style.width = width + 'px';
            domElement.style.height = height + 'px';

            viewElement.style.width = width + 'px';
            viewElement.style.height = height + 'px';

            cameraElement.style.width = width + 'px';
            cameraElement.style.height = height + 'px';
        };

        function epsilon(value:Float):Float {
            return Math.abs(value) < 1e-10 ? 0 : value;
        }

        function getCameraCSSMatrix(matrix:Matrix4):String {
            var elements:Array<Float> = matrix.elements;

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

        function getObjectCSSMatrix(matrix:Matrix4):String {
            var elements:Array<Float> = matrix.elements;
            var matrix3d:String = 'matrix3d(' +
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

        function hideObject(object:Object3D) {
            if (object.isCSS3DObject) object.element.style.display = 'none';

            for (i in 0...object.children.length) {
                hideObject(object.children[i]);
            }
        }

        function renderObject(object:Object3D, scene:Object3D, camera:Object3D, cameraCSSMatrix:String) {
            if (!object.visible) {
                hideObject(object);
                return;
            }

            if (object.isCSS3DObject) {
                var visible:Bool = object.layers.test(camera.layers);
                var element:js.html.Element = object.element;
                element.style.display = visible ? '' : 'none';

                if (visible) {
                    object.onBeforeRender(_this, scene, camera);

                    var style:String;

                    if (object.isCSS3DSprite) {
                        var matrix:Matrix4 = new Matrix4();
                        matrix.copy(camera.matrixWorldInverse);
                        matrix.transpose();

                        if (object.rotation2D != 0) matrix.multiply(new Matrix4().makeRotationZ(object.rotation2D));

                        object.matrixWorld.decompose(_position, _quaternion, _scale);
                        matrix.setPosition(_position);
                        matrix.scale(_scale);

                        matrix.elements[3] = 0;
                        matrix.elements[7] = 0;
                        matrix.elements[11] = 0;
                        matrix.elements[15] = 1;

                        style = getObjectCSSMatrix(matrix);
                    } else {
                        style = getObjectCSSMatrix(object.matrixWorld);
                    }

                    var cachedObject:Dynamic = cache.objects.get(object);

                    if (cachedObject == null || cachedObject.style != style) {
                        element.style.transform = style;

                        var objectData:Dynamic = { style: style };
                        cache.objects.set(object, objectData);
                    }

                    if (element.parentNode != cameraElement) {
                        cameraElement.appendChild(element);
                    }

                    object.onAfterRender(_this, scene, camera);
                }
            }

            for (i in 0...object.children.length) {
                renderObject(object.children[i], scene, camera, cameraCSSMatrix);
            }
        }
    }
}