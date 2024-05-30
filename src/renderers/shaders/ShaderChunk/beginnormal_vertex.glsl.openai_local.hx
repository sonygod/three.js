要将这段 JavaScript 代码转换为 Haxe，需要考虑 Haxe 对应的语法以及适当的 Haxe 文件路径。以下是转换后的 Haxe 代码：

Haxe 文件路径: `three/src/renderers/shaders/ShaderChunk/beginnormal_vertex.glsl.hx`

```haxe
package three.renderers.shaders.ShaderChunk;

class BeginNormalVertexGlsl {
  public static var code: String = '
    vec3 objectNormal = vec3( normal );

    #ifdef USE_TANGENT

      vec3 objectTangent = vec3( tangent.xyz );

    #endif
  ';
}
```

在这个转换中，我们做了以下工作：

1. 创建了一个 `BeginNormalVertexGlsl` 类，以模拟原始 JavaScript 文件的作用。
2. 将 GLSL 代码存储在静态变量 `code` 中。
3. 使用 Haxe 的多行字符串语法 (`'''`) 保留 GLSL 代码的格式。

这样做之后，`BeginNormalVertexGlsl.code` 就包含了原始的 GLSL 代码片段，可以在 Haxe 项目中使用类似的方式引用这个代码片段。