class KTX2Container {
  public var vkFormat:Int = 0;
  public var typeSize:Int = 1;
  public var pixelWidth:Int = 0;
  public var pixelHeight:Int = 0;
  public var pixelDepth:Int = 0;
  public var layerCount:Int = 0;
  public var faceCount:Int = 1;
  public var supercompressionScheme:Int = 0;
  public var levels:Array<Dynamic> = [];
  public var dataFormatDescriptor:Array<Dynamic> = [{
    vendorId: 0,
    descriptorType: 0,
    descriptorBlockSize: 0,
    versionNumber: 2,
    colorModel: 0,
    colorPrimaries: 1,
    transferFunction: 2,
    flags: 0,
    texelBlockDimension: [0, 0, 0, 0],
    bytesPlane: [0, 0, 0, 0, 0, 0, 0, 0],
    samples: []
  }];
  public var keyValue:Dynamic = {};
  public var globalData:Dynamic = null;

  public function new() {}
}

class Ii {
  private var _dataView:DataView;
  private var _littleEndian:Bool;
  private var _offset:Int;

  public function new(t:Dynamic, e:Int, n:Int, i:Bool) {
    this._dataView = new DataView(t.buffer, t.byteOffset + e, n);
    this._littleEndian = i;
    this._offset = 0;
  }

  public function _nextUint8():Int {
    var t = this._dataView.getUint8(this._offset);
    this._offset += 1;
    return t;
  }

  public function _nextUint16():Int {
    var t = this._dataView.getUint16(this._offset, this._littleEndian);
    this._offset += 2;
    return t;
  }

  public function _nextUint32():Int {
    var t = this._dataView.getUint32(this._offset, this._littleEndian);
    this._offset += 4;
    return t;
  }

  public function _nextUint64():Int {
    var t = this._dataView.getUint32(this._offset, this._littleEndian) + 2**32 * this._dataView.getUint32(this._offset + 4, this._littleEndian);
    this._offset += 8;
    return t;
  }

  public function _nextInt32():Int {
    var t = this._dataView.getInt32(this._offset, this._littleEndian);
    this._offset += 4;
    return t;
  }

  public function _skip(t:Int):Void {
    this._offset += t;
  }

  public function _scan(t:Int, e:Int = 0):Dynamic {
    var n = this._offset;
    var i = 0;
    for (; this._dataView.getUint8(this._offset) != e && i < t;) i++, this._offset++;
    if (i < t && this._offset++) return new Uint8Array(this._dataView.buffer, this._dataView.byteOffset + n, i);
  }
}

class Si {
  public function new() {
    this.vkFormat = 0;
    this.typeSize = 1;
    this.pixelWidth = 0;
    this.pixelHeight = 0;
    this.pixelDepth = 0;
    this.layerCount = 0;
    this.faceCount = 1;
    this.supercompressionScheme = 0;
    this.levels = [];
    this.dataFormatDescriptor = [{
      vendorId: 0,
      descriptorType: 0,
      descriptorBlockSize: 0,
      versionNumber: 2,
      colorModel: 0,
      colorPrimaries: 1,
      transferFunction: 2,
      flags: 0,
      texelBlockDimension: [0, 0, 0, 0],
      bytesPlane: [0, 0, 0, 0, 0, 0, 0, 0],
      samples: []
    }];
    this.keyValue = {};
    this.globalData = null;
  }
}

