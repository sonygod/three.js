将这段 JavaScript 代码转换为 Haxe 需要考虑到 Haxe 的语法和模块系统，同时保留 GLSL 代码的格式。以下是将该 JavaScript 代码转换为 Haxe 的示例：

```haxe
package three.renderers.shaders.ShaderChunk;

class LightsLambertFragmentGLSL {
    public static var shaderCode: String = '
LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = specularStrength;
';
}
```

在这个转换中：

1. **包名和文件路径**：按照 Haxe 的命名约定，使用 `package` 关键字定义包名，路径映射到 `three.renderers.shaders.ShaderChunk`。
2. **类定义**：创建一个类 `LightsLambertFragmentGLSL` 来包含 GLSL 代码。
3. **静态变量**：使用 `public static var shaderCode` 定义一个静态字符串变量来存储 GLSL 代码。

这种方式确保 GLSL 代码可以在 Haxe 中使用，并且结构清晰且易于管理。