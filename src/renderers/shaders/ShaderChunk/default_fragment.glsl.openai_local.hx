将给定的 JavaScript 代码转换为 Haxe，以下是基于 Haxe 的等效代码：

```haxe
package three.renderers.shaders.ShaderChunk;

class DefaultFragmentGLSL {
    public static inline var shader: String = "
    void main() {
        gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
    }
    ";
}
```

在这个转换过程中，以下几点需要注意：
1. **Haxe 语法**: Haxe 使用 `package` 关键字来指定包路径。
2. **静态内联变量**: 使用 `public static inline var` 来定义静态内联字符串变量。
3. **字符串内容**: 使用多行字符串（multiline string）来保持 GLSL 代码的原样。

这样，Haxe 代码就可以导出一个包含 GLSL 代码的字符串变量，该变量在 Haxe 编译后的 JavaScript 代码中可以像原始 JavaScript 代码一样使用。