import js.html.DataView;
import js.html.ArrayBuffer;
import js.html.Uint8Array;
import js.html.Uint32Array;
import js.html.Float64Array;
import js.html.TextEncoder;
import js.html.TextDecoder;
import js.html.Buffer;

class KTX2Container {
    public var vkFormat: Int;
    public var typeSize: Int;
    public var pixelWidth: Int;
    public var pixelHeight: Int;
    public var pixelDepth: Int;
    public var layerCount: Int;
    public var faceCount: Int;
    public var supercompressionScheme: Int;
    public var levels: Array<Dynamic>;
    public var dataFormatDescriptor: Array<Dynamic>;
    public var keyValue: Map<String, String>;
    public var globalData: Dynamic;

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
        this.keyValue = new Map<String, String>();
        this.globalData = null;
    }
}

class DataReader {
    private var _dataView: DataView;
    private var _littleEndian: Bool;
    private var _offset: Int;

    public function new(data: Uint8Array, start: Int, length: Int, littleEndian: Bool) {
        this._dataView = new DataView(data.buffer, data.byteOffset + start, length);
        this._littleEndian = littleEndian;
        this._offset = 0;
    }

    public function nextUint8(): Int {
        var value = this._dataView.getUint8(this._offset);
        this._offset += 1;
        return value;
    }

    public function nextUint16(): Int {
        var value = this._dataView.getUint16(this._offset, this._littleEndian);
        this._offset += 2;
        return value;
    }

    public function nextUint32(): Int {
        var value = this._dataView.getUint32(this._offset, this._littleEndian);
        this._offset += 4;
        return value;
    }

    public function nextUint64(): Int {
        var low = this._dataView.getUint32(this._offset, this._littleEndian);
        var high = this._dataView.getUint32(this._offset + 4, this._littleEndian);
        this._offset += 8;
        return low + high * Math.pow(2, 32);
    }

    public function nextInt32(): Int {
        var value = this._dataView.getInt32(this._offset, this._littleEndian);
        this._offset += 4;
        return value;
    }

    public function skip(length: Int): DataReader {
        this._offset += length;
        return this;
    }

    public function scan(length: Int, delimiter: Int = 0): Uint8Array {
        var start = this._offset;
        var count = 0;
        while (this._dataView.getUint8(this._offset) != delimiter && count < length) {
            count++;
            this._offset++;
        }
        if (count < length && this._dataView.getUint8(this._offset) == delimiter) {
            this._offset++;
        }
        return new Uint8Array(this._dataView.buffer, this._dataView.byteOffset + start, count);
    }
}

function encodeString(str: String): Uint8Array {
    return new TextEncoder().encode(str);
}

function decodeString(data: Uint8Array): String {
    return new TextDecoder().decode(data);
}

function concatArrays(arrays: Array<Uint8Array>): Uint8Array {
    var totalLength = 0;
    for (array in arrays) {
        totalLength += array.byteLength;
    }
    var result = new Uint8Array(totalLength);
    var offset = 0;
    for (array in arrays) {
        result.set(new Uint8Array(array), offset);
        offset += array.byteLength;
    }
    return result;
}

