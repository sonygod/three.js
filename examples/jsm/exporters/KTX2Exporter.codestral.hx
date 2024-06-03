import three.FloatType;
import three.HalfFloatType;
import three.UnsignedByteType;
import three.RGBAFormat;
import three.RGFormat;
import three.RGIntegerFormat;
import three.RedFormat;
import three.RedIntegerFormat;
import three.NoColorSpace;
import three.LinearSRGBColorSpace;
import three.SRGBColorSpace;
import three.DataTexture;
import three.REVISION;

import ktxparse.write;
import ktxparse.KTX2Container;
import ktxparse.KHR_DF_CHANNEL_RGBSDA_ALPHA;
import ktxparse.KHR_DF_CHANNEL_RGBSDA_BLUE;
import ktxparse.KHR_DF_CHANNEL_RGBSDA_GREEN;
import ktxparse.KHR_DF_CHANNEL_RGBSDA_RED;
import ktxparse.KHR_DF_MODEL_RGBSDA;
import ktxparse.KHR_DF_PRIMARIES_BT709;
import ktxparse.KHR_DF_PRIMARIES_UNSPECIFIED;
import ktxparse.KHR_DF_SAMPLE_DATATYPE_FLOAT;
import ktxparse.KHR_DF_SAMPLE_DATATYPE_LINEAR;
import ktxparse.KHR_DF_SAMPLE_DATATYPE_SIGNED;
import ktxparse.KHR_DF_TRANSFER_LINEAR;
import ktxparse.KHR_DF_TRANSFER_SRGB;
import ktxparse.VK_FORMAT_R16_SFLOAT;
import ktxparse.VK_FORMAT_R16G16_SFLOAT;
import ktxparse.VK_FORMAT_R16G16B16A16_SFLOAT;
import ktxparse.VK_FORMAT_R32_SFLOAT;
import ktxparse.VK_FORMAT_R32G32_SFLOAT;
import ktxparse.VK_FORMAT_R32G32B32A32_SFLOAT;
import ktxparse.VK_FORMAT_R8_SRGB;
import ktxparse.VK_FORMAT_R8_UNORM;
import ktxparse.VK_FORMAT_R8G8_SRGB;
import ktxparse.VK_FORMAT_R8G8_UNORM;
import ktxparse.VK_FORMAT_R8G8B8A8_SRGB;
import ktxparse.VK_FORMAT_R8G8B8A8_UNORM;

class VKFormatMap {
    static var map:Map<Int, Map<Int, Map<Int, Int>>> = new Map<Int, Map<Int, Map<Int, Int>>>();
}

VKFormatMap.map[RGBAFormat] = new Map<Int, Map<Int, Int>>();
VKFormatMap.map[RGBAFormat][FloatType] = new Map<Int, Int>();
VKFormatMap.map[RGBAFormat][FloatType][NoColorSpace] = VK_FORMAT_R32G32B32A32_SFLOAT;
VKFormatMap.map[RGBAFormat][FloatType][LinearSRGBColorSpace] = VK_FORMAT_R32G32B32A32_SFLOAT;
VKFormatMap.map[RGBAFormat][HalfFloatType] = new Map<Int, Int>();
VKFormatMap.map[RGBAFormat][HalfFloatType][NoColorSpace] = VK_FORMAT_R16G16B16A16_SFLOAT;
VKFormatMap.map[RGBAFormat][HalfFloatType][LinearSRGBColorSpace] = VK_FORMAT_R16G16B16A16_SFLOAT;
VKFormatMap.map[RGBAFormat][UnsignedByteType] = new Map<Int, Int>();
VKFormatMap.map[RGBAFormat][UnsignedByteType][NoColorSpace] = VK_FORMAT_R8G8B8A8_UNORM;
VKFormatMap.map[RGBAFormat][UnsignedByteType][LinearSRGBColorSpace] = VK_FORMAT_R8G8B8A8_UNORM;
VKFormatMap.map[RGBAFormat][UnsignedByteType][SRGBColorSpace] = VK_FORMAT_R8G8B8A8_SRGB;

