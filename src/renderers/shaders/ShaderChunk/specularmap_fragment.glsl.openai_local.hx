将这段 JavaScript 代码转换为 Haxe，可以参考以下实现。Haxe 语言与 JavaScript 有很多相似之处，但也有一些语法和结构上的不同。这里是将给定的 JavaScript 代码转换为 Haxe 的版本。

假设我们使用 `haxe.macro.Context` 以及 GLSL 片段着色器代码的字符串内嵌方式。

首先，我们需要导入 Haxe 的必要模块，然后定义包含 GLSL 代码的字符串，并确保能够处理条件编译指令 `#ifdef` 和 `#else` 等。

```haxe
package renderers.shaders;

class ShaderChunk {
    public static final specularmap_fragment = 
    "
    float specularStrength;

    #ifdef USE_SPECULARMAP

        vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
        specularStrength = texelSpecular.r;

    #else

        specularStrength = 1.0;

    #endif
    ";
}
```

解释：
1. 将 JavaScript 中的 `export default` 转换为 Haxe 中的 `public static final`。
2. 将 GLSL 代码作为多行字符串嵌入到 Haxe 中。
3. 保持 GLSL 代码的格式和结构不变，以确保在 Haxe 中依然能正确解析和使用。

这样转换后，Haxe 程序能够包含和使用这个 GLSL 片段着色器代码。