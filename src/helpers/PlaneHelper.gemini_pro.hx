import three.core.BufferGeometry;
import three.core.Float32BufferAttribute;
import three.materials.LineBasicMaterial;
import three.materials.MeshBasicMaterial;
import three.objects.Line;
import three.objects.Mesh;
import three.math.Plane;

class PlaneHelper extends Line {
  public var plane:Plane;
  public var size:Float;

  public function new(plane:Plane, size:Float = 1, hex:Int = 0xffff00) {
    var color = hex;

    var positions = [1, -1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, 1, 0, -1, -1, 0, 1, -1, 0, 1, 1, 0];

    var geometry = new BufferGeometry();
    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));
    geometry.computeBoundingSphere();

    super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));

    this.type = 'PlaneHelper';

    this.plane = plane;

    this.size = size;

    var positions2 = [1, 1, 0, -1, 1, 0, -1, -1, 0, 1, 1, 0, -1, -1, 0, 1, -1, 0];

    var geometry2 = new BufferGeometry();
    geometry2.setAttribute('position', new Float32BufferAttribute(positions2, 3));
    geometry2.computeBoundingSphere();

    this.add(new Mesh(geometry2, new MeshBasicMaterial({color: color, opacity: 0.2, transparent: true, depthWrite: false, toneMapped: false})));
  }

  override function updateMatrixWorld(force:Bool) {
    this.position.set(0, 0, 0);

    this.scale.set(0.5 * this.size, 0.5 * this.size, 1);

    this.lookAt(this.plane.normal);

    this.translateZ(-this.plane.constant);

    super.updateMatrixWorld(force);
  }

  public function dispose() {
    this.geometry.dispose();
    this.material.dispose();
    this.children[0].geometry.dispose();
    this.children[0].material.dispose();
  }
}