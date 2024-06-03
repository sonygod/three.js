import js.Browser.document;
import three.js.core.InstancedInterleavedBuffer;
import three.js.core.InterleavedBuffer;

class InstancedInterleavedBufferTests {
    public function new() {
        // INHERITANCE
        var object = new InstancedInterleavedBuffer();
        js.Boot.trace(Std.is(object, InterleavedBuffer), 'InstancedInterleavedBuffer extends from InterleavedBuffer');

        // INSTANCING
        var array = new js.Boot.Float32Array([1, 2, 3, 7, 8, 9]);
        var instance = new InstancedInterleavedBuffer(array, 3);
        js.Boot.trace(instance.meshPerAttribute == 1, 'ok');

        // PUBLIC
        var object = new InstancedInterleavedBuffer();
        js.Boot.trace(object.isInstancedInterleavedBuffer, 'InstancedInterleavedBuffer.isInstancedInterleavedBuffer should be true');

        // COPY
        var array = new js.Boot.Float32Array([1, 2, 3, 7, 8, 9]);
        var instance = new InstancedInterleavedBuffer(array, 3);
        var copiedInstance = instance.copy(instance);
        js.Boot.trace(copiedInstance.meshPerAttribute == 1, 'additional attribute was copied');
    }
}

new InstancedInterleavedBufferTests();