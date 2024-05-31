以下是将所给的 JavaScript 代码转换为 Haxe 代码的版本:

```haxe
import three.core.RenderTarget;

class WebGLRenderTarget extends RenderTarget {

    public var isWebGLRenderTarget:Bool;

    public function new( width:Int = 1, height:Int = 1, options:Dynamic = {} ) {
        super(width, height, options);
        this.isWebGLRenderTarget = true;
    }
}
```

### 说明:
1. **导入模块**: Haxe 使用 `import` 关键字来导入模块，与 JavaScript 类似。
2. **类定义**: 使用 `class` 关键字定义类。
3. **继承**: 使用 `extends` 关键字表示继承关系。
4. **构造函数**: Haxe 的构造函数使用 `new` 关键字。参数的默认值也类似于 JavaScript，可以在参数列表中直接赋值。
5. **属性**: 在 Haxe 中，类属性需要显式声明其类型。`isWebGLRenderTarget` 被声明为 `Bool` 类型。
6. **动态类型**: `options` 参数使用 `Dynamic` 类型，类似于 JavaScript 中的对象。

这样，你就可以在 Haxe 中使用与原 JavaScript 代码相同的功能。