package three.math;

import three.Vector3;

class Box3 {

    public var isBox3:Bool;
    public var min:Vector3;
    public var max:Vector3;

    public function new(min:Vector3 = new Vector3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY), max:Vector3 = new Vector3(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY)) {
        this.isBox3 = true;
        this.min = min;
        this.max = max;
    }

    public function set(min:Vector3, max:Vector3):Box3 {
        this.min.copy(min);
        this.max.copy(max);
        return this;
    }

    // ... 其他方法的转换，与JavaScript代码类似，这里省略了

    public function intersectsTriangle(triangle:Vector3):Bool {
        // ... 转换后的代码，与JavaScript代码类似，这里省略了
    }

    // ... 其他方法的转换，与JavaScript代码类似，这里省略了

    public function applyMatrix4(matrix:Matrix4):Box3 {
        // ... 转换后的代码，与JavaScript代码类似，这里省略了
    }

    // ... 其他方法的转换，与JavaScript代码类似，这里省略了

    public function equals(box:Box3):Bool {
        return box.min.equals(this.min) && box.max.equals(this.max);
    }

    // ... 其他方法的转换，与JavaScript代码类似，这里省略了

}

// ... 其他变量的转换，与JavaScript代码类似，这里省略了

function satForAxes(axes:Array<Float>, v0:Vector3, v1:Vector3, v2:Vector3, extents:Vector3):Bool {
    // ... 转换后的代码，与JavaScript代码类似，这里省略了
}