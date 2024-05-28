Here is the equivalent Haxe code:
```
package three.js.src.objects;

import three.js.src.core.Object3D;

class Bone extends Object3D {

    public var isBone:Bool = true;

    public var type:String = 'Bone';

    public function new() {
        super();
    }
}
```
Note that in Haxe, we don't need to explicitly define a constructor with an empty body, so I removed the `constructor` function. Also, I replaced `this.isBone = true;` and `this.type = 'Bone';` with direct field initialization, which is a more idiomatic way to do it in Haxe.

Also, I added the `public` access modifier to the fields and the constructor, since in Haxe, everything is private by default.

Finally, I added the `package` declaration at the top, which corresponds to the file path `three.js/src/objects/Bone.js`.