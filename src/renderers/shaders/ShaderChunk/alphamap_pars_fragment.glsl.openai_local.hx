要将这段 JavaScript 代码转换为 Haxe，你可以使用 Haxe 的特定语法来定义 GLSL 代码和条件编译。Haxe 的 GLSL 支持需要通过字符串定义 GLSL 代码，并且可以使用条件编译来处理 `#ifdef` 语句。

下面是等价的 Haxe 代码：

```haxe
class AlphaMapParsFragment {
    public static inline var glslCode = "
        #ifdef USE_ALPHAMAP

            uniform sampler2D alphaMap;

        #endif
    ";
}
```

这段 Haxe 代码定义了一个名为 `AlphaMapParsFragment` 的类，并且将 GLSL 代码作为一个内联变量 `glslCode` 进行了定义。通过这种方式，你可以在 Haxe 项目中使用这段 GLSL 代码。