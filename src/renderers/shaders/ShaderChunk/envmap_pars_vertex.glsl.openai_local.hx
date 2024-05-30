将给定的 JavaScript GLSL 代码转换为 Haxe 代码，Haxe 文件路径为 `three/src/renderers/shaders/ShaderChunk/envmap_pars_vertex.glsl.hx`，代码如下：

```haxe
package three.renderers.shaders.ShaderChunk;

class EnvmapParsVertexGlsl {
    public static inline var source: String = '
#ifdef USE_ENVMAP

    #if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )

        #define ENV_WORLDPOS

    #endif

    #ifdef ENV_WORLDPOS

        varying vec3 vWorldPosition;

    #else

        varying vec3 vReflect;
        uniform float refractionRatio;

    #endif

#endif
';
}
```

### 解释
1. **包路径**: Haxe 使用 `package` 关键字指定包路径，`three.renderers.shaders.ShaderChunk` 对应文件夹路径 `three/src/renderers/shaders/ShaderChunk/`。
2. **类定义**: 定义一个类 `EnvmapParsVertexGlsl`，在 Haxe 中每个文件中通常只有一个类。
3. **静态内联变量**: 使用 `public static inline var` 定义 GLSL 代码字符串 `source`。 `inline` 关键字表示这个字符串将在编译时内联。
4. **字符串定义**: 使用 Haxe 的多行字符串定义方式 `'''...'''`（单引号三个）将 GLSL 代码嵌入到字符串中。