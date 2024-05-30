import js.Browser;

class KTX2Container {
    public var vkFormat(default, null):Int;
    public var typeSize(default, null):Int;
    public var pixelWidth(default, null):Int;
    public var pixelHeight(default, null):Int;
    public var pixelDepth(default, null):Int;
    public var layerCount(default, null):Int;
    public var faceCount(default, null):Int;
    public var levels(default, null):Array<{levelData:Uint8Array, uncompressedByteLength:Int}>;
    public var dataFormatDescriptor(default, null):Array<{vendorId:Int, descriptorType:Int, versionNumber:Int, colorModel:Int, colorPrimaries:Int, transferFunction:Int, flags:Int, texelBlockDimension:Array<Int>, bytesPlane:Array<Int>, samples:Array<{bitOffset:Int, bitLength:Int, channelType:Int, samplePosition:Array<Int>, sampleLower:Int, sampleUpper:Int}>}>;
    public var keyValue(default, null):Dynamic;
    public var globalData(default, null):Dynamic;
}

class Ii {
    public var _dataView(default, null):DataView;
    public var _littleEndian(default, null):Bool;
    public var _offset(default, null):Int;

    public function new(t:Uint8Array, e:Int, n:Int, i:Bool) {
        _dataView = new DataView(t.buffer, t.byteOffset + e, n);
        _littleEndian = i;
        _offset = 0;
    }

    public function _nextUint8():Int {
        var t = _dataView.getUint8(_offset);
        _offset += 1;
        return t;
    }

    public function _nextUint16():Int {
        var t = _dataView.getUint16(_offset, _littleEndian);
        _offset += 2;
        return t;
    }

    public function _nextUint32():Int {
        var t = _dataView.getUint32(_offset, _littleEndian);
        _offset += 4;
        return t;
    }

    public function _nextUint64():Int {
        var t = _dataView.getUint32(_offset, _littleEndian) + 2**32 * _dataView.getUint32(_offset + 4, _littleEndian);
        _offset += 8;
        return t;
    }

    public function _nextInt32():Int {
        var t = _dataView.getInt32(_offset, _littleEndian);
        _offset += 4;
        return t;
    }

    public function _skip(t:Int):Ii {
        _offset += t;
        return this;
    }

    public function _scan(t:Int, e:Int = 0):Uint8Array {
        var n = _offset;
        var i = 0;
        for (; _dataView.getUint8(_offset) != e && i < t; ) {
            i++;
            _offset++;
        }
        return i < t && _offset++, new Uint8Array(_dataView.buffer, _dataView.byteOffset + n, i);
    }
}

var Oi = new Uint8Array([0]);
var Ti = [171, 75, 84, 88, 32, 50, 48, 187, 13, 10, 26, 10];

function Vi(t:String):Uint8Array {
    return "undefined" != typeof TextEncoder ? (new TextEncoder).encode(t) : Buffer.from(t);
}

function Ei(t:Uint8Array):String {
    return "undefined" != typeof TextDecoder ? (new TextDecoder).decode(t) : Buffer.from(t).toString("utf8");
}

function Fi(t:Array<Uint8Array>):Uint8Array {
    var e = 0;
    for (var n of t) e += n.byteLength;
    var i = new Uint8Array(e);
    var s = 0;
    for (var t of t) i.set(new Uint8Array(t), s), s += t.byteLength;
    return i;
}

