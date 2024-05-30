将 JavaScript 代码转换为 Haxe 代码，并考虑到 Haxe 语法以及等效的功能，转换后的代码如下：

```haxe
class EmissivemapFragmentGlsl {
    public static inline var source: String = "
        #ifdef USE_EMISSIVEMAP
        
        vec4 emissiveColor = texture2D(emissiveMap, vEmissiveMapUv);
        
        totalEmissiveRadiance *= emissiveColor.rgb;
        
        #endif
    ";
}
```

### 说明
1. **文件路径与类定义**：
   Haxe 没有 JavaScript 的文件导出功能（`export default`），但我们可以通过定义一个类来模拟这种行为。这个类包含一个静态的内联变量 `source`，用于存储 GLSL 代码。

2. **GLSL 代码字符串**：
   Haxe 中的多行字符串使用三引号（`"`）进行定义，保持 GLSL 代码不变。

这种方式可以确保 GLSL 代码作为字符串保存在 Haxe 代码中，便于在 Haxe 应用中使用。