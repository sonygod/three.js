将给定的 JavaScript 代码转换为 Haxe，可以参考以下 Haxe 代码片段：

```haxe
class LightmapParsFragment {
    #if USE_LIGHTMAP

    public static inline var lightMap = "uniform sampler2D lightMap;";
    public static inline var lightMapIntensity = "uniform float lightMapIntensity;";

    #end
}
```

在 Haxe 中，我们使用条件编译来处理编译期标识符。上面的代码段使用了 `#if` 预处理器指令来检查是否定义了 `USE_LIGHTMAP`。如果定义了 `USE_LIGHTMAP`，那么就会包含 `lightMap` 和 `lightMapIntensity` 的声明。

请注意，在 Haxe 中，我们通常将 GLSL 代码作为字符串进行处理，以便在运行时传递到 OpenGL 着色器程序中。因此，可以将这些字符串在需要的地方进行拼接和使用。