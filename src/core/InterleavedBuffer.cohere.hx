import MathUtils from "../math/MathUtils";
import StaticDrawUsage from "../constants";
import { warnOnce } from "../utils";

class InterleavedBuffer {
  public isInterleavedBuffer: Bool;
  public array: Array<Float>;
  public stride: Int;
  public count: Int;
  public usage: StaticDrawUsage;
  private _updateRange: { offset: Int, count: Int };
  public updateRanges: Array<{ start: Int, count: Int }>;
  public version: Int;
  public uuid: String;
  public onUploadCallback: Void->Void;

  public function new(array: Array<Float>, stride: Int) {
    this.isInterleavedBuffer = true;
    this.array = array;
    this.stride = stride;
    this.count = if (array != null) Std.int(array.length / stride) else 0;
    this.usage = StaticDrawUsage.StaticDraw;
    this._updateRange = { offset: 0, count: -1 };
    this.updateRanges = [];
    this.version = 0;
    this.uuid = MathUtils.generateUUID();
  }

  public function set needsUpdate(value: Bool) {
    if (value) {
      this.version++;
    }
  }

  public function get updateRange(): { offset: Int, count: Int } {
    warnOnce("InterleavedBuffer: updateRange() is deprecated and will be removed. Use addUpdateRange() instead.");
    return this._updateRange;
  }

  public function setUsage(value: StaticDrawUsage): InterleavedBuffer {
    this.usage = value;
    return this;
  }

  public function addUpdateRange(start: Int, count: Int): InterleavedBuffer {
    this.updateRanges.push({ start, count });
    return this;
  }

  public function clearUpdateRanges(): InterleavedBuffer {
    this.updateRanges = [];
    return this;
  }

  public function copy(source: InterleavedBuffer): InterleavedBuffer {
    this.array = new source.array.constructor(source.array);
    this.count = source.count;
    this.stride = source.stride;
    this.usage = source.usage;
    return this;
  }

  public function copyAt(index1: Int, attribute: InterleavedBuffer, index2: Int): InterleavedBuffer {
    index1 *= this.stride;
    index2 *= attribute.stride;
    for (i in 0...this.stride) {
      this.array[index1 + i] = attribute.array[index2 + i];
    }
    return this;
  }

  public function set(value: Array<Float>, offset: Int = 0): InterleavedBuffer {
    this.array.set(value, offset);
    return this;
  }

  public function clone(data: { arrayBuffers: { _: String, __: Array<Int> }}): InterleavedBuffer {
    if (data.arrayBuffers == null) {
      data.arrayBuffers = { _: String, __: Array<Int> };
    }
    if (this.array.buffer._uuid == null) {
      this.array.buffer._uuid = MathUtils.generateUUID();
    }
    if (data.arrayBuffers[this.array.buffer._uuid] == null) {
      data.arrayBuffers[this.array.buffer._uuid] = this.array.slice(0).buffer;
    }
    var array = new this.array.constructor(data.arrayBuffers[this.array.buffer._uuid]);
    var ib = new InterleavedBuffer(array, this.stride);
    ib.setUsage(this.usage);
    return ib;
  }

  public function onUpload(callback: Void->Void): InterleavedBuffer {
    this.onUploadCallback = callback;
    return this;
  }

  public function toJSON(data: { arrayBuffers: { _: String, __: Array<Int> }}): { uuid: String, buffer: String, type: String, stride: Int } {
    if (data.arrayBuffers == null) {
      data.arrayBuffers = { _: String, __: Array<Int> };
    }
    if (this.array.buffer._uuid == null) {
      this.array.buffer._uuid = MathUtils.generateUUID();
    }
    if (data.arrayBuffers[this.array.buffer._uuid] == null) {
      data.arrayBuffers[this.array.buffer._uuid] = Array.from(new Uint32Array(this.array.buffer));
    }
    return {
      uuid: this.uuid,
      buffer: this.array.buffer._uuid,
      type: this.array.constructor.name,
      stride: this.stride
    };
  }
}

class StaticDrawUsage {
  public static inline StaticDraw: StaticDrawUsage = new StaticDrawUsage();
}