function readKTX2(data: Uint8Array): KTX2Container {
    var reader = new DataReader(data, 0, 12, true);
    if (reader.nextUint32() != 0xAB4B5458 || reader.nextUint16() != 0x2032 || reader.nextUint16() != 0x3138 || reader.nextUint8() != 0x0D || reader.nextUint8() != 0x0A || reader.nextUint8() != 0x1A || reader.nextUint8() != 0x0A) {
        throw new Error("Missing KTX 2.0 identifier.");
    }
    var container = new KTX2Container();
    var headerLength = 17 * Uint32Array.BYTES_PER_ELEMENT;
    var headerReader = new DataReader(data, 12, headerLength, true);
    container.vkFormat = headerReader.nextUint32();
    container.typeSize = headerReader.nextUint32();
    container.pixelWidth = headerReader.nextUint32();
    container.pixelHeight = headerReader.nextUint32();
    container.pixelDepth = headerReader.nextUint32();
    container.layerCount = headerReader.nextUint32();
    container.faceCount = headerReader.nextUint32();
    var levelCount = headerReader.nextUint32();
    container.supercompressionScheme = headerReader.nextUint32();
    var dfdByteOffset = headerReader.nextUint32();
    var dfdByteLength = headerReader.nextUint32();
    var kvdByteOffset = headerReader.nextUint32();
    var kvdByteLength = headerReader.nextUint32();
    var sgdByteOffset = headerReader.nextUint32();
    var sgdByteLength = headerReader.nextUint32();
    var levelReader = new DataReader(data, 12 + headerLength, 3 * levelCount * 8, true);
    for (var i = 0; i < levelCount; i++) {
        container.levels.push({
            levelData: new Uint8Array(data.buffer, data.byteOffset + levelReader.nextUint64(), levelReader.nextUint64()),
            uncompressedByteLength: levelReader.nextUint64()
        });
    }
    var dfdReader = new DataReader(data, dfdByteOffset, dfdByteLength, true);
    var dfd = {
        vendorId: dfdReader.skip(4).nextUint16(),
        descriptorType: dfdReader.nextUint16(),
        versionNumber: dfdReader.nextUint16(),
        descriptorBlockSize: dfdReader.nextUint16(),
        colorModel: dfdReader.nextUint8(),
        colorPrimaries: dfdReader.nextUint8(),
        transferFunction: dfdReader.nextUint8(),
        flags: dfdReader.nextUint8(),
        texelBlockDimension: [dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8()],
        bytesPlane: [dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8()],
        samples: []
    };
    var sampleCount = (dfd.descriptorBlockSize / 4 - 6) / 4;
    for (var i = 0; i < sampleCount; i++) {
        var sample = {
            bitOffset: dfdReader.nextUint16(),
            bitLength: dfdReader.nextUint8(),
            channelType: dfdReader.nextUint8(),
            samplePosition: [dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8(), dfdReader.nextUint8()],
            sampleLower: -Infinity,
            sampleUpper: Infinity
        };
        if ((sample.channelType & 64) != 0) {
            sample.sampleLower = dfdReader.nextInt32();
            sample.sampleUpper = dfdReader.nextInt32();
        } else {
            sample.sampleLower = dfdReader.nextUint32();
            sample.sampleUpper = dfdReader.nextUint32();
        }
        dfd.samples[i] = sample;
    }
    container.dataFormatDescriptor.length = 0;
    container.dataFormatDescriptor.push(dfd);
    var kvdReader = new DataReader(data, kvdByteOffset, kvdByteLength, true);
    while (kvdReader._offset < kvdByteLength) {
        var keyLength = kvdReader.nextUint32();
        var key = decodeString(kvdReader.scan(keyLength));
        var valueLength = kvdReader.nextUint32();
        var value = kvdReader.scan(valueLength);
        container.keyValue.set(key, key.match(/^ktx/i) ? decodeString(value) : value);
        var padding = kvdReader._offset % 4;
        if (padding != 0) {
            kvdReader.skip(4 - padding);
        }
    }
    if (sgdByteLength <= 0) {
        return container;
    }
    var sgdReader = new DataReader(data, sgdByteOffset, sgdByteLength, true);
    var endpointCount = sgdReader.nextUint16();
    var selectorCount = sgdReader.nextUint16();
    var endpointsByteLength = sgdReader.nextUint32();
    var selectorsByteLength = sgdReader.nextUint32();
    var tablesByteLength = sgdReader.nextUint32();
    var extendedByteLength = sgdReader.nextUint32();
    var imageDescs = [];
    for (var i = 0; i < levelCount; i++) {
        imageDescs.push({
            imageFlags: sgdReader.nextUint32(),
            rgbSliceByteOffset: sgdReader.nextUint32(),
            rgbSliceByteLength: sgdReader.nextUint32(),
            alphaSliceByteOffset: sgdReader.nextUint32(),
            alphaSliceByteLength: sgdReader.nextUint32()
        });
    }
    var endpointsData = new Uint8Array(data.buffer, data.byteOffset + sgdByteOffset + sgdReader._offset, endpointsByteLength);
    var selectorsData = new Uint8Array(data.buffer, data.byteOffset + sgdByteOffset + sgdReader._offset, selectorsByteLength);
    var tablesData = new Uint8Array(data.buffer, data.byteOffset + sgdByteOffset + sgdReader._offset, tablesByteLength);
    var extendedData = new Uint8Array(data.buffer, data.byteOffset + sgdByteOffset + sgdReader._offset, extendedByteLength);
    container.globalData = {
        endpointCount: endpointCount,
        selectorCount: selectorCount,
        imageDescs: imageDescs,
        endpointsData: endpointsData,
        selectorsData: selectorsData,
        tablesData: tablesData,
        extendedData: extendedData
    };
    return container;
}

