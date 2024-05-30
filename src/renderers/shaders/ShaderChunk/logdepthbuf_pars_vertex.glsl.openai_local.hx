下面是将所提供的 JavaScript 代码转换为 Haxe 代码，并且考虑了文件路径的上下文信息：

```haxe
package three.renderers.shaders.ShaderChunk;

#if glsl
@:glsl
class LogDepthBufParsVertex {
  public static inline var shader: String = "
  #ifdef USE_LOGDEPTHBUF

    varying float vFragDepth;
    varying float vIsPerspective;

  #endif
  ";
}
#end
```

说明：

1. 使用 `package` 语句指定文件路径：`three.renderers.shaders.ShaderChunk`。
2. 使用 `#if glsl` 和 `@:glsl` 元标记来表示 GLSL 代码。
3. 将 GLSL 代码作为类的静态成员变量 `shader` 的字符串值。

这样可以在 Haxe 项目中方便地管理 GLSL 代码，同时保持与原始 JavaScript 代码的结构和功能一致。