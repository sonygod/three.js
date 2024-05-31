要将这段 JavaScript 代码转换为 Haxe 代码，可以按照以下步骤进行：

1. **导入模块**：将 `import { Light } from './Light.js';` 转换为 Haxe 的模块导入语法。
2. **定义类**：将 `class AmbientLight extends Light` 转换为 Haxe 的类定义和继承语法。
3. **构造函数**：将 JavaScript 的构造函数转换为 Haxe 的构造函数。
4. **类成员**：定义 Haxe 的类成员变量。

以下是转换后的 Haxe 代码：

```haxe
import three.lights.Light;

class AmbientLight extends Light {

    public var isAmbientLight:Bool;
    public var type:String;

    public function new(color:Dynamic, intensity:Dynamic) {
        super(color, intensity);
        this.isAmbientLight = true;
        this.type = 'AmbientLight';
    }

}
```

**解释**：

1. **导入模块**：Haxe 的模块路径需要与文件系统的路径一致，因此假设 `Light` 类在 `three/lights` 路径下。
2. **定义类**：使用 `class AmbientLight extends Light` 来定义继承关系。
3. **构造函数**：使用 `new` 关键字定义构造函数，并将 `super(color, intensity)` 调用放在构造函数的开头。
4. **类成员**：在 Haxe 中，成员变量需要在类中显式声明其类型。这里 `isAmbientLight` 是 `Bool` 类型，`type` 是 `String` 类型。

这个 Haxe 代码片段应该在与 JavaScript 原代码等价的情况下工作。如果有更多上下文（例如 `Light` 类的具体实现），可能需要进一步调整以确保兼容性和正确性。