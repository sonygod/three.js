Here is the equivalent Haxe code for the given JavaScript code:
```
package three.helpers;

import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.Float32BufferAttribute;
import three.core.BufferGeometry;

class Box3Helper extends LineSegments {
  public var box:Dynamic;

  public function new(box:Dynamic, ?color:Int = 0xffff00) {
    var indices:Array<Int> = [0, 1, 1, 2, 2, 3, 3, 0, 4, 5, 5, 6, 6, 7, 7, 4, 0, 4, 1, 5, 2, 6, 3, 7];
    var positions:Array<Float> = [1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, 1, 1, -1, -1, 1, -1, -1, -1, -1, 1, -1, -1];

    var geometry:BufferGeometry = new BufferGeometry();
    geometry.setIndex(new BufferAttribute(new Uint16Array(indices), 1));
    geometry.setAttribute('position', new Float32BufferAttribute(new Float32Array(positions), 3));

    super(geometry, new LineBasicMaterial({color: color, toneMapped: false}));

    this.box = box;
    this.type = 'Box3Helper';

    geometry.computeBoundingSphere();
  }

  override public function updateMatrixWorld(force:Bool) {
    var box:Dynamic = this.box;
    if (box.isEmpty()) return;
    box.getCenter(this.position);
    box.getSize(this.scale);
    this.scale.multiplyScalar(0.5);
    super.updateMatrixWorld(force);
  }

  public function dispose() {
    geometry.dispose();
    material.dispose();
  }
}
```
Note that I've made the following changes:

* Imported the necessary Haxe classes from the `three` package.
* Changed the `constructor` to a Haxe `new` method.
* Used Haxe's `Array` and `Float` types instead of JavaScript's `[]` and `new Float32Array()`.
* Used Haxe's `Uint16Array` instead of JavaScript's `Uint16Array`.
* Changed the `super` calls to use Haxe's override syntax.
* Removed the `export` statement, as Haxe uses a different module system.

Please note that this is a manual conversion, and you should test the resulting Haxe code to ensure it works as expected.