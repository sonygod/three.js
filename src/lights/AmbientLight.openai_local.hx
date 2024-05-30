要将该 JavaScript 代码转换为 Haxe，需要遵循 Haxe 的语法和结构。以下是将 `AmbientLight` 类从 JavaScript 转换到 Haxe 的代码：

```haxe
package three.lights;

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

### 解释
- **包声明**：将文件路径对应到 Haxe 包路径 `three.lights`。
- **导入**：使用 `import` 导入所需的类 `Light`。
- **类声明**：使用 `class` 关键字声明 `AmbientLight` 类，并让其继承 `Light` 类。
- **构造函数**：在 Haxe 中构造函数用 `new` 关键字表示。参数类型使用 `Dynamic` 表示，因为原始 JavaScript 代码中没有明确的类型信息。
- **成员变量**：在 Haxe 中，成员变量需要显式声明类型。这里，`isAmbientLight` 是 `Bool` 类型，`type` 是 `String` 类型。
- **super 调用**：调用父类构造函数使用 `super` 关键字，传递 `color` 和 `intensity` 参数。

这样转换后，代码在 Haxe 中应能正确地继承和初始化 `AmbientLight` 类。