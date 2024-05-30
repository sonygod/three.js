将给定的 JavaScript 代码转换为 Haxe 代码时，需考虑 Haxe 的语法和使用的图形库。假设你在 Haxe 中使用的是一个类似 Three.js 的图形库，比如 ThreeHaxe，转换后的代码可能如下所示：

```haxe
#if !macro
import haxe.io.Bytes;
import haxe.io.BytesInput;
import three.textures.Texture;
#end

class MetalnessMapParsFragment {
    #if threejs
    public static inline var source = "
    #ifdef USE_METALNESSMAP
    
        uniform sampler2D metalnessMap;
    
    #endif
    ";
    #end
}
```

在这个转换过程中，我们假设你使用的是一种能处理 GLSL 着色器的 Haxe 库。以下是一些关键点：
1. 使用 `#if threejs` 来确保代码仅在使用特定图形库时编译。
2. 在 `source` 变量中包含 GLSL 代码，作为 Haxe 的内联字符串。

这样做会将原始的 GLSL 代码嵌入到 Haxe 项目中，并使其在需要时作为着色器代码使用。根据具体的图形库和上下文，你可能需要调整导入和库的使用方式。