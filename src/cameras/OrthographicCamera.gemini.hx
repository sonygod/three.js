import three.cameras.Camera;

class OrthographicCamera extends Camera {

  public var isOrthographicCamera:Bool = true;
  public var type:String = "OrthographicCamera";
  public var zoom:Float = 1;
  public var view:haxe.ds.WeakMap<String,Dynamic> = null;

  public var left:Float;
  public var right:Float;
  public var top:Float;
  public var bottom:Float;
  public var near:Float;
  public var far:Float;

  public function new(left:Float = -1, right:Float = 1, top:Float = 1, bottom:Float = -1, near:Float = 0.1, far:Float = 2000) {
    super();
    this.left = left;
    this.right = right;
    this.top = top;
    this.bottom = bottom;
    this.near = near;
    this.far = far;
    this.updateProjectionMatrix();
  }

  public function copy(source:OrthographicCamera, recursive:Bool = true):OrthographicCamera {
    super.copy(source, recursive);
    this.left = source.left;
    this.right = source.right;
    this.top = source.top;
    this.bottom = source.bottom;
    this.near = source.near;
    this.far = source.far;
    this.zoom = source.zoom;
    if (source.view != null) {
      this.view = new haxe.ds.WeakMap<String,Dynamic>();
      for (v in source.view.keys()) {
        this.view.set(v, source.view.get(v));
      }
    } else {
      this.view = null;
    }
    return this;
  }

  public function setViewOffset(fullWidth:Float, fullHeight:Float, x:Float, y:Float, width:Float, height:Float):Void {
    if (this.view == null) {
      this.view = new haxe.ds.WeakMap<String,Dynamic>();
      this.view.set("enabled", true);
      this.view.set("fullWidth", 1);
      this.view.set("fullHeight", 1);
      this.view.set("offsetX", 0);
      this.view.set("offsetY", 0);
      this.view.set("width", 1);
      this.view.set("height", 1);
    }
    this.view.set("enabled", true);
    this.view.set("fullWidth", fullWidth);
    this.view.set("fullHeight", fullHeight);
    this.view.set("offsetX", x);
    this.view.set("offsetY", y);
    this.view.set("width", width);
    this.view.set("height", height);
    this.updateProjectionMatrix();
  }

  public function clearViewOffset():Void {
    if (this.view != null) {
      this.view.set("enabled", false);
    }
    this.updateProjectionMatrix();
  }

  public function updateProjectionMatrix():Void {
    var dx = (this.right - this.left) / (2 * this.zoom);
    var dy = (this.top - this.bottom) / (2 * this.zoom);
    var cx = (this.right + this.left) / 2;
    var cy = (this.top + this.bottom) / 2;

    var left = cx - dx;
    var right = cx + dx;
    var top = cy + dy;
    var bottom = cy - dy;

    if (this.view != null && this.view.get("enabled")) {
      var scaleW = (this.right - this.left) / this.view.get("fullWidth") / this.zoom;
      var scaleH = (this.top - this.bottom) / this.view.get("fullHeight") / this.zoom;

      left += scaleW * this.view.get("offsetX");
      right = left + scaleW * this.view.get("width");
      top -= scaleH * this.view.get("offsetY");
      bottom = top - scaleH * this.view.get("height");
    }

    this.projectionMatrix.makeOrthographic(left, right, top, bottom, this.near, this.far, this.coordinateSystem);
    this.projectionMatrixInverse.copy(this.projectionMatrix).invert();
  }

  public function toJSON(meta:Dynamic):Dynamic {
    var data = super.toJSON(meta);

    data.object.zoom = this.zoom;
    data.object.left = this.left;
    data.object.right = this.right;
    data.object.top = this.top;
    data.object.bottom = this.bottom;
    data.object.near = this.near;
    data.object.far = this.far;

    if (this.view != null) {
      data.object.view = new haxe.ds.WeakMap<String,Dynamic>();
      for (v in this.view.keys()) {
        data.object.view.set(v, this.view.get(v));
      }
    }
    return data;
  }

}