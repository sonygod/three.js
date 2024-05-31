package core;

import core.InterleavedBuffer;

class InstancedInterleavedBuffer extends InterleavedBuffer {

    public var isInstancedInterleavedBuffer:Bool;
    public var meshPerAttribute:Int;

    public function new(array:Array<Float>, stride:Int, meshPerAttribute:Int = 1) {
        super(array, stride);
        this.isInstancedInterleavedBuffer = true;
        this.meshPerAttribute = meshPerAttribute;
    }

    public function copy(source:InstancedInterleavedBuffer):InstancedInterleavedBuffer {
        super.copy(source);
        this.meshPerAttribute = source.meshPerAttribute;
        return this;
    }

    public function clone(data:Dynamic = null):InstancedInterleavedBuffer {
        var ib:InstancedInterleavedBuffer = cast super.clone(data);
        ib.meshPerAttribute = this.meshPerAttribute;
        return ib;
    }

    public function toJSON(data:Dynamic = null):Dynamic {
        var json = super.toJSON(data);
        json.isInstancedInterleavedBuffer = true;
        json.meshPerAttribute = this.meshPerAttribute;
        return json;
    }

}



以下是各部分的解释：

1. **包和导入语句**：
   
   package core;

   import core.InterleavedBuffer;
   
   这部分定义了文件的包路径，并导入了 `InterleavedBuffer` 类。

2. **类定义和成员变量**：
   
   class InstancedInterleavedBuffer extends InterleavedBuffer {

       public var isInstancedInterleavedBuffer:Bool;
       public var meshPerAttribute:Int;
   
   在 Haxe 中，类成员变量需要显式地声明类型。`isInstancedInterleavedBuffer` 是一个布尔值，而 `meshPerAttribute` 是一个整数。

3. **构造函数**：
   
       public function new(array:Array<Float>, stride:Int, meshPerAttribute:Int = 1) {
           super(array, stride);
           this.isInstancedInterleavedBuffer = true;
           this.meshPerAttribute = meshPerAttribute;
       }
   
   构造函数类似于 JavaScript 构造函数，但在 Haxe 中需要使用 `new` 关键字。

4. **复制方法**：
   
       public function copy(source:InstancedInterleavedBuffer):InstancedInterleavedBuffer {
           super.copy(source);
           this.meshPerAttribute = source.meshPerAttribute;
           return this;
       }
   
   `copy` 方法在 Haxe 中接受一个 `InstancedInterleavedBuffer` 类型的参数，并返回 `InstancedInterleavedBuffer`。

5. **克隆方法**：
   
       public function clone(data:Dynamic = null):InstancedInterleavedBuffer {
           var ib:InstancedInterleavedBuffer = cast super.clone(data);
           ib.meshPerAttribute = this.meshPerAttribute;
           return ib;
       }
   
   `clone` 方法返回 `InstancedInterleavedBuffer` 类型的对象。在 Haxe 中，`cast` 关键字用于类型转换。

6. **toJSON 方法**：
   
       public function toJSON(data:Dynamic = null):Dynamic {
           var json = super.toJSON(data);
           json.isInstancedInterleavedBuffer = true;
           json.meshPerAttribute = this.meshPerAttribute;
           return json;
       }