Here is the converted Haxe code:
```
package three.helpers;

import three.objects.LineSegments;
import three.materials.LineBasicMaterial;
import three.core.BufferAttribute;
import three.core.Float32BufferAttribute;
import three.core.BufferGeometry;

class Box3Helper extends LineSegments {

    public var box:Box3;

    public function new(box:Box3, color:Int = 0xffff00) {
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
        var box:Box3 = this.box;
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
Note that I've used the Haxe `override` keyword to indicate that the `updateMatrixWorld` method is overriding a method from the superclass. I've also used Haxe's type system to specify the types of variables and function parameters. Additionally, I've used Haxe's `new` keyword to create objects, and I've used Haxe's `Uint16Array` and `Float32Array` classes to create typed arrays.

It's worth noting that Haxe's syntax is similar to JavaScript's, but there are some differences. For example, Haxe uses `override` to indicate overridden methods, whereas JavaScript uses no keyword at all. Haxe also uses `public` and `private` keywords to specify access modifiers, whereas JavaScript does not have explicit access modifiers.