class Mi {
  public static function write(t:Dynamic, e:Dynamic = {}):Dynamic {
    e = Ci({}, zi, e);
    var n = new ArrayBuffer(0);
    if (t.globalData) {
      var e = new ArrayBuffer(20 + 5 * t.globalData.imageDescs.length * 4),
        i = new DataView(e);
      i.setUint16(0, t.globalData.endpointCount, !0);
      i.setUint16(2, t.globalData.selectorCount, !0);
      i.setUint32(4, t.globalData.endpointsData.byteLength, !0);
      i.setUint32(8, t.globalData.selectorsData.byteLength, !0);
      i.setUint32(12, t.globalData.tablesData.byteLength, !0);
      i.setUint32(16, t.globalData.extendedData.byteLength, !0);
      for (var l = 0; l < t.globalData.imageDescs.length; l++) {
        var f = t.globalData.imageDescs[l];
        i.setUint32(20 + 5 * l * 4 + 0, f.imageFlags, !0);
        i.setUint32(20 + 5 * l * 4 + 4, f.rgbSliceByteOffset, !0);
        i.setUint32(20 + 5 * l * 4 + 8, f.rgbSliceByteLength, !0);
        i.setUint32(20 + 5 * l * 4 + 12, f.alphaSliceByteOffset, !0);
        i.setUint32(20 + 5 * l * 4 + 16, f.alphaSliceByteLength, !0);
      }
      n = Fi([e, t.globalData.endpointsData, t.globalData.selectorsData, t.globalData.tablesData, t.globalData.extendedData]);
    }
    var i = [];
    var s = t.keyValue;
    e.keepWriter || (s = Ci({}, t.keyValue, {
      KTXwriter: "KTX-Parse v0.3.1"
    }));
    for (var t in s) {
      var e = s[t],
        a = Vi(t),
        r = "string" == typeof e ? Vi(e) : e,
        o = a.byteLength + 1 + r.byteLength + 1,
        l = o % 4 ? 4 - o % 4 : 0;
      i.push(Fi([new Uint32Array([o]), a, Oi, r, Oi, new Uint8Array(l).fill(0)]));
    }
    var a = Fi(i);
    if (1 !== t.dataFormatDescriptor.length || 0 !== t.dataFormatDescriptor[0].descriptorType) throw new Error("Only BASICFORMAT Data Format Descriptor output supported.");
    var r = t.dataFormatDescriptor[0],
      o = new ArrayBuffer(28 + 16 * r.samples.length),
      l = new DataView(o),
      f = 24 + 16 * r.samples.length;
    l.setUint32(0, o.byteLength, !0);
    l.setUint16(4, r.vendorId, !0);
    l.setUint16(6, r.descriptorType, !0);
    l.setUint16(8, r.versionNumber, !0);
    l.setUint16(10, f, !0);
    l.setUint8(12, r.colorModel);
    l.setUint8(13, r.colorPrimaries);
    l.setUint8(14, r.transferFunction);
    l.setUint8(15, r.flags);
    !Array.isArray(r.texelBlockDimension) && throw new Error("texelBlockDimension is now an array. For dimensionality `d`, set `d - 1`.");
    l.setUint8(16, r.texelBlockDimension[0]);
    l.setUint8(17, r.texelBlockDimension[1]);
    l.setUint8(18, r.texelBlockDimension[2]);
    l.setUint8(19, r.texelBlockDimension[3]);
    for (var c = 0; c < 8; c++) l.setUint8(20 + c, r.bytesPlane[c]);
    for (var c = 0; c < r.samples.length; c++) {
      var h = r.samples[c],
        u = 28 + 16 * c;
      if (h.channelID) throw new Error("channelID has been renamed to channelType.");
      l.setUint16(u + 0, h.bitOffset, !0);
      l.setUint8(u + 2, h.bitLength);
      l.setUint8(u + 3, h.channelType);
      l.setUint8(u + 4, h.samplePosition[0]);
      l.setUint8(u + 5, h.samplePosition[1]);
      l.setUint8(u + 6, h.samplePosition[2]);
      l.setUint8(u + 7, h.samplePosition[3]);
      64 & h.channelType ? (l.setInt32(u + 8, h.sampleLower, !0), l.setInt32(u + 12, h.sampleUpper, !0)) : (l.setUint32(u + 8, h.sampleLower, !0), l.setUint32(u + 12, h.sampleUpper, !0));
    }
    var _ = Ti.length + 68 + 3 * t.levels.length * 8,
      p = _ + o.byteLength;
    var g = n.byteLength > 0 ? p + a.byteLength : 0;
    g % 8 && (g += 8 - g % 8);
    var _ = [];
    var l = new DataView(new ArrayBuffer(3 * t.levels.length * 8));
    var g = (g || p + a.byteLength) + n.byteLength;
    for (var e = 0; e < t.levels.length; e++) {
      var n = t.levels[e];
      _.push(n.levelData);
      l.setBigUint64(24 * e + 0, BigInt(g), !0);
      l.setBigUint64(24 * e + 8, BigInt(n.levelData.byteLength), !0);
      l.setBigUint64(24 * e + 16, BigInt(n.uncompressedByteLength), !0);
      g += n.levelData.byteLength;
    }
    var a = new ArrayBuffer(68),
      r = new DataView(a);
    return r.setUint32(0, t.vkFormat, !0), r.setUint32(4, t.typeSize, !0), r.setUint32(8, t.pixelWidth, !0), r.setUint32(12, t.pixelHeight, !0), r.setUint32(16, t.pixelDepth, !0), r.setUint32(20, t.layerCount, !0), r.setUint32(24, t.faceCount, !0), r.setUint32(28, t.levels.length, !0), r.setUint32(32, t.supercompressionScheme, !0), r.setUint32(36, _, !0), r.setUint32(40, o.byteLength, !0), r.setUint32(44, p, !0), r.setUint32(48, a.byteLength, !0), r.setBigUint64(52, BigInt(n.byteLength > 0 ? g : 0), !0), r.setBigUint64(60, BigInt(n.byteLength), !0), new Uint8Array(Fi([new Uint8Array(Ti).buffer, a, l.buffer, o, a, h > 0 ? new ArrayBuffer(h - (p + a.byteLength)) : new ArrayBuffer(0), n, ..._]));
  }
}

class Ci {
  public static function assign(t:Dynamic, ...r:Array<Dynamic>):Dynamic {
    for (var e = 1; e < arguments.length; e++) {
      var n = arguments[e];
      for (var i in n) Object.prototype.hasOwnProperty.call(n, i) && (t[i] = n[i]);
    }
    return t;
  }
}

class zi {
  public static var keepWriter:Bool = !1;
}

class Vi {
  public static function encode(t:String):Dynamic {
    return "undefined" != typeof TextEncoder ? (new TextEncoder).encode(t) : Buffer.from(t);
  }
}

