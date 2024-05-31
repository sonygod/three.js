根据提供的JavaScript代码和其上下文信息，将其转换为Haxe代码如下：

File path: three.js/src/animation/tracks/NumberKeyframeTrack.hx

```haxe
import three.animation.KeyframeTrack;

/**
 * A Track of numeric keyframe values.
 */
class NumberKeyframeTrack extends KeyframeTrack {
    public static var ValueTypeName:String = 'number';
    // ValueBufferType is inherited
    // DefaultInterpolation is inherited
}

```

解释：
1. `import { KeyframeTrack } from '../KeyframeTrack.js';` 在Haxe中转换为 `import three.animation.KeyframeTrack;`。假设 `KeyframeTrack` 类在 `three/animation` 路径下。
2. `class NumberKeyframeTrack extends KeyframeTrack {}` 在Haxe中转换为 `class NumberKeyframeTrack extends KeyframeTrack {}`。
3. `NumberKeyframeTrack.prototype.ValueTypeName = 'number';` 在Haxe中转换为 `public static var ValueTypeName:String = 'number';`，因为Haxe使用静态变量来定义类级别的属性。