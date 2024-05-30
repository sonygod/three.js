要将给定的 JavaScript 代码转换为 Haxe 代码，可以按照以下步骤操作：

1. 使用 Haxe 的类定义语法。
2. 使用 Haxe 的继承语法 `extends`。
3. 设置构造函数中的初始值。

以下是将给定的 JavaScript 代码转换为 Haxe 的代码：

```haxe
import three.core.Object3D;

class Group extends Object3D {

    public var isGroup:Bool;
    public var type:String;

    public function new() {
        super();
        this.isGroup = true;
        this.type = 'Group';
    }

}

```

请确保以下几点：

1. `three.core.Object3D` 是正确的导入路径。如果 Haxe 中的导入路径不同，需要根据实际情况调整。
2. `Group` 类中的成员变量需要明确其类型，所以在 Haxe 中要声明 `isGroup` 为 `Bool` 类型，`type` 为 `String` 类型。