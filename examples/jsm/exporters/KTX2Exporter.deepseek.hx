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

import ktx_parse.write;
import ktx_parse.KTX2Container;
import ktx_parse.KHR_DF_CHANNEL_RGBSDA_ALPHA;
import ktx_parse.KHR_DF_CHANNEL_RGBSDA_BLUE;
import ktx_parse.KHR_DF_CHANNEL_RGBSDA_GREEN;
import ktx_parse.KHR_DF_CHANNEL_RGBSDA_RED;
import ktx_parse.KHR_DF_MODEL_RGBSDA;
import ktx_parse.KHR_DF_PRIMARIES_BT709;
import ktx_parse.KHR_DF_PRIMARIES_UNSPECIFIED;
import ktx_parse.KHR_DF_SAMPLE_DATATYPE_FLOAT;
import ktx_parse.KHR_DF_SAMPLE_DATATYPE_LINEAR;
import ktx_parse.KHR_DF_SAMPLE_DATATYPE_SIGNED;
import ktx_parse.KHR_DF_TRANSFER_LINEAR;
import ktx_parse.KHR_DF_TRANSFER_SRGB;
import ktx_parse.VK_FORMAT_R16_SFLOAT;
import ktx_parse.VK_FORMAT_R16G16_SFLOAT;
import ktx_parse.VK_FORMAT_R16G16B16A16_SFLOAT;
import ktx_parse.VK_FORMAT_R32_SFLOAT;
import ktx_parse.VK_FORMAT_R32G32_SFLOAT;
import ktx_parse.VK_FORMAT_R32G32B32A32_SFLOAT;
import ktx_parse.VK_FORMAT_R8_SRGB;
import ktx_parse.VK_FORMAT_R8_UNORM;
import ktx_parse.VK_FORMAT_R8G8_SRGB;
import ktx_parse.VK_FORMAT_R8G8_UNORM;
import ktx_parse.VK_FORMAT_R8G8B8A8_SRGB;
import ktx_parse.VK_FORMAT_R8G8B8A8_UNORM;

class KTX2Exporter {

    public function new() {

    }

    public function parse(arg1:Dynamic, arg2:Dynamic):Dynamic {

        var texture:Dynamic;

        if (arg1.isDataTexture || arg1.isData3DTexture) {

            texture = arg1;

        } else if (arg1.isWebGLRenderer && arg2.isWebGLRenderTarget) {

            texture = toDataTexture(arg1, arg2);

        } else {

            throw "THREE.KTX2Exporter: Supported inputs are DataTexture, Data3DTexture, or WebGLRenderer and WebGLRenderTarget.";

        }

        if (VK_FORMAT_MAP[texture.format] == null) {

            throw "THREE.KTX2Exporter: Supported formats are RGBAFormat, RGFormat, or RedFormat.";

        }

        if (VK_FORMAT_MAP[texture.format][texture.type] == null) {

            throw "THREE.KTX2Exporter: Supported types are FloatType, HalfFloatType, or UnsignedByteType.";

        }

        if (VK_FORMAT_MAP[texture.format][texture.type][texture.colorSpace] == null) {

            throw "THREE.KTX2Exporter: Supported color spaces are SRGBColorSpace (UnsignedByteType only), LinearSRGBColorSpace, or NoColorSpace.";

        }

        //

        var array = texture.image.data;
        var channelCount = getChannelCount(texture);
        var container = new KTX2Container();

        container.vkFormat = VK_FORMAT_MAP[texture.format][texture.type][texture.colorSpace];
        container.typeSize = array.BYTES_PER_ELEMENT;
        container.pixelWidth = texture.image.width;
        container.pixelHeight = texture.image.height;

        if (texture.isData3DTexture) {

            container.pixelDepth = texture.image.depth;

        }

        //

        var basicDesc = container.dataFormatDescriptor[0];

        basicDesc.colorModel = KHR_DF_MODEL_RGBSDA;
        basicDesc.colorPrimaries = texture.colorSpace == NoColorSpace
            ? KHR_DF_PRIMARIES_UNSPECIFIED
            : KHR_DF_PRIMARIES_BT709;
        basicDesc.transferFunction = texture.colorSpace == SRGBColorSpace
            ? KHR_DF_TRANSFER_SRGB
            : KHR_DF_TRANSFER_LINEAR;

        basicDesc.texelBlockDimension = [0, 0, 0, 0];

        basicDesc.bytesPlane = [

            container.typeSize * channelCount, 0, 0, 0, 0, 0, 0, 0,

        ];

        for (i in 0...channelCount) {

            var channelType = KHR_DF_CHANNEL_MAP[i];

            if (texture.colorSpace == LinearSRGBColorSpace || texture.colorSpace == NoColorSpace) {

                channelType |= KHR_DF_SAMPLE_DATATYPE_LINEAR;

            }

            if (texture.type == FloatType || texture.type == HalfFloatType) {

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

        //

        container.levels = [{

            levelData: new Uint8Array(array.buffer, array.byteOffset, array.byteLength),
            uncompressedByteLength: array.byteLength,

        }];

        //

        container.keyValue["KTXwriter"] = "three.js " + REVISION;

        //

        return write(container, {keepWriter: true});

    }

}

function toDataTexture(renderer:Dynamic, rtt:Dynamic):Dynamic {

    var channelCount = getChannelCount(rtt.texture);

    var view:Dynamic;

    if (rtt.texture.type == FloatType) {

        view = new Float32Array(rtt.width * rtt.height * channelCount);

    } else if (rtt.texture.type == HalfFloatType) {

        view = new Uint16Array(rtt.width * rtt.height * channelCount);

    } else if (rtt.texture.type == UnsignedByteType) {

        view = new Uint8Array(rtt.width * rtt.height * channelCount);

    } else {

        throw "THREE.KTX2Exporter: Supported types are FloatType, HalfFloatType, or UnsignedByteType.";

    }

    renderer.readRenderTargetPixels(rtt, 0, 0, rtt.width, rtt.height, view);

    return new DataTexture(view, rtt.width, rtt.height, rtt.texture.format, rtt.texture.type);

}

function getChannelCount(texture:Dynamic):Int {

    switch (texture.format) {

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