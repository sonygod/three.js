将你提供的 JavaScript 代码转换为 Haxe 代码如下：

```haxe
import three.animation.KeyframeTrack;

/**
 * A Track of vectored keyframe values.
 */
class VectorKeyframeTrack extends KeyframeTrack {
    public static var ValueTypeName: String = "vector";
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited
}

```

在这个转换过程中，需要注意以下几点：

1. Haxe 中使用 `import` 语句来导入其他模块，与 JavaScript 的 `import` 语句类似。
2. 在 Haxe 中，类的定义方式与 JavaScript 类似，但语法稍有不同。
3. JavaScript 中的原型属性在 Haxe 中作为静态属性处理。因此，我们在 Haxe 中定义了 `public static var ValueTypeName: String = "vector";`。

这样，Haxe 代码就能实现与原 JavaScript 代码相同的功能。