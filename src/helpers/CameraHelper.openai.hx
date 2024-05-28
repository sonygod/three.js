package three.helpers;

import three.cameras.Camera;
import three.math.Vector3;
import three.objects.LineSegments;
import three.math.Color;
import three.materials.LineBasicMaterial;
import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;

class CameraHelper extends LineSegments {
  public var camera:Camera;
  public var pointMap:Map<String, Array<Int>>;
  public var geometry:BufferGeometry;
  public var material:LineBasicMaterial;

  public function new(camera:Camera) {
    super(new BufferGeometry(), new LineBasicMaterial({color: 0xffffff, vertexColors: true, toneMapped: false}));

    this.camera = camera;
    this.pointMap = new Map<String, Array<Int>>();
    this.geometry = cast geometry;
    this.material = cast material;

    update();

    setColors(new Color(0xffaa00), new Color(0xff0000), new Color(0x00aaff), new Color(0xffffff), new Color(0x333333));
  }

  public function setColors(frustum:Color, cone:Color, up:Color, target:Color, cross:Color) {
    var geometry = this.geometry;
    var colorAttribute = geometry.getAttribute('color');
    // near
    colorAttribute.setXYZ(0, frustum.r, frustum.g, frustum.b);
    colorAttribute.setXYZ(1, frustum.r, frustum.g, frustum.b);
    // ...
  }

  public function update() {
    var geometry = this.geometry;
    var pointMap = this.pointMap;

    var w = 1, h = 1;

    _vector.set(0, 0, -1).unproject(this.camera);
    setPoint('c', pointMap, geometry, this.camera, 0, 0, -1);
    // ...
  }

  public function dispose() {
    geometry.dispose();
    material.dispose();
  }

  static function setPoint(point:String, pointMap:Map<String, Array<Int>>, geometry:BufferGeometry, camera:Camera, x:Float, y:Float, z:Float) {
    _vector.set(x, y, z).unproject(camera);
    var points = pointMap[point];
    if (points != null) {
      var position = geometry.getAttribute('position');
      for (i in 0...points.length) {
        position.setXYZ(points[i], _vector.x, _vector.y, _vector.z);
      }
    }
  }

  static var _vector = new Vector3();
  static var _camera = new Camera();
}