VKFormatMap.map[RGFormat] = new Map<Int, Map<Int, Int>>();
VKFormatMap.map[RGFormat][FloatType] = new Map<Int, Int>();
VKFormatMap.map[RGFormat][FloatType][NoColorSpace] = VK_FORMAT_R32G32_SFLOAT;
VKFormatMap.map[RGFormat][FloatType][LinearSRGBColorSpace] = VK_FORMAT_R32G32_SFLOAT;
VKFormatMap.map[RGFormat][HalfFloatType] = new Map<Int, Int>();
VKFormatMap.map[RGFormat][HalfFloatType][NoColorSpace] = VK_FORMAT_R16G16_SFLOAT;
VKFormatMap.map[RGFormat][HalfFloatType][LinearSRGBColorSpace] = VK_FORMAT_R16G16_SFLOAT;
VKFormatMap.map[RGFormat][UnsignedByteType] = new Map<Int, Int>();
VKFormatMap.map[RGFormat][UnsignedByteType][NoColorSpace] = VK_FORMAT_R8G8_UNORM;
VKFormatMap.map[RGFormat][UnsignedByteType][LinearSRGBColorSpace] = VK_FORMAT_R8G8_UNORM;
VKFormatMap.map[RGFormat][UnsignedByteType][SRGBColorSpace] = VK_FORMAT_R8G8_SRGB;

VKFormatMap.map[RedFormat] = new Map<Int, Map<Int, Int>>();
VKFormatMap.map[RedFormat][FloatType] = new Map<Int, Int>();
VKFormatMap.map[RedFormat][FloatType][NoColorSpace] = VK_FORMAT_R32_SFLOAT;
VKFormatMap.map[RedFormat][FloatType][LinearSRGBColorSpace] = VK_FORMAT_R32_SFLOAT;
VKFormatMap.map[RedFormat][HalfFloatType] = new Map<Int, Int>();
VKFormatMap.map[RedFormat][HalfFloatType][NoColorSpace] = VK_FORMAT_R16_SFLOAT;
VKFormatMap.map[RedFormat][HalfFloatType][LinearSRGBColorSpace] = VK_FORMAT_R16_SFLOAT;
VKFormatMap.map[RedFormat][UnsignedByteType] = new Map<Int, Int>();
VKFormatMap.map[RedFormat][UnsignedByteType][NoColorSpace] = VK_FORMAT_R8_UNORM;
VKFormatMap.map[RedFormat][UnsignedByteType][LinearSRGBColorSpace] = VK_FORMAT_R8_UNORM;
VKFormatMap.map[RedFormat][UnsignedByteType][SRGBColorSpace] = VK_FORMAT_R8_SRGB;

class KHRDFChannelMap {
    static var map:Map<Int, Int> = new Map<Int, Int>();
}

KHRDFChannelMap.map[0] = KHR_DF_CHANNEL_RGBSDA_RED;
KHRDFChannelMap.map[1] = KHR_DF_CHANNEL_RGBSDA_GREEN;
KHRDFChannelMap.map[2] = KHR_DF_CHANNEL_RGBSDA_BLUE;
KHRDFChannelMap.map[3] = KHR_DF_CHANNEL_RGBSDA_ALPHA;