function writeKTX2(container: KTX2Container, options: Dynamic = {}): Uint8Array {
    options = { keepWriter: false }.merge(options);
    var globalDataBuffer = new ArrayBuffer(0);
    if (container.globalData != null) {
        var globalDataLength = 20 + 5 * container.globalData.imageDescs.length * 4;
        globalDataBuffer = new ArrayBuffer(globalDataLength);
        var globalDataView = new DataView(globalDataBuffer);
        globalDataView.setUint16(0, container.globalData.endpointCount, true);
        globalDataView.setUint16(2, container.globalData.selectorCount, true);
        globalDataView.setUint32(4, container.globalData.endpointsData.byteLength, true);
        globalDataView.setUint32(8, container.globalData.selectorsData.byteLength, true);
        globalDataView.setUint32(12, container.globalData.tablesData.byteLength, true);
        globalDataView.setUint32(16, container.globalData.extendedData.byteLength, true);
        for (var i = 0; i < container.globalData.imageDescs.length; i++) {
            var desc = container.globalData.imageDescs[i];
            globalDataView.setUint32(20 + 5 * i * 4 + 0, desc.imageFlags, true);
            globalDataView.setUint32(20 + 5 * i * 4 + 4, desc.rgbSliceByteOffset, true);
            globalDataView.setUint32(20 + 5 * i * 4 + 8, desc.rgbSliceByteLength, true);
            globalDataView.setUint32(20 + 5 * i * 4 + 12, desc.alphaSliceByteOffset, true);
            globalDataView.setUint32(20 + 5 * i * 4 + 16, desc.alphaSliceByteLength, true);
        }
        globalDataBuffer = concatArrays([globalDataBuffer, container.globalData.endpointsData, container.globalData.selectorsData, container.globalData.tablesData, container.globalData.extendedData]);
    }
    var keyValueData = [];
    var keyValue = container.keyValue;
    if (!options.keepWriter) {
        keyValue = keyValue.copy();
        keyValue.set("KTXwriter", "KTX-Parse v0.3.1");
    }
    for (key in keyValue.keys()) {
        var value = keyValue.get(key);
        var keyBytes = encodeString(key);
        var valueBytes = typeof(value) == "string" ? encodeString(value) : value;
        var keyValueLength = keyBytes.byteLength + 1 + valueBytes.byteLength + 1;
        var padding = keyValueLength % 4;
        if (padding != 0) {
            padding = 4 - padding;
        }
        keyValueData.push(concatArrays([new Uint32Array([keyValueLength]), keyBytes, new Uint8Array(1), valueBytes, new Uint8Array(1), new Uint8Array(padding).fill(0)]));
    }
    var keyValueBuffer = concatArrays(keyValueData);
    if (container.dataFormatDescriptor.length != 1 || container.dataFormatDescriptor[0].descriptorType != 0) {
        throw new Error("Only BASICFORMAT Data Format Descriptor output supported.");
    }
    var dfd = container.dataFormatDescriptor[0];
    var dfdBuffer = new ArrayBuffer(28 + 16 * dfd.samples.length);
    var dfdView = new DataView(dfdBuffer);
    var dfdLength = 24 + 16 * dfd.samples.length;
    dfdView.setUint32(0, dfdBuffer.byteLength, true);
    dfdView.setUint16(4, dfd.vendorId, true);
    dfdView.setUint16(6, dfd.descriptorType, true);
    dfdView.setUint16(8, dfd.versionNumber, true);
    dfdView.setUint16(10, dfdLength, true);
    dfdView.setUint8(12, dfd.colorModel);
    dfdView.setUint8(13, dfd.colorPrimaries);
    dfdView.setUint8(14, dfd.transferFunction);
    dfdView.setUint8(15, dfd.flags);
    dfdView.setUint8(16, dfd.texelBlockDimension[0]);
    dfdView.setUint8(17, dfd.texelBlockDimension[1]);
    dfdView.setUint8(18, dfd.texelBlockDimension[2]);
    dfdView.setUint8(19, dfd.texelBlockDimension[3]);
    for (var i = 0; i < 8; i++) {
        dfdView.setUint8(20 + i, dfd.bytesPlane[i]);
    }
    for (var i = 0; i < dfd.samples.length; i++) {
        var sample = dfd.samples[i];
        var sampleOffset = 28 + 16 * i;
        dfdView.setUint16(sampleOffset + 0, sample.bitOffset, true);
        dfdView.setUint8(sampleOffset + 2, sample.bitLength);
        dfdView.setUint8(sampleOffset + 3, sample.channelType);
        dfdView.setUint8(sampleOffset + 4, sample.samplePosition[0]);
        dfdView.setUint8(sampleOffset + 5, sample.samplePosition[1]);
        dfdView.setUint8(sampleOffset + 6, sample.samplePosition[2]);
        dfdView.setUint8(sampleOffset + 7, sample.samplePosition[3]);
        if ((sample.channelType & 64) != 0) {
            dfdView.setInt32(sampleOffset + 8, sample.sampleLower, true);
            dfdView.setInt32(sampleOffset + 12, sample.sampleUpper, true);
        } else {
            dfdView.setUint32(sampleOffset + 8, sample.sampleLower, true);
            dfdView.setUint32(sampleOffset + 12, sample.sampleUpper, true);
        }
    }
    var headerBuffer = new ArrayBuffer(68);
    var headerView = new DataView(headerBuffer);
    var identifier = new Uint8Array([0xAB, 0x4B, 0x54, 0x58, 0x20, 0x32, 0x30, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A]);
    var headerLength = identifier.byteLength + headerBuffer.byteLength;
    var levelArrayBuffer = new ArrayBuffer(3 * container.levels.length * 8);
    var levelArrayView = new DataView(levelArrayBuffer);
    var levelData = [];
    var offset = headerLength + levelArrayBuffer.byteLength + dfdBuffer.byteLength;
    if (keyValueBuffer.byteLength > 0) {
        offset += keyValueBuffer.byteLength;
    }
    var padding = offset % 8;
    if (padding != 0) {
        padding = 8 - padding;
    }
    for (var i = 0; i < container.levels.length; i++) {
        var level = container.levels[i];
        levelData.push(level.levelData);
        levelArrayView.setBigUint64(24 * i + 0, BigInt(offset), true);
        levelArrayView.setBigUint64(24 * i + 8, BigInt(level.levelData.byteLength), true);
        levelArrayView.setBigUint64(24 * i + 16, BigInt(level.uncompressedByteLength), true);
        offset += level.levelData.byteLength;
    }
    headerView.setUint32(0, container.vkFormat, true);
    headerView.setUint32(4, container.typeSize, true);
    headerView.setUint32(8, container.pixelWidth, true);
    headerView.setUint32(12, container.pixelHeight, true);
    headerView.setUint32(16, container.pixelDepth, true);
    headerView.setUint32(20, container.layerCount, true);
    headerView.setUint32(24, container.faceCount, true);
    headerView.setUint32(28, container.levels.length, true);
    headerView.setUint32(32, container.supercompressionScheme, true);
    headerView.setUint32(36, headerLength, true);
    headerView.setUint32(40, dfdBuffer.byteLength, true);
    headerView.setUint32(44, headerLength + dfdBuffer.byteLength, true);
    headerView.setUint32(48, keyValueBuffer.byteLength, true);
    if (globalDataBuffer.byteLength > 0) {
        headerView.setBigUint64(52, BigInt(offset + padding), true);
        headerView.setBigUint64(60, BigInt(globalDataBuffer.byteLength), true);
    } else {
        headerView.setBigUint64(52, BigInt(0), true);
        headerView.setBigUint64(60, BigInt(0), true);
    }
    var paddingBuffer = new ArrayBuffer(padding);
    return concatArrays([identifier, headerBuffer, levelArrayBuffer, dfdBuffer, keyValueBuffer, paddingBuffer, globalDataBuffer, ...levelData]);
}