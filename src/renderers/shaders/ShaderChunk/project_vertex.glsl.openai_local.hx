将提供的 JavaScript 代码转换为 Haxe 时，需要保留 GLSL 代码的原始内容并进行适当的导出。以下是将 JavaScript 代码转换为 Haxe 的示例：

### 原始 JavaScript 代码

```javascript
export default /* glsl */`
vec4 mvPosition = vec4( transformed, 1.0 );

#ifdef USE_BATCHING

	mvPosition = batchingMatrix * mvPosition;

#endif

#ifdef USE_INSTANCING

	mvPosition = instanceMatrix * mvPosition;

#endif

mvPosition = modelViewMatrix * mvPosition;

gl_Position = projectionMatrix * mvPosition;
`;
```

### 转换为 Haxe 的代码

在 Haxe 中，可以使用字符串字面量来表示 GLSL 代码，并将其导出。可以创建一个 Haxe 文件并将 GLSL 代码保存在一个常量中。以下是转换后的 Haxe 代码：

```haxe
// File path: three.js/src/renderers/shaders/ShaderChunk/project_vertex.glsl.hx

class ProjectVertexGLSL {
    public static inline var shader: String = "
        vec4 mvPosition = vec4( transformed, 1.0 );

        #ifdef USE_BATCHING

            mvPosition = batchingMatrix * mvPosition;

        #endif

        #ifdef USE_INSTANCING

            mvPosition = instanceMatrix * mvPosition;

        #endif

        mvPosition = modelViewMatrix * mvPosition;

        gl_Position = projectionMatrix * mvPosition;
    ";
}
```

### 说明

1. **类声明**: 在 Haxe 中，使用 `class` 声明类名为 `ProjectVertexGLSL`。
2. **常量声明**: 使用 `public static inline var` 来声明一个字符串常量 `shader`，并将 GLSL 代码作为字符串字面量赋值给它。
3. **字符串格式**: Haxe 支持多行字符串字面量，这样可以保留 GLSL 代码的格式。

这样，转换后的 Haxe 代码不仅保留了原始 GLSL 代码的结构和内容，还使其可以在 Haxe 项目中使用。