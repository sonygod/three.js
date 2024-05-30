package;

import js.three.Matrix4;
import js.three.Object3D;
import js.three.Quaternion;
import js.three.Vector3;

class CSS3DObject extends Object3D {
    public var isCSS3DObject:Bool;
    public var element:Dynamic;

    public function new(element:Dynamic = cast js.Document.createElement('div', null)) {
        super();
        isCSS3DObject = true;
        this.element = element;
        element.style.position = 'absolute';
        element.style.pointerEvents = 'auto';
        element.style.userSelect = 'none';
        element.setAttribute('draggable', false);
        addEventListener('removed', function() {
            traverse(function(object:Object3D) {
                if (Std.is(object.element, Element) && object.element.parentNode != null) {
                    object.element.parentNode.removeChild(object.element);
                }
            });
        });
    }

    public function copy(source:Object3D, recursive:Bool) {
        super.copy(source, recursive);
        element = source.element.cloneNode(true);
        return this;
    }
}

class CSS3DSprite extends CSS3DObject {
    public var isCSS3DSprite:Bool;
    public var rotation2D:Float;

    public function new(element:Dynamic) {
        super(element);
        isCSS3DSprite = true;
        rotation2D = 0;
    }

    public function copy(source:Object3D, recursive:Bool) {
        super.copy(source, recursive);
        rotation2D = source.rotation2D;
        return this;
    }
}

class CSS3DRenderer {
    private var _this:CSS3DRenderer;
    private var _width:Int;
    private var _height:Int;
    private var _widthHalf:Int;
    private var _heightHalf:Int;
    private var cache:Dynamic;
    private var domElement:Dynamic;
    private var viewElement:Dynamic;
    private var cameraElement:Dynamic;

    public function new(parameters:Dynamic = {}) {
        _this = this;
        cache = {
            camera: { style: '' },
            objects: new WeakMap()
        };
        domElement = parameters.element != null ? parameters.element : cast js.Document.createElement('div', null);
        domElement.style.overflow = 'hidden';
        this.domElement = domElement;
        viewElement = cast js.Document.createElement('div', null);
        viewElement.style.transformOrigin = '0 0';
        viewElement.style.pointerEvents = 'none';
        domElement.appendChild(viewElement);
        cameraElement = cast js.Document.createElement('div', null);
        cameraElement.style.transformStyle = 'preserve-3d';
        viewElement.appendChild(cameraElement);

        function getSize():Dynamic {
            return { width: _width, height: _height };
        }

        function render(scene:Dynamic, camera:Dynamic) {
            var fov = camera.projectionMatrix.elements[5] * _heightHalf;
            if (camera.view != null && camera.view.enabled) {
                viewElement.style.transform = `translate( ${ - camera.view.offsetX * (_width / camera.view.width) }px, ${ - camera.view.offsetY * (_height / camera.view.height) }px )`;
                viewElement.style.transform += `scale( ${ camera.view.fullWidth / camera.view.width }, ${ camera.view.fullHeight / camera.view.height } )`;
            } else {
                viewElement.style.transform = '';
            }
            if (scene.matrixWorldAutoUpdate) scene.updateMatrixWorld();
            if (camera.parent == null && camera.matrixWorldAutoUpdate) camera.updateMatrixWorld();
            var tx:Float, ty:Float;
            if (camera.isOrthographicCamera) {
                tx = - (camera.right + camera.left) / 2;
                ty = (camera.top + camera.bottom) / 2;
            }
            var scaleByViewOffset = camera.view != null && camera.view.enabled ? camera.view.height / camera.view.fullHeight : 1;
            var cameraCSSMatrix = camera.isOrthographicCamera ?
                `scale( ${ scaleByViewOffset } )` + 'scale(' + fov + ')' + 'translate(' + epsilon(tx) + 'px,' + epsilon(ty) + 'px)' + getCameraCSSMatrix(camera.matrixWorldInverse) :
                `scale( ${ scaleByViewOffset } )` + 'translateZ(' + fov + 'px)' + getCameraCSSMatrix(camera.matrixWorldInverse);
            var perspective = camera.isPerspectiveCamera ? 'perspective(' + fov + 'px) ' : '';
            var style = perspective + cameraCSSMatrix +
                'translate(' + _widthHalf + 'px,' + _heightHalf + 'px)';
            if (cache.camera.style != style) {
                cameraElement.style.transform = style;
                cache.camera.style = style;
            }
            renderObject(scene, scene, camera, cameraCSSMatrix);
        }

        function setSize(width:Int, height:Int) {
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
        }

        function epsilon(value:Float):Float {
            return Math.abs(value) < 1e-10 ? 0 : value;
        }

        function getCameraCSSMatrix(matrix:Dynamic):String {
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

        function getObjectCSSMatrix(matrix:Dynamic):String {
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
                epsilon(-elements[13]) + ',' +
                epsilon(elements[14]) + ',' +
                epsilon(elements[15]) +
            ')';
            return 'translate(-50%,-50%)' + matrix3d;
        }

        function hideObject(object:Dynamic) {
            if (object.isCSS3DObject) object.element.style.display = 'none';
            for (i in 0...object.children.length) {
                hideObject(object.children[i]);
            }
        }

        function renderObject(object:Dynamic, scene:Dynamic, camera:Dynamic, cameraCSSMatrix:Dynamic) {
            if (object.visible == false) {
                hideObject(object);
                return;
            }
            if (object.isCSS3DObject) {
                var visible = object.layers.test(camera.layers);
                var element = object.element;
                element.style.display = visible ? '' : 'none';
                if (visible) {
                    object.onBeforeRender(_this, scene, camera);
                    var style:String;
                    if (object.isCSS3DSprite) {
                        _matrix.copy(camera.matrixWorldInverse);
                        _matrix.transpose();
                        if (object.rotation2D != 0) _matrix.multiply(_matrix2.makeRotationZ(object.rotation2D));
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
                    if (cachedObject == null || cachedObject.style != style) {
                        element.style.transform = style;
                        var objectData = { style: style };
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