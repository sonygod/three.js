Here is the equivalent Haxe code:
```
package three.objects;

import three.core.Object3D;

class Group extends Object3D {
    public var isGroup:Bool = true;
    public var type:String = 'Group';

    public function new() {
        super();
    }
}
```
Note that in Haxe, we don't need to use the `export` keyword to make the class available outside the file. Instead, we use the `public` access modifier to make the class and its members accessible from outside the file.

Also, in Haxe, we use the `package` keyword to specify the package name, which corresponds to the file path in JavaScript. In this case, the package name is `three.objects`, which matches the file path `three.js/src/objects/Group.js`.

Finally, in Haxe, we use the `public var` syntax to declare public variables, and the `public function new()` syntax to declare the constructor.