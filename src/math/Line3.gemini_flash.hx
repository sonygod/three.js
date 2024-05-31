import three.math.Vector3;
import three.math.MathUtils;

class Line3 {
  public var start:Vector3;
  public var end:Vector3;

  public function new(start:Vector3 = new Vector3(), end:Vector3 = new Vector3()) {
    this.start = start;
    this.end = end;
  }

  public function set(start:Vector3, end:Vector3):Line3 {
    this.start.copy(start);
    this.end.copy(end);
    return this;
  }

  public function copy(line:Line3):Line3 {
    this.start.copy(line.start);
    this.end.copy(line.end);
    return this;
  }

  public function getCenter(target:Vector3):Vector3 {
    return target.addVectors(this.start, this.end).multiplyScalar(0.5);
  }

  public function delta(target:Vector3):Vector3 {
    return target.subVectors(this.end, this.start);
  }

  public function distanceSq():Float {
    return this.start.distanceToSquared(this.end);
  }

  public function distance():Float {
    return this.start.distanceTo(this.end);
  }

  public function at(t:Float, target:Vector3):Vector3 {
    return this.delta(target).multiplyScalar(t).add(this.start);
  }

  public function closestPointToPointParameter(point:Vector3, clampToLine:Bool = false):Float {
    var _startP = new Vector3();
    var _startEnd = new Vector3();
    _startP.subVectors(point, this.start);
    _startEnd.subVectors(this.end, this.start);

    var startEnd2 = _startEnd.dot(_startEnd);
    var startEnd_startP = _startEnd.dot(_startP);

    var t = startEnd_startP / startEnd2;

    if (clampToLine) {
      t = MathUtils.clamp(t, 0, 1);
    }

    return t;
  }

  public function closestPointToPoint(point:Vector3, clampToLine:Bool = false, target:Vector3 = new Vector3()):Vector3 {
    var t = this.closestPointToPointParameter(point, clampToLine);
    return this.delta(target).multiplyScalar(t).add(this.start);
  }

  public function applyMatrix4(matrix:three.math.Matrix4):Line3 {
    this.start.applyMatrix4(matrix);
    this.end.applyMatrix4(matrix);
    return this;
  }

  public function equals(line:Line3):Bool {
    return line.start.equals(this.start) && line.end.equals(this.end);
  }

  public function clone():Line3 {
    return new Line3().copy(this);
  }
}


**转换说明：**

1.  **类定义：** 将 `class Line3` 定义为 `class Line3`。
2.  **属性：** 将 `start` 和 `end` 定义为 `Vector3` 类型。
3.  **构造函数：**  将 `constructor` 转换为 `new` 函数，并添加类型提示。
4.  **方法：** 将 `set`、`copy`、`getCenter`、`delta`、`distanceSq`、`distance`、`at`、`closestPointToPointParameter`、`closestPointToPoint`、`applyMatrix4`、`equals` 和 `clone` 转换为 `public` 函数，并添加类型提示。
5.  **私有变量：** 使用 `var` 关键字定义私有变量，并将它们移到 `closestPointToPointParameter` 方法内部。
6.  **返回值：** 添加 `return this;` 到所有修改自身状态的函数，以确保链式调用。
7.  **默认参数：** 为 `closestPointToPoint` 方法的 `target` 参数添加默认值 `new Vector3()`。

**其他注意事项：**

*   Haxe 不支持 `@__PURE__*/` 注解。
*   Haxe 中没有类似 `import * as MathUtils` 的语法，需要手动导入需要的函数。
*   `three.math.Vector3` 和 `three.math.Matrix4` 需要在导入语句中添加 `three.math` 前缀。

**最终代码：**


import three.math.Vector3;
import three.math.MathUtils;

class Line3 {
  public var start:Vector3;
  public var end:Vector3;

  public function new(start:Vector3 = new Vector3(), end:Vector3 = new Vector3()) {
    this.start = start;
    this.end = end;
  }

  public function set(start:Vector3, end:Vector3):Line3 {
    this.start.copy(start);
    this.end.copy(end);
    return this;
  }

  public function copy(line:Line3):Line3 {
    this.start.copy(line.start);
    this.end.copy(line.end);
    return this;
  }

  public function getCenter(target:Vector3):Vector3 {
    return target.addVectors(this.start, this.end).multiplyScalar(0.5);
  }

  public function delta(target:Vector3):Vector3 {
    return target.subVectors(this.end, this.start);
  }

  public function distanceSq():Float {
    return this.start.distanceToSquared(this.end);
  }

  public function distance():Float {
    return this.start.distanceTo(this.end);
  }

  public function at(t:Float, target:Vector3):Vector3 {
    return this.delta(target).multiplyScalar(t).add(this.start);
  }

  public function closestPointToPointParameter(point:Vector3, clampToLine:Bool = false):Float {
    var _startP = new Vector3();
    var _startEnd = new Vector3();
    _startP.subVectors(point, this.start);
    _startEnd.subVectors(this.end, this.start);

    var startEnd2 = _startEnd.dot(_startEnd);
    var startEnd_startP = _startEnd.dot(_startP);

    var t = startEnd_startP / startEnd2;

    if (clampToLine) {
      t = MathUtils.clamp(t, 0, 1);
    }

    return t;
  }

  public function closestPointToPoint(point:Vector3, clampToLine:Bool = false, target:Vector3 = new Vector3()):Vector3 {
    var t = this.closestPointToPointParameter(point, clampToLine);
    return this.delta(target).multiplyScalar(t).add(this.start);
  }

  public function applyMatrix4(matrix:three.math.Matrix4):Line3 {
    this.start.applyMatrix4(matrix);
    this.end.applyMatrix4(matrix);
    return this;
  }

  public function equals(line:Line3):Bool {
    return line.start.equals(this.start) && line.end.equals(this.end);
  }

  public function clone():Line3 {
    return new Line3().copy(this);
  }
}