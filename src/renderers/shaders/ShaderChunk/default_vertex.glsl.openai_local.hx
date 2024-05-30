要将这段 JavaScript 代码转换为 Haxe，并保留 GLSL 着色器代码，可以按照以下步骤进行：

1. 在 Haxe 中创建一个类来包含着色器代码。
2. 使用 `@:glsl` 元标签来标记 GLSL 着色器代码。
3. 定义一个静态字符串变量来保存 GLSL 代码。

下面是转换后的 Haxe 代码：

```haxe
package three.renderers.shaders;

class ShaderChunk {
    public static inline var default_vertex_glsl:String = 
    "
    void main() {
        gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
    }
    ";
}
```

解释：
- 我们在 `ShaderChunk` 类中定义了一个静态内联变量 `default_vertex_glsl`，它保存了 GLSL 代码。
- 使用 `inline` 修饰符可以在编译时直接内联这个字符串，从而避免运行时的开销。

这样，Haxe 代码就可以通过静态变量 `ShaderChunk.default_vertex_glsl` 访问 GLSL 着色器代码。