class Ei {
  public static function decode(t:Dynamic):String {
    return "undefined" != typeof TextDecoder ? (new TextDecoder).decode(t) : Buffer.from(t).toString("utf8");
  }
}

class Fi {
  public static function concat(t:Array<Dynamic>):Dynamic {
    let e = 0;
    for (const n of t) e += n.byteLength;
    const n = new Uint8Array(e);
    let i = 0;
    for (const e of t) n.set(new Uint8Array(e), i), i += e.byteLength;
    return n;
  }
}

class Pi {
  public static function read(t:Dynamic):Dynamic {
    const e = new Uint8Array(t.buffer, t.byteOffset, Ti.length);
    if (e[0] !== Ti[0] || e[1] !== Ti[1] || e[2] !== Ti[2] || e[3] !== Ti[3] || e[4] !== Ti[4] || e[5] !== Ti[5] || e[6] !== Ti[6] || e[7] !== Ti[7] || e[8] !== Ti[8] || e[9] !== Ti[9] || e[10] !== Ti[10] || e[11] !== Ti[11]) throw new Error("Missing KTX 2.0 identifier.");
    const n = new Si,
      i = 17 * Uint32Array.BYTES_PER_ELEMENT,
      s = new Ii(t, Ti.length, i, !0);
    n.vkFormat = s._nextUint32();
    n.typeSize = s._nextUint32();
    n.pixelWidth = s._nextUint32();
    n.pixelHeight = s._nextUint32();
    n.pixelDepth = s._nextUint32();
    n.layerCount = s._nextUint32();
    n.faceCount = s._nextUint32();
    const a = s._nextUint32();
    n.supercompressionScheme = s._nextUint32();
    const r = s._nextUint32(),
      o = s._nextUint32(),
      l = s._nextUint32(),
      f = s._nextUint32(),
      U = s._nextUint64(),
      c = s._nextUint64(),
      h = new Ii(t, Ti.length + i, 3 * a * 8, !0);
    for (let e = 0; e < a; e++) n.levels.push({
      levelData: new Uint8Array(t.buffer, t.byteOffset + h._nextUint64(), h._nextUint64()),
      uncompressedByteLength: h._nextUint64()
    });
    const _ = new Ii(t, r, o, !0),
      p = {
        vendorId: _.skip(4)._nextUint16(),
        descriptorType: _.nextUint16(),
        versionNumber: _.nextUint16(),
        descriptorBlockSize: _.nextUint16(),
        colorModel: _.nextUint8(),
        colorPrimaries: _.nextUint8(),
        transferFunction: _.nextUint8(),
        flags: _.nextUint8(),
        texelBlockDimension: [_.nextUint8(), _.nextUint8(), _.nextUint8(), _.nextUint8()],
        bytesPlane: [_.nextUint8(), _.nextUint8(), _.nextUint8(), _.nextUint8(), _.nextUint8(), _.nextUint8(), _.nextUint8(), _.nextUint8()],
        samples: []
      },
      g = (p.descriptorBlockSize / 4 - 6) / 4;
    for (let t = 0; t < g; t++) {
      const e = {
        bitOffset: _.nextUint16(),
        bitLength: _.nextUint8(),
        channelType: _.nextUint8(),
        samplePosition: [_.nextUint8(), _.nextUint8(), _.nextUint8(), _.nextUint8()],
        sampleLower: -Infinity,
        sampleUpper: Infinity
      };
      64 & e.channelType ? (e.sampleLower = _.nextInt32(), e.sampleUpper = _.nextInt32()) : (e.sampleLower = _.nextUint32(), e.sampleUpper = _.nextUint32());
      p.samples[t] = e;
    }
    n.dataFormatDescriptor.length = 0;
    n.dataFormatDescriptor.push(p);
    const y = new Ii(t, l, f, !0);
    for (; y._offset < f;) {
      const t = y._nextUint32(),
        e = y._scan(t),
        i = Ei(e),
        s = y._scan(t - e.byteLength);
      n.keyValue[i] = i.match(/^ktx/i) ? Ei(s) : s;
      y._offset % 4 && y._skip(4 - y._offset % 4);
    }
    if (c <= 0) return n;
    const x = new Ii(t, U, c, !0),
      u = x._nextUint16(),
      b = x._nextUint16(),
      d = x._nextUint32(),
      m = x._nextUint32(),
      w = x._nextUint32(),
      D = x._nextUint32(),
      B = [],
      L = U + x._offset,
      A = L + d,
      k = A + m,
      v = k + w,
      S = new Uint8Array(t.buffer, t.byteOffset + L, d),
      I = new Uint8Array(t.buffer, t.byteOffset + A, m),
      O = new Uint8Array(t.buffer, t.byteOffset + k, w),
      T = new Uint8Array(t.buffer, t.byteOffset + v, D);
    return n.globalData = {
      endpointCount: u,
      selectorCount: b,
      imageDescs: B,
      endpointsData: S,
      selectorsData: I,
      tablesData: O,
      extendedData: T
    }, n;
  }
}