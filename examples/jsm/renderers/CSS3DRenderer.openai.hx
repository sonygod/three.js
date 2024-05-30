package three.renderers;

import three.math.Matrix4;
import three.math.Quaternion;
import three.math.Vector3;
import three.core.Object3D;

class CSS3DObject extends Object3D {
  public var element:js.html.Element;
  public var isCSS3DObject:Bool;

  public function new(element:js.html.Element = js.Browser.document.createElement('div')) {
    super();
    isCSS3DObject = true;
    this.element = element;
    element.style.position = 'absolute';
    element.style.pointerEvents = 'auto';
    element.style.userSelect = 'none';
    element.draggable = false;

   addEventListener('removed', function() {
      traverse(function(object) {
        if (object.element.parentNode != null) {
          object.element.parentNode.removeChild(object.element);
        }
      });
    });
  }

  override public function copy(source:Object3D, recursive:Bool):Object3D {
    super.copy(source, recursive);
    element = source.element.cloneNode(true);
    return this;
  }
}

class CSS3DSprite extends CSS3DObject {
  public var rotation2D:Float;

  public function new(element:js.html.Element) {
    super(element);
    isCSS3DSprite = true;
    rotation2D = 0;
  }

  override public function copy(source:Object3D, recursive:Bool):Object3D {
    super.copy(source, recursive);
    rotation2D = source.rotation2D;
    return this;
  }
}

class CSS3DRenderer {
  private var _matrix:Matrix4;
  private var _matrix2:Matrix4;
  private var _this:CSS3DRenderer;
  private var _width:Float;
  private var _height:Float;
  private var _widthHalf:Float;
  private var _heightHalf:Float;
  private var cache:{
    camera:{style:String},
    objects:WeakMap<Object3D, {style:String}>
  };
  private var domElement:js.html.Element;
  private var viewElement:js.html.Element;
  private var cameraElement:js.html.Element;

  public function new(?parameters:{element:js.html.Element}) {
    _this = this;
    _matrix = new Matrix4();
    _matrix2 = new Matrix4();
    cache = {
      camera: {style: ''},
      objects: new WeakMap()
    };
    domElement = if (parameters != null && parameters.element != null) parameters.element else js.Browser.document.createElement('div');
    domElement.style.overflow = 'hidden';
    viewElement = js.Browser.document.createElement('div');
    viewElement.style.transformOrigin = '0 0';
    viewElement.style.pointerEvents = 'none';
    domElement.appendChild(viewElement);
    cameraElement = js.Browser.document.createElement('div');
    cameraElement.style.transformStyle = 'preserve-3d';
    viewElement.appendChild(cameraElement);

    getSize = function():{width:Float, height:Float} {
      return {width: _width, height: _height};
    };

    render = function(scene:Object3D, camera:Object3D):Void {
      // ...
    };

    setSize = function(width:Float, height:Float):Void {
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
  }

  private function epsilon(value:Float):Float {
    return Math.abs(value) < 1e-10 ? 0 : value;
  }

  private function getCameraCSSMatrix(matrix:Matrix4):String {
    // ...
  }

  private function getObjectCSSMatrix(matrix:Matrix4):String {
    // ...
  }

  private function hideObject(object:Object3D):Void {
    if (object.isCSS3DObject) object.element.style.display = 'none';
    for (i in 0...object.children.length) {
      hideObject(object.children[i]);
    }
  }

  private function renderObject(object:Object3D, scene:Object3D, camera:Object3D, cameraCSSMatrix:String):Void {
    // ...
  }
}