function Pi(t:KTX2Container, e:Dynamic = {}):Uint8Array {
    e = Object.assign(e, {keepWriter: !1});
    var n = new ArrayBuffer(0);
    if (t.globalData) {
        var i = 20 + 5 * t.globalData.imageDescs.length * 4;
        var s = new Ii(t, Ti.length + i, t.globalData.endpointsData.byteLength + t.globalData.selectorsData.byteLength + t.globalData.tablesData.byteLength + t.globalData.extendedData.byteLength, !0);
        var a = new ArrayBuffer(i);
        var r = new DataView(a);
        for (var o = 0; o < t.globalData.imageDescs.length; o++) {
            var l = t.globalData.imageDescs[o];
            r.setUint32(20 + 5 * o * 4 + 0, l.imageFlags, !0);
            r.setUint32(20 + 5 * o * 4 + 4, l.rgbSliceByteOffset, !0);
            r.setUint32(20 + 5 * o * 4 + 8, l.rgbSliceByteLength, !0);
            r.setUint32(20 + 5 * o * 4 + 12, l.alphaSliceByteOffset, !0);
            r.setUint32(20 + 5 * o * 4 + 16, l.alphaSliceByteLength, !0);
        }
        n = Fi([new Uint8Array(Ti).buffer, new Uint8Array(a).buffer, t.globalData.endpointsData.buffer, t.globalData.selectorsData.buffer, t.globalData.tablesData.buffer, t.globalData.extendedData.buffer]);
    }
    var a = [];
    var s = t.keyValue;
    e.keepWriter || (s = Object.assign(s, {KTXwriter: "KTX-Parse v0.3.1"});
    for (var t in s) {
        var e = s[t], n = Vi(t), a = "string" == typeof e ? Vi(e) : e, r = n.byteLength + a.byteLength + 1;
        a.push(Fi([new Uint32Array([r]), n, Oi, a, Oi, new Uint8Array(4 - r % 4)]));
    }
    var a = Fi(a);
    if (1 !== t.dataFormatDescriptor.length || 0 !== t.dataFormatDescriptor[0].descriptorType) throw new Error("Only BASICFORMAT Data Format Descriptor output supported.");
    var r = t.dataFormatDescriptor[0], o = new ArrayBuffer(28 + 16 * r.samples.length);
    var l = new DataView(o);
    l.setUint32(0, o.byteLength, !0);
    l.setUint16(4, r.vendorId, !0);
    l.setUint16(6, r.descriptorType, !0);
    l.setUint16(8, r.versionNumber, !0);
    l.setUint16(10, 28 + 16 * r.samples.length, !0);
    l.setUint8(12, r.colorModel);
    l.setUint8(13, r.colorPrimaries);
    l.setUint8(14, r.transferFunction);
    l.setUint8(15, r.flags);
    for (var t = 0; t < 8; t++) l.setUint8(16 + t, r.texelBlockDimension[t]);
    for (var t = 0; t < 8; t++) l.setUint8(24 + t, r.bytesPlane[t]);
    for (var t = 0; t < r.samples.length; t++) {
        var e = r.samples[t], n = 28 + 16 * t;
        if (e.channelID) throw new Error("channelID has been renamed to channelType.");
        l.setUint16(n + 0, e.bitOffset, !0);
        l.setUint8(n + 2, e.bitLength);
        l.setUint8(n + 3, e.channelType);
        l.setUint8(n + 4, e.samplePosition[0]);
        l.setUint8(n + 5, e.samplePosition[1]);
        l.setUint8(n + 6, e.samplePosition[2]);
        l.setUint8(n + 7, e.samplePosition[3]);
        64 & e.channelType ? (l.setInt32(n + 8, e.sampleLower, !0), l.setInt32(n + 12, e.sampleUpper, !0)) : (l.setUint32(n + 8, e.sampleLower, !0), l.setUint32(n + 12, e.sampleUpper, !0));
    }
    var U = Ti.length + 68 + 3 * t.levels.length * 8, c = U + o.byteLength;
    var h = n.byteLength > 0 ? c + a.byteLength : 0;
    h % 8 && (h += 8 - h % 8);
    var _ = [], p = new DataView(new ArrayBuffer(3 * t.levels.length * 8));
    for (var e = 0; e < t.levels.length; e++) {
        var n = t.levels[e];
        _.push(n.levelData);
        p.setBigUint64(24 * e + 0, BigInt(g), !0);
        p.setBigUint64(24 * e + 8, BigInt(n.levelData.byteLength), !0);
        p.setBigUint64(24 * e + 16, BigInt(n.uncompressedByteLength), !0);
        g += n.levelData.byteLength;
    }
    var y = new ArrayBuffer(68), x = new DataView(y);
    x.setUint32(0, t.vkFormat, !0);
    x.setUint32(4, t.typeSize, !0);
    x.setUint32(8, t.pixelWidth, !0);
    x.setUint32(12, t.pixelHeight, !0);
    x.setUint32(16, t.pixelDepth, !0);
    x.setUint32(20, t.layerCount, !0);
    x.setUint32(24, t.faceCount, !0);
    x.setUint32(28, t.levels.length, !0);
    x.setUint32(32, t.supercompressionScheme, !0);
    x.setUint32(36, U, !0);
    x.setUint32(40, o.byteLength, !0);
    x.setUint32(44, c, !0);
    x.setUint32(48, a.byteLength, !0);
    x.setBigUint64(52, BigInt(n.byteLength > 0 ? h - (c + a.byteLength) : 0), !0);
    x.setBigUint64(60, BigInt(n.byteLength), !0);
    return new Uint8Array(Fi([new Uint8Array(Ti).buffer, y, p.buffer, o, a, h > 0 ? new ArrayBuffer(h - (c + a.byteLength)) : new ArrayBuffer(0), n, ..._]));
}

export {
    Pi as write
};