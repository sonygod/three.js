要将这段 JavaScript 代码转换为 Haxe，需要遵循 Haxe 的语法，并考虑 Haxe 的模块导入方式。以下是转换后的 Haxe 代码：

```haxe
import three.lights.LightShadow;
import three.cameras.OrthographicCamera;

class DirectionalLightShadow extends LightShadow {

    public var isDirectionalLightShadow:Bool;

    public function new() {

        super(new OrthographicCamera(-5, 5, 5, -5, 0.5, 500));

        this.isDirectionalLightShadow = true;

    }

}
```

在这个转换过程中，有几个关键点：

1. **导入模块**：在 Haxe 中使用 `import` 语句导入所需的模块。
2. **类定义**：使用 `class` 关键字定义类，并继承自 `LightShadow`。
3. **构造函数**：在 Haxe 中，构造函数使用 `new` 关键字，并调用父类构造函数 `super()`。
4. **属性定义**：在 Haxe 中，属性要在类的顶部声明。在这里声明 `isDirectionalLightShadow` 属性，并在构造函数中初始化它。