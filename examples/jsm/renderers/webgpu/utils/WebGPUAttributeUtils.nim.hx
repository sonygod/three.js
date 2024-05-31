import three.examples.jsm.renderers.webgpu.utils.WebGPUConstants.GPUInputStepMode;
import three.Float16BufferAttribute;

class WebGPUAttributeUtils {

  var backend:WebGPUBackend;

  public function new(backend:WebGPUBackend) {
    this.backend = backend;
  }

  private function createAttribute(attribute:Dynamic, usage:Dynamic):Void {
    var bufferAttribute = this._getBufferAttribute(attribute);
    var backend = this.backend;
    var bufferData = backend.get(bufferAttribute);
    var buffer = bufferData.buffer;

    if (buffer == null) {
      var device = backend.device;
      var array = bufferAttribute.array;

      // patch for INT16 and UINT16
      if (attribute.normalized == false && (Type.getClass(array) == Int16Array || Type.getClass(array) == Uint16Array)) {
        var tempArray = new Uint32Array(array.length);
        for (i in 0...array.length) {
          tempArray[i] = array[i];
        }
        array = tempArray;
      }

      bufferAttribute.array = array;

      if ((bufferAttribute.isStorageBufferAttribute || bufferAttribute.isStorageInstancedBufferAttribute) && bufferAttribute.itemSize == 3) {
        array = new array.constructor(bufferAttribute.count * 4);
        for (i in 0...bufferAttribute.count) {
          array.set(bufferAttribute.array.subarray(i * 3, i * 3 + 3), i * 4);
        }

        // Update BufferAttribute
        bufferAttribute.itemSize = 4;
        bufferAttribute.array = array;
      }

      var size = array.byteLength + ((4 - (array.byteLength % 4)) % 4); // ensure 4 byte alignment, see #20441

      buffer = device.createBuffer({
        label: bufferAttribute.name,
        size: size,
        usage: usage,
        mappedAtCreation: true
      });

      new array.constructor(buffer.getMappedRange()).set(array);

      buffer.unmap();

      bufferData.buffer = buffer;
    }
  }

  // ... rest of the class methods

  private function _getBufferAttribute(attribute:Dynamic):Dynamic {
    if (attribute.isInterleavedBufferAttribute) attribute = attribute.data;
    return attribute;
  }

}