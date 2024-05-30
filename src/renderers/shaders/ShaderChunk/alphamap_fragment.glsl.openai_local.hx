将这段 JavaScript 代码转换为 Haxe 时，需要保持与原始 GLSL 代码的结构和功能一致。Haxe 代码中可以使用字符串来表示 GLSL 代码。以下是转换后的代码：

```haxe
class AlphaMapFragmentShader {
    public static inline var source: String = '
#ifdef USE_ALPHAMAP

    diffuseColor.a *= texture2D(alphaMap, vAlphaMapUv).g;

#endif
    ';
}
```

这个转换假设 `AlphaMapFragmentShader` 类是你希望在 Haxe 中包含这段 GLSL 代码的类。`source` 变量包含了原始 GLSL 代码，使用多行字符串表示。

请注意，这段代码的文件路径和文件名可能需要根据你的项目结构进行调整。