class KTX2Exporter {
    public function parse(arg1:Dynamic, arg2:Dynamic):Uint8Array {
        var texture:DataTexture;

        if(Std.is(arg1, DataTexture) || Std.is(arg1, three.Data3DTexture)) {
            texture = arg1;
        } else if(Std.is(arg1, three.WebGLRenderer) && Std.is(arg2, three.WebGLRenderTarget)) {
            texture = toDataTexture(arg1, arg2);
        } else {
            throw "THREE.KTX2Exporter: Supported inputs are DataTexture, Data3DTexture, or WebGLRenderer and WebGLRenderTarget.";
        }

        if(VKFormatMap.map[texture.format] == null) {
            throw "THREE.KTX2Exporter: Supported formats are RGBAFormat, RGFormat, or RedFormat.";
        }

        if(VKFormatMap.map[texture.format][texture.type] == null) {
            throw "THREE.KTX2Exporter: Supported types are FloatType, HalfFloatType, or UnsignedByteType.";
        }

        if(VKFormatMap.map[texture.format][texture.type][texture.colorSpace] == null) {
            throw "THREE.KTX2Exporter: Supported color spaces are SRGBColorSpace (UnsignedByteType only), LinearSRGBColorSpace, or NoColorSpace.";
        }

        var array:Uint8Array = texture.image.data;
        var channelCount:Int = getChannelCount(texture);
        var container:KTX2Container = new KTX2Container();

        container.vkFormat = VKFormatMap.map[texture.format][texture.type][texture.colorSpace];
        container.typeSize = array.BYTES_PER_ELEMENT;
        container.pixelWidth = texture.image.width;
        container.pixelHeight = texture.image.height;

        if(Std.is(texture, three.Data3DTexture)) {
            container.pixelDepth = texture.image.depth;
        }

        var basicDesc = container.dataFormatDescriptor[0];

        basicDesc.colorModel = KHR_DF_MODEL_RGBSDA;
        basicDesc.colorPrimaries = texture.colorSpace == NoColorSpace ? KHR_DF_PRIMARIES_UNSPECIFIED : KHR_DF_PRIMARIES_BT709;
        basicDesc.transferFunction = texture.colorSpace == SRGBColorSpace ? KHR_DF_TRANSFER_SRGB : KHR_DF_TRANSFER_LINEAR;

        basicDesc.texelBlockDimension = [0, 0, 0, 0];

        basicDesc.bytesPlane = [
            container.typeSize * channelCount, 0, 0, 0, 0, 0, 0, 0,
        ];

        for(var i:Int = 0; i < channelCount; ++i) {
            var channelType:Int = KHRDFChannelMap.map[i];

            if(texture.colorSpace == LinearSRGBColorSpace || texture.colorSpace == NoColorSpace) {
                channelType |= KHR_DF_SAMPLE_DATATYPE_LINEAR;
            }

            if(texture.type == FloatType || texture.type == HalfFloatType) {
                channelType |= KHR_DF_SAMPLE_DATATYPE_FLOAT;
                channelType |= KHR_DF_SAMPLE_DATATYPE_SIGNED;
            }

            basicDesc.samples.push({
                channelType: channelType,
                bitOffset: i * array.BYTES_PER_ELEMENT,
                bitLength: array.BYTES_PER_ELEMENT * 8 - 1,
                samplePosition: [0, 0, 0, 0],
                sampleLower: texture.type == UnsignedByteType ? 0 : -1,
                sampleUpper: texture.type == UnsignedByteType ? 255 : 1,
            });
        }

        container.levels = [{
            levelData: array,
            uncompressedByteLength: array.byteLength,
        }];

        container.keyValue["KTXwriter"] = "three.js " + REVISION;

        return write(container, {keepWriter: true});
    }
}

function toDataTexture(renderer:three.WebGLRenderer, rtt:three.WebGLRenderTarget):DataTexture {
    var channelCount:Int = getChannelCount(rtt.texture);

    var view:Array<Float>;

    if(rtt.texture.type == FloatType) {
        view = new Array<Float>(rtt.width * rtt.height * channelCount);
    } else if(rtt.texture.type == HalfFloatType) {
        view = new Array<Int>(rtt.width * rtt.height * channelCount);
    } else if(rtt.texture.type == UnsignedByteType) {
        view = new Array<Int>(rtt.width * rtt.height * channelCount);
    } else {
        throw "THREE.KTX2Exporter: Supported types are FloatType, HalfFloatType, or UnsignedByteType.";
    }

    renderer.readRenderTargetPixels(rtt, 0, 0, rtt.width, rtt.height, view);

    return new DataTexture(view, rtt.width, rtt.height, rtt.texture.format, rtt.texture.type);
}

function getChannelCount(texture:Dynamic):Int {
    switch(texture.format) {
        case RGBAFormat:
            return 4;
        case RGFormat:
        case RGIntegerFormat:
            return 2;
        case RedFormat:
        case RedIntegerFormat:
            return 1;
        default:
            throw "THREE.KTX2Exporter: Supported formats are RGBAFormat, RGFormat, or RedFormat.";
    }
}