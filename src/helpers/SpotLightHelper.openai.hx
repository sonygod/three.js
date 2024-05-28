package three.helpers;

import three.math.Vector3;
import three.core.Object3D;
import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.BufferGeometry;

class SpotLightHelper extends Object3D {
  var light:Dynamic;
  var color:Int;

  public function new(light:Dynamic, color:Int) {
    super();
    this.light = light;
    matrixAutoUpdate = false;
    this.color = color;
    type = 'SpotLightHelper';

    var geometry = new BufferGeometry();
    var positions:Array<Float> = [
      0, 0, 0, 0, 0, 1,
      0, 0, 0, 1, 0, 1,
      0, 0, 0, -1, 0, 1,
      0, 0, 0, 0, 1, 1,
      0, 0, 0, 0, -1, 1
    ];

    for (i in 0...32) {
      var p1 = i / 32 * Math.PI * 2;
      var p2 = (i + 1) / 32 * Math.PI * 2;
      positions.push(Math.cos(p1), Math.sin(p1), 1, Math.cos(p2), Math.sin(p2), 1);
    }

    geometry.setAttribute('position', new Float32BufferAttribute(positions, 3));

    var material = new LineBasicMaterial({ fog: false, toneMapped: false });
    cone = new LineSegments(geometry, material);
    add(cone);

    update();
  }

  public function dispose() {
    cone.geometry.dispose();
    cone.material.dispose();
  }

  public function update() {
    light.updateWorldMatrix(true, false);
    light.target.updateWorldMatrix(true, false);

    if (parent != null) {
      parent.updateWorldMatrix(true);
      matrix.copy(parent.matrixWorld).invert().multiply(light.matrixWorld);
    } else {
      matrix.copy(light.matrixWorld);
    }

    matrixWorld.copy(light.matrixWorld);

    var coneLength = light.distance != null ? light.distance : 1000;
    var coneWidth = coneLength * Math.tan(light.angle);

    cone.scale.set(coneWidth, coneWidth, coneLength);

    _vector.setFromMatrixPosition(light.target.matrixWorld);

    cone.lookAt(_vector);

    if (color != null) {
      cone.material.color.set(color);
    } else {
      cone.material.color.copy(light.color);
    }
  }

  static var _vector = new Vector3();
}