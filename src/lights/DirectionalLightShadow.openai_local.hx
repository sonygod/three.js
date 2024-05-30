将 JavaScript 代码转换为 Haxe 代码时，需要注意 Haxe 的语法和模块系统。下面是转换后的 Haxe 代码，基于给定的文件路径 `three.js/src/lights/DirectionalLightShadow.hx`：

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

### 详细说明

1. **导入模块**：在 Haxe 中，模块导入使用 `import` 关键字。假设 `LightShadow` 和 `OrthographicCamera` 类分别位于 `three.lights` 和 `three.cameras` 包中。
2. **类声明**：类声明的语法与 JavaScript 类似，但构造函数使用 `new` 关键字。
3. **构造函数**：构造函数中的 `super` 调用会传递参数给父类的构造函数。
4. **变量声明**：`isDirectionalLightShadow` 变量在 Haxe 中声明为 `Bool` 类型。

请根据具体的项目包结构调整导入路径。如果 `LightShadow` 和 `OrthographicCamera` 位于其他包中，请相应地调整导入路径。