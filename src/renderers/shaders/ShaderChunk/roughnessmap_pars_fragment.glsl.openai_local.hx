要将提供的 JavaScript GLSL 代码转换为 Haxe，可以按照以下方式进行：

1. 创建一个对应的 Haxe 文件（例如 `roughnessmap_pars_fragment.glsl.hx`）。
2. 在 Haxe 文件中定义一个包含 GLSL 代码的字符串常量。

下面是转换后的 Haxe 代码：

```haxe
// 文件路径: three/shaders/ShaderChunk/roughnessmap_pars_fragment.glsl.hx

package three.shaders.ShaderChunk;

class RoughnessMapParsFragmentGLSL {
    public static inline var source: String = 
    #if glsl
    "
    #ifdef USE_ROUGHNESSMAP

        uniform sampler2D roughnessMap;

    #endif
    "
    #end;
}
```

这里的关键点是：

- 使用 Haxe 的 `inline var` 来定义 GLSL 代码的字符串常量。
- `#if glsl` 和 `#end` 用于确保在编译时正确处理 GLSL 代码（假设 `glsl` 是一个有效的编译器指令，可以根据实际情况调整）。
- 路径和命名空间根据你提供的文件路径和文件名进行了调整。

这样就完成了从 JavaScript 到 Haxe 的转换。