要将上述 JavaScript 代码转换为 Haxe，需要考虑到 Haxe 语法以及等效的 Haxe 库。以下是转换后的 Haxe 代码：

```haxe
package three.objects;

import three.core.Object3D;

class Bone extends Object3D {

    public var isBone:Bool;
    public var type:String;

    public function new() {
        super();
        this.isBone = true;
        this.type = 'Bone';
    }

}
```

解释：
1. `package three.objects;` 对应文件路径 `three.js/src/objects/Bone.js`。
2. `import` 语句导入相应的类。
3. `class` 关键字定义类。
4. `public var isBone:Bool;` 和 `public var type:String;` 定义公共成员变量。
5. 构造函数 `new` 中调用 `super();` 初始化父类，并设置 `isBone` 和 `type` 的初始值。