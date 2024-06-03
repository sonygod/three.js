import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.DataView;

/**
 * @author Don McCurdy / https://www.donmccurdy.com
 */

@:enum abstract KHRSupercompressionScheme(Int) {
  public var KHR_SUPERCOMPRESSION_NONE = 0;
  public var KHR_SUPERCOMPRESSION_BASISLZ = 1;
  public var KHR_SUPERCOMPRESSION_ZLIB = 2;
  public var KHR_SUPERCOMPRESSION_ZSTD = 3;
}

@:enum abstract VKFormat(Int) {
  public var VK_FORMAT_UNDEFINED = 0;
  public var VK_FORMAT_R4G4_UNORM_PACK8 = 1;
  public var VK_FORMAT_R4G4B4A4_UNORM_PACK16 = 2;
  public var VK_FORMAT_B4G4R4A4_UNORM_PACK16 = 3;
  public var VK_FORMAT_R5G6B5_UNORM_PACK16 = 4;
  public var VK_FORMAT_B5G6R5_UNORM_PACK16 = 5;
  public var VK_FORMAT_R5G5B5A1_UNORM_PACK16 = 6;
  public var VK_FORMAT_B5G5R5A1_UNORM_PACK16 = 7;
  public var VK_FORMAT_A1R5G5B5_UNORM_PACK16 = 8;
  public var VK_FORMAT_R8_UNORM = 9;
  public var VK_FORMAT_R8_SNORM = 10;
  public var VK_FORMAT_R8_USCALED = 11;
  public var VK_FORMAT_R8_SSCALED = 12;
  public var VK_FORMAT_R8_UINT = 13;
  public var VK_FORMAT_R8_SINT = 14;
  public var VK_FORMAT_R8_SRGB = 15;
  public var VK_FORMAT_R8G8_UNORM = 16;
  public var VK_FORMAT_R8G8_SNORM = 17;
  public var VK_FORMAT_R8G8_USCALED = 18;
  public var VK_FORMAT_R8G8_SSCALED = 19;
  public var VK_FORMAT_R8G8_UINT = 20;
  public var VK_FORMAT_R8G8_SINT = 21;
  public var VK_FORMAT_R8G8_SRGB = 22;
  public var VK_FORMAT_R8G8B8_UNORM = 23;
  public var VK_FORMAT_R8G8B8_SNORM = 24;
  public var VK_FORMAT_R8G8B8_USCALED = 25;
  public var VK_FORMAT_R8G8B8_SSCALED = 26;
  public var VK_FORMAT_R8G8B8_UINT = 27;
  public var VK_FORMAT_R8G8B8_SINT = 28;
  public var VK_FORMAT_R8G8B8_SRGB = 29;
  public var VK_FORMAT_B8G8R8_UNORM = 30;
  public var VK_FORMAT_B8G8R8_SNORM = 31;
  public var VK_FORMAT_B8G8R8_USCALED = 32;
  public var VK_FORMAT_B8G8R8_SSCALED = 33;
  public var VK_FORMAT_B8G8R8_UINT = 34;
  public var VK_FORMAT_B8G8R8_SINT = 35;
  public var VK_FORMAT_B8G8R8_SRGB = 36;
  public var VK_FORMAT_R8G8B8A8_UNORM = 37;
  public var VK_FORMAT_R8G8B8A8_SNORM = 38;
  public var VK_FORMAT_R8G8B8A8_USCALED = 39;
  public var VK_FORMAT_R8G8B8A8_SSCALED = 40;
  public var VK_FORMAT_R8G8B8A8_UINT = 41;
  public var VK_FORMAT_R8G8B8A8_SINT = 42;
  public var VK_FORMAT_R8G8B8A8_SRGB = 43;
  public var VK_FORMAT_B8G8R8A8_UNORM = 44;
  public var VK_FORMAT_B8G8R8A8_SNORM = 45;
  public var VK_FORMAT_B8G8R8A8_USCALED = 46;
  public var VK_FORMAT_B8G8R8A8_SSCALED = 47;
  public var VK_FORMAT_B8G8R8A8_UINT = 48;
  public var VK_FORMAT_B8G8R8A8_SINT = 49;
  public var VK_FORMAT_B8G8R8A8_SRGB = 50;
  public var VK_FORMAT_A8B8G8R8_UNORM_PACK32 = 51;
  public var VK_FORMAT_A8B8G8R8_SNORM_PACK32 = 52;
  public var VK_FORMAT_A8B8G8R8_USCALED_PACK32 = 53;
  public var VK_FORMAT_A8B8G8R8_SSCALED_PACK32 = 54;
  public var VK_FORMAT_A8B8G8R8_UINT_PACK32 = 55;
  public var VK_FORMAT_A8B8G8R8_SINT_PACK32 = 56;
  public var VK_FORMAT_A8B8G8R8_SRGB_PACK32 = 57;
  public var VK_FORMAT_A2R10G10B10_UNORM_PACK32 = 58;
  public var VK_FORMAT_A2R10G10B10_SNORM_PACK32 = 59;
  public var VK_FORMAT_A2R10G10B10_USCALED_PACK32 = 60;
  public var VK_FORMAT_A2R10G10B10_SSCALED_PACK32 = 61;
  public var VK_FORMAT_A2R10G10B10_UINT_PACK32 = 62;
  public var VK_FORMAT_A2R10G10B10_SINT_PACK32 = 63;
  public var VK_FORMAT_A2B10G10R10_UNORM_PACK32 = 64;
  public var VK_FORMAT_A2B10G10R10_SNORM_PACK32 = 65;
  public var VK_FORMAT_A2B10G10R10_USCALED_PACK32 = 66;
  public var VK_FORMAT_A2B10G10R10_SSCALED_PACK32 = 67;
  public var VK_FORMAT_A2B10G10R10_UINT_PACK32 = 68;
  public var VK_FORMAT_A2B10G10R10_SINT_PACK32 = 69;
  public var VK_FORMAT_R16_UNORM = 70;
  public var VK_FORMAT_R16_SNORM = 71;
  public var VK_FORMAT_R16_USCALED = 72;
  public var VK_FORMAT_R16_SSCALED = 73;
  public var VK_FORMAT_R16_UINT = 74;
  public var VK_FORMAT_R16_SINT = 75;
  public var VK_FORMAT_R16_SFLOAT = 76;
  public var VK_FORMAT_R16G16_UNORM = 77;
  public var VK_FORMAT_R16G16_SNORM = 78;
  public var VK_FORMAT_R16G16_USCALED = 79;
  public var VK_FORMAT_R16G16_SSCALED = 80;
  public var VK_FORMAT_R16G16_UINT = 81;
  public var VK_FORMAT_R16G16_SINT = 82;
  public var VK_FORMAT_R16G16_SFLOAT = 83;
  public var VK_FORMAT_R16G16B16_UNORM = 84;
  public var VK_FORMAT_R16G16B16_SNORM = 85;
  public var VK_FORMAT_R16G16B16_USCALED = 86;
  public var VK_FORMAT_R16G16B16_SSCALED = 87;
  public var VK_FORMAT_R16G16B16_UINT = 88;
  public var VK_FORMAT_R16G16B16_SINT = 89;
  public var VK_FORMAT_R16G16B16_SFLOAT = 90;
  public var VK_FORMAT_R16G16B16A16_UNORM = 91;
  public var VK_FORMAT_R16G16B16A16_SNORM = 92;
  public var VK_FORMAT_R16G16B16A16_USCALED = 93;
  public var VK_FORMAT_R16G16B16A16_SSCALED = 94;
  public var VK_FORMAT_R16G16B16A16_UINT = 95;
  public var VK_FORMAT_R16G16B16A16_SINT = 96;
  public var VK_FORMAT_R16G16B16A16_SFLOAT = 97;
  public var VK_FORMAT_R32_UINT = 98;
  public var VK_FORMAT_R32_SINT = 99;
  public var VK_FORMAT_R32_SFLOAT = 100;
  public var VK_FORMAT_R32G32_UINT = 101;
  public var VK_FORMAT_R32G32_SINT = 102;
  public var VK_FORMAT_R32G32_SFLOAT = 103;
  public var VK_FORMAT_R32G32B32_UINT = 104;
  public var VK_FORMAT_R32G32B32_SINT = 105;
  public var VK_FORMAT_R32G32B32_SFLOAT = 106;
  public var VK_FORMAT_R32G32B32A32_UINT = 107;
  public var VK_FORMAT_R32G32B32A32_SINT = 108;
  public var VK_FORMAT_R32G32B32A32_SFLOAT = 109;
  public var VK_FORMAT_R64_UINT = 110;
  public var VK_FORMAT_R64_SINT = 111;
  public var VK_FORMAT_R64_SFLOAT = 112;
  public var VK_FORMAT_R64G64_UINT = 113;
  public var VK_FORMAT_R64G64_SINT = 114;
  public var VK_FORMAT_R64G64_SFLOAT = 115;
  public var VK_FORMAT_R64G64B64_UINT = 116;
  public var VK_FORMAT_R64G64B64_SINT = 117;
  public var VK_FORMAT_R64G64B64_SFLOAT = 118;
  public var VK_FORMAT_R64G64B64A64_UINT = 119;
  public var VK_FORMAT_R64G64B64A64_SINT = 120;
  public var VK_FORMAT_R64G64B64A64_SFLOAT = 121;
  public var VK_FORMAT_B10G11R11_UFLOAT_PACK32 = 122;
  public var VK_FORMAT_E5B9G9R9_UFLOAT_PACK32 = 123;
  public var VK_FORMAT_D16_UNORM = 124;
  public var VK_FORMAT_X8_D24_UNORM_PACK32 = 125;
  public var VK_FORMAT_D32_SFLOAT = 126;
  public var VK_FORMAT_S8_UINT = 127;
  public var VK_FORMAT_D16_UNORM_S8_UINT = 128;
  public var VK_FORMAT_D24_UNORM_S8_UINT = 129;
  public var VK_FORMAT_D32_SFLOAT_S8_UINT = 130;
  public var VK_FORMAT_BC1_RGB_UNORM_BLOCK = 131;
  public var VK_FORMAT_BC1_RGB_SRGB_BLOCK = 132;
  public var VK_FORMAT_BC1_RGBA_UNORM_BLOCK = 133;
  public var VK_FORMAT_BC1_RGBA_SRGB_BLOCK = 134;
  public var VK_FORMAT_BC2_UNORM_BLOCK = 135;
  public var VK_FORMAT_BC2_SRGB_BLOCK = 136;
  public var VK_FORMAT_BC3_UNORM_BLOCK = 137;
  public var VK_FORMAT_BC3_SRGB_BLOCK = 138;
  public var VK_FORMAT_BC4_UNORM_BLOCK = 139;
  public var VK_FORMAT_BC4_SNORM_BLOCK = 140;
  public var VK_FORMAT_BC5_UNORM_BLOCK = 141;
  public var VK_FORMAT_BC5_SNORM_BLOCK = 142;
  public var VK_FORMAT_BC6H_UFLOAT_BLOCK = 143;
  public var VK_FORMAT_BC6H_SFLOAT_BLOCK = 144;
  public var VK_FORMAT_BC7_UNORM_BLOCK = 145;
  public var VK_FORMAT_BC7_SRGB_BLOCK = 146;
  public var VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK = 147;
  public var VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK = 148;
  public var VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK = 149;
  public var VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK = 150;
  public var VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK = 151;
  public var VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK = 152;
  public var VK_FORMAT_EAC_R11_UNORM_BLOCK = 153;
  public var VK_FORMAT_EAC_R11_SNORM_BLOCK = 154;
  public var VK_FORMAT_EAC_R11G11_UNORM_BLOCK = 155;
  public var VK_FORMAT_EAC_R11G11_SNORM_BLOCK = 156;
  public var VK_FORMAT_ASTC_4x4_UNORM_BLOCK = 157;
  public var VK_FORMAT_ASTC_4x4_SRGB_BLOCK = 158;
  public var VK_FORMAT_ASTC_5x4_UNORM_BLOCK = 159;
  public var VK_FORMAT_ASTC_5x4_SRGB_BLOCK = 160;
  public var VK_FORMAT_ASTC_5x5_UNORM_BLOCK = 161;
  public var VK_FORMAT_ASTC_5x5_SRGB_BLOCK = 162;
  public var VK_FORMAT_ASTC_6x5_UNORM_BLOCK = 163;
  public var VK_FORMAT_ASTC_6x5_SRGB_BLOCK = 164;
  public var VK_FORMAT_ASTC_6x6_UNORM_BLOCK = 165;
  public var VK_FORMAT_ASTC_6x6_SRGB_BLOCK = 166;
  public var VK_FORMAT_ASTC_8x5_UNORM_BLOCK = 167;
  public var VK_FORMAT_ASTC_8x5_SRGB_BLOCK = 168;
  public var VK_FORMAT_ASTC_8x6_UNORM_BLOCK = 169;
  public var VK_FORMAT_ASTC_8x6_SRGB_BLOCK = 170;
  public var VK_FORMAT_ASTC_8x8_UNORM_BLOCK = 171;
  public var VK_FORMAT_ASTC_8x8_SRGB_BLOCK = 172;
  public var VK_FORMAT_ASTC_10x5_UNORM_BLOCK = 173;
  public var VK_FORMAT_ASTC_10x5_SRGB_BLOCK = 174;
  public var VK_FORMAT_ASTC_10x6_UNORM_BLOCK = 175;
  public var VK_FORMAT_ASTC_10x6_SRGB_BLOCK = 176;
  public var VK_FORMAT_ASTC_10x8_UNORM_BLOCK = 177;
  public var VK_FORMAT_ASTC_10x8_SRGB_BLOCK = 178;
  public var VK_FORMAT_ASTC_10x10_UNORM_BLOCK = 179;
  public var VK_FORMAT_ASTC_10x10_SRGB_BLOCK = 180;
  public var VK_FORMAT_ASTC_12x10_UNORM_BLOCK = 181;
  public var VK_FORMAT_ASTC_12x10_SRGB_BLOCK = 182;
  public var VK_FORMAT_ASTC_12x12_UNORM_BLOCK = 183;
  public var VK_FORMAT_ASTC_12x12_SRGB_BLOCK = 184;
  public var VK_FORMAT_G8B8G8R8_422_UNORM = 1000156000;
  public var VK_FORMAT_B8G8R8G8_422_UNORM = 1000156001;
  public var VK_FORMAT_G8_B8_R8_3PLANE_420_UNORM = 1000156002;
  public var VK_FORMAT_G8_B8R8_2PLANE_420_UNORM = 1000156003;
  public var VK_FORMAT_G8_B8_R8_3PLANE_422_UNORM = 1000156004;
  public var VK_FORMAT_G8_B8R8_2PLANE_422_UNORM = 1000156005;
  public var VK_FORMAT_G8_B8_R8_3PLANE_444_UNORM = 1000156006;
  public var VK_FORMAT_R10X6_UNORM_PACK16 = 1000156007;
  public var VK_FORMAT_R10X6G10X6_UNORM_2PACK16 = 1000156008;
  public var VK_FORMAT_R10X6G10X6B10X6A10X6_UNORM_4PACK16 = 1000156009;
  public var VK_FORMAT_G10X6B10X6G10X6R10X6_422_UNORM_4PACK16 = 1000156010;
  public var VK_FORMAT_B10X6G10X6R10X6G10X6_422_UNORM_4PACK16 = 1000156011;
  public var VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16 = 1000156012;
  public var VK_FORMAT_G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16 = 1000156013;
  public var VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16 = 1000156014;
  public var VK_FORMAT_G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16 = 1000156015;
  public var VK_FORMAT_G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16 = 1000156016;
  public var VK_FORMAT_R12X4_UNORM_PACK16 = 1000156017;
  public var VK_FORMAT_R12X4G12X4_UNORM_2PACK16 = 1000156018;
  public var VK_FORMAT_R12X4G12X4B12X4A12X4_UNORM_4PACK16 = 1000156019;
  public var VK_FORMAT_G12X4B12X4G12X4R12X4_422_UNORM_4PACK16 = 1000156020;
  public var VK_FORMAT_B12X4G12X4R12X4G12X4_422_UNORM_4PACK16 = 1000156021;
  public var VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16 = 1000156022;
  public var VK_FORMAT_G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16 = 1000156023;
  public var VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16 = 1000156024;
  public var VK_FORMAT_G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16 = 1000156025;
  public var VK_FORMAT_G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16 = 1000156026;
  public var VK_FORMAT_G16B16G16R16_422_UNORM = 1000156027;
  public var VK_FORMAT_B16G16R16G16_422_UNORM = 1000156028;
  public var VK_FORMAT_G16_B16_R16_3PLANE_420_UNORM = 1000156029;
  public var VK_FORMAT_G16_B16R16_2PLANE_420_UNORM = 1000156030;
  public var VK_FORMAT_G16_B16_R16_3PLANE_422_UNORM = 1000156031;
  public var VK_FORMAT_G16_B16R16_2PLANE_422_UNORM = 1000156032;
  public var VK_FORMAT_G16_B16_R16_3PLANE_444_UNORM = 1000156033;
  public var VK_FORMAT_PVRTC1_2BPP_UNORM_BLOCK_IMG = 1000054000;
  public var VK_FORMAT_PVRTC1_4BPP_UNORM_BLOCK_IMG = 1000054001;
  public var VK_FORMAT_PVRTC2_2BPP_UNORM_BLOCK_IMG = 1000054002;
  public var VK_FORMAT_PVRTC2_4BPP_UNORM_BLOCK_IMG = 1000054003;
  public var VK_FORMAT_PVRTC1_2BPP_SRGB_BLOCK_IMG = 1000054004;
  public var VK_FORMAT_PVRTC1_4BPP_SRGB_BLOCK_IMG = 1000054005;
  public var VK_FORMAT_PVRTC2_2BPP_SRGB_BLOCK_IMG = 1000054006;
  public var VK_FORMAT_PVRTC2_4BPP_SRGB_BLOCK_IMG = 1000054007;
  public var VK_FORMAT_ASTC_4x4_SFLOAT_BLOCK_EXT = 1000066000;
  public var VK_FORMAT_ASTC_5x4_SFLOAT_BLOCK_EXT = 1000066001;
  public var VK_FORMAT_ASTC_5x5_SFLOAT_BLOCK_EXT = 1000066002;
  public var VK_FORMAT_ASTC_6x5_SFLOAT_BLOCK_EXT = 1000066003;
  public var VK_FORMAT_ASTC_6x6_SFLOAT_BLOCK_EXT = 1000066004;
  public var VK_FORMAT_ASTC_8x5_SFLOAT_BLOCK_EXT = 1000066005;
  public var VK_FORMAT_ASTC_8x6_SFLOAT_BLOCK_EXT = 1000066006;
  public var VK_FORMAT_ASTC_8x8_SFLOAT_BLOCK_EXT = 1000066007;
  public var VK_FORMAT_ASTC_10x5_SFLOAT_BLOCK_EXT = 1000066008;
  public var VK_FORMAT_ASTC_10x6_SFLOAT_BLOCK_EXT = 1000066009;
  public var VK_FORMAT_ASTC_10x8_SFLOAT_BLOCK_EXT = 1000066010;
  public var VK_FORMAT_ASTC_10x10_SFLOAT_BLOCK_EXT = 1000066011;
  public var VK_FORMAT_ASTC_12x10_SFLOAT_BLOCK_EXT = 1000066012;
  public var VK_FORMAT_ASTC_12x12_SFLOAT_BLOCK_EXT = 1000066013;
  public var VK_FORMAT_A4R4G4B4_UNORM_PACK16_EXT = 1000340000;
  public var VK_FORMAT_A4B4G4R4_UNORM_PACK16_EXT = 1000340001;
}

@:enum abstract KHRDataFormatDescriptorType(Int) {
  public var KHR_DF_KHR_DESCRIPTORTYPE_BASICFORMAT = 0;
}

@:enum abstract KHRDataFormatDescriptorVendorId(Int) {
  public var KHR_DF_VENDORID_KHRONOS = 0;
}

@:enum abstract KHRDataFormatDescriptorVersion(Int) {
  public var KHR_DF_VERSION = 2;
}

@:enum abstract KHRDataFormatDescriptorModel(Int) {
  public var KHR_DF_MODEL_UNSPECIFIED = 0;
  public var KHR_DF_MODEL_RGBSDA = 1;
  public var KHR_DF_MODEL_ASTC = 2;
  public var KHR_DF_MODEL_ETC1 = 3;
  public var KHR_DF_MODEL_ETC1S = 4;
  public var KHR_DF_MODEL_ETC2 = 5;
}

@:enum abstract KHRDataFormatDescriptorColorPrimaries(Int) {
  public var KHR_DF_PRIMARIES_UNSPECIFIED = 0;
  public var KHR_DF_PRIMARIES_BT709 = 1;
  public var KHR_DF_PRIMARIES_UNSUPPORTED = 2;
  public var KHR_DF_PRIMARIES_BT470M = 4;
  public var KHR_DF_PRIMARIES_BT470BG = 5;
  public var KHR_DF_PRIMARIES_SMPTE170M = 6;
  public var KHR_DF_PRIMARIES_SMPTE240M = 7;
  public var KHR_DF_PRIMARIES_FILM = 8;
  public var KHR_DF_PRIMARIES_BT2020 = 9;
  public var KHR_DF_PRIMARIES_NTSC1953 = 10;
  public var KHR_DF_PRIMARIES_SMPTE428 = 11;
  public var KHR_DF_PRIMARIES_SMPTE431 = 12;
  public var KHR_DF_PRIMARIES_SMPTE432 = 13;
  public var KHR_DF_PRIMARIES_JEDEC_P22 = 22;
  public var KHR_DF_PRIMARIES_CUSTOM = 255;
}

@:enum abstract KHRDataFormatDescriptorColorModel(Int) {
  public var KHR_DF_MODEL_UNSPECIFIED = 0;
  public var KHR_DF_MODEL_RGBSDA = 1;
  public var KHR_DF_MODEL_ASTC = 2;
  public var KHR_DF_MODEL_ETC1 = 3;
  public var KHR_DF_MODEL_ETC1S = 4;
  public var KHR_DF_MODEL_ETC2 = 5;
}

@:enum abstract KHRDataFormatDescriptorTransferFunction(Int) {
  public var KHR_DF_TRANSFER_UNSPECIFIED = 0;
  public var KHR_DF_TRANSFER_LINEAR = 1;
  public var KHR_DF_TRANSFER_SRGB = 2;
  public var KHR_DF_TRANSFER_UNSUPPORTED = 3;
  public var KHR_DF_TRANSFER_BT709 = 4;
  public var KHR_DF_TRANSFER_UNSUPPORTED = 5;
  public var KHR_DF_TRANSFER_BT470M = 6;
  public var KHR_DF_TRANSFER_BT470BG = 7;
  public var KHR_DF_TRANSFER_SMPTE170M = 8;
  public var KHR_DF_TRANSFER_SMPTE240M = 9;
  public var KHR_DF_TRANSFER_LINEAR = 10;
  public var KHR_DF_TRANSFER_LOG = 11;
  public var KHR_DF_TRANSFER_LOG_SQRT = 12;
  public var KHR_DF_TRANSFER_IEC61966_2_4 = 13;
  public var KHR_DF_TRANSFER_BT1361_ECG = 14;
  public var KHR_DF_TRANSFER_IEC61966_2_1 = 15;
  public var KHR_DF_TRANSFER_BT2020_10 = 16;
  public var KHR_DF_TRANSFER_BT2020_12 = 17;
  public var KHR_DF_TRANSFER_SMPTE2084 = 18;
  public var KHR_DF_TRANSFER_SMPTE428 = 19;
  public var KHR_DF_TRANSFER_HLG = 20;
  public var KHR_DF_TRANSFER_APHG = 21;
  public var KHR_DF_TRANSFER_SMPTE43
1 = 22;
  public var KHR_DF_TRANSFER_SCRGB = 23;
  public var KHR_DF_TRANSFER_DCI_P3 = 24;
  public var KHR_DF_TRANSFER_CUSTOM = 255;
}

@:enum abstract KHRDataFormatDescriptorFlags(Int) {
  public var KHR_DF_FLAG_ALPHA_STRAIGHT = 0;
  public var KHR_DF_FLAG_ALPHA_PREMULTIPLIED = 1;
}

@:enum abstract KHRDataFormatDescriptorChannelRGBSDA(Int) {
  public var KHR_DF_CHANNEL_RGBSDA_RED = 0;
  public var KHR_DF_CHANNEL_RGBSDA_GREEN = 1;
  public var KHR_DF_CHANNEL_RGBSDA_BLUE = 2;
  public var KHR_DF_CHANNEL_RGBSDA_ALPHA = 15;
  public var KHR_DF_CHANNEL_RGBSDA_DEPTH = 13;
  public var KHR_DF_CHANNEL_RGBSDA_STENCIL = 14;
}

@:enum abstract KHRDataFormatDescriptorSampleDataType(Int) {
  public var KHR_DF_SAMPLE_DATATYPE_SIGNED = 64;
  public var KHR_DF_SAMPLE_DATATYPE_LINEAR = 32;
  public var KHR_DF_SAMPLE_DATATYPE_EXPONENT = 16;
  public var KHR_DF_SAMPLE_DATATYPE_FLOAT = 128;
}

typedef KTX2Level = {
  var levelData: Bytes;
  var uncompressedByteLength: haxe.Int64;
}

typedef KHRDataFormatDescriptorSample = {
  var bitOffset: Int;
  var bitLength: Int;
  var channelType: Int;
  var samplePosition: Array<Int>;
  var sampleLower: Dynamic; // Int | Float
  var sampleUpper: Dynamic; // Int | Float
}

typedef KHRDataFormatDescriptor = {
  var vendorId: Int;
  var descriptorType: Int;
  var versionNumber: Int;
  var descriptorBlockSize: Int;
  var colorModel: Int;
  var colorPrimaries: Int;
  var transferFunction: Int;
  var flags: Int;
  var texelBlockDimension: Array<Int>;
  var bytesPlane: Array<Int>;
  var samples: Array<KHRDataFormatDescriptorSample>;
}

typedef KTX2GlobalData = {
  var endpointCount: Int;
  var selectorCount: Int;
  var imageDescs: Array<KTX2ImageDesc>;
  var endpointsData: Bytes;
  var selectorsData: Bytes;
  var tablesData: Bytes;
  var extendedData: Bytes;
}

typedef KTX2ImageDesc = {
  var imageFlags: Int;
  var rgbSliceByteOffset: Int;
  var rgbSliceByteLength: Int;
  var alphaSliceByteOffset: Int;
  var alphaSliceByteLength: Int;
}

typedef KTX2KeyValue = {
  @:optional var KTXwriter: String;
  @:optional var KTXorientation: String;
}

class KTX2Container {
  public var vkFormat: Int = 0;
  public var typeSize: Int = 1;
  public var pixelWidth: Int = 0;
  public var pixelHeight: Int = 0;
  public var pixelDepth: Int = 0;
  public var layerCount: Int = 0;
  public var faceCount: Int = 1;
  public var supercompressionScheme: Int = 0;
  public var levels: Array<KTX2Level> = [];
  public var dataFormatDescriptor: Array<KHRDataFormatDescriptor> = [{
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
  public var keyValue: KTX2KeyValue = { };
  public var globalData: KTX2GlobalData = null;

  public function new() {
  }
}

class DataViewReader {
  var _dataView: DataView;
  var _littleEndian: Bool;
  var _offset: Int;

  public function new(data: Bytes, byteOffset: Int, byteLength: Int, littleEndian: Bool) {
    _dataView = new DataView(data.buffer, data.byteOffset + byteOffset, byteLength);
    _littleEndian = littleEndian;
    _offset = 0;
  }

  public function _nextUint8(): Int {
    var value = _dataView.getUint8(_offset);
    _offset += 1;
    return value;
  }

  public function _nextUint16(): Int {
    var value = _dataView.getUint16(_offset, _littleEndian);
    _offset += 2;
    return value;
  }

  public function _nextUint32(): Int {
    var value = _dataView.getUint32(_offset, _littleEndian);
    _offset += 4;
    return value;
  }

  public function _nextUint64(): haxe.Int64 {
    // Note: Haxe doesn't have native Uint64, so we need to use Int64 and handle potential overflow
    var low = _dataView.getUint32(_offset, _littleEndian);
    var high = _dataView.getUint32(_offset + 4, _littleEndian);
    _offset += 8;
    return haxe.Int64.make(high, low);
  }

  public function _nextInt32(): Int {
    var value = _dataView.getInt32(_offset, _littleEndian);
    _offset += 4;
    return value;
  }

  public function _skip(bytes: Int): DataViewReader {
    _offset += bytes;
    return this;
  }

  public function _scan(bytes: Int, stopByte: Int = 0): Bytes {
    var start = _offset;
    var count = 0;
    while (_dataView.getUint8(_offset) != stopByte && count < bytes) {
      count++;
      _offset++;
    }

    if (count < bytes) {
      _offset++;
    }

    return Bytes.alloc(_dataView.buffer, _dataView.byteOffset + start, count);
  }
}

final KTX2_IDENTIFIER: Array<Int> = [171, 75, 84, 88, 32, 50, 48, 187, 13, 10, 26, 10];
final KTX2_ZERO_PADDING: Bytes = Bytes.alloc(1);

function _encodeString(str: String): Bytes {
#if js
  return (new js.html.TextEncoder()).encode(str);
#else
  var buffer = new BytesBuffer();
  for (i in 0...str.length) {
    buffer.addByte(str.charCodeAt(i));
  }
  return buffer.getBytes();
#end
}

function _decodeString(bytes: Bytes): String {
#if js
  return (new js.html.TextDecoder()).decode(bytes);
#else
  return bytes.toString();
#end
}

function _concatBytes(arrays: Array<Bytes>): Bytes {
  var totalLength = 0;
  for (arr in arrays) {
    totalLength += arr.length;
  }

  var result = Bytes.alloc(totalLength);
  var offset = 0;
  for (arr in arrays) {
    result.blit(offset, arr, 0, arr.length);
    offset += arr.length;
  }

  return result;
}

function read(data: Bytes): KTX2Container {
  var identifier = data.sub(0, KTX2_IDENTIFIER.length);
  for (i in 0...KTX2_IDENTIFIER.length) {
    if (identifier.get(i) != KTX2_IDENTIFIER[i]) {
      throw "Missing KTX 2.0 identifier.";
    }
  }

  var container = new KTX2Container();
  var headerByteLength = 17 * 4; // 17 Uint32 values
  var headerReader = new DataViewReader(data, KTX2_IDENTIFIER.length, headerByteLength, true);

  container.vkFormat = headerReader._nextUint32();
  container.typeSize = headerReader._nextUint32();
  container.pixelWidth = headerReader._nextUint32();
  container.pixelHeight = headerReader._nextUint32();
  container.pixelDepth = headerReader._nextUint32();
  container.layerCount = headerReader._nextUint32();
  container.faceCount = headerReader._nextUint32();
  var levelCount = headerReader._nextUint32();
  container.supercompressionScheme = headerReader._nextUint32();

  var dfdByteOffset = headerReader._nextUint32();
  var dfdByteLength = headerReader._nextUint32();
  var kvdByteOffset = headerReader._nextUint32();
  var kvdByteLength = headerReader._nextUint32();
  var sgdByteOffset = headerReader._nextUint64();
  var sgdByteLength = headerReader._nextUint64();

  var levelIndexReader = new DataViewReader(data, KTX2_IDENTIFIER.length + headerByteLength, 3 * levelCount * 8, true);
  for (i in 0...levelCount) {
    var levelDataByteOffset = levelIndexReader._nextUint64();
    var levelDataByteLength = levelIndexReader._nextUint64();
    var uncompressedByteLength = levelIndexReader._nextUint64();
    container.levels.push({
      levelData: data.sub(Std.int(levelDataByteOffset), Std.int(levelDataByteLength)),
      uncompressedByteLength: uncompressedByteLength
    });
  }

  var dfdReader = new DataViewReader(data, dfdByteOffset, dfdByteLength, true);
  var descriptor = {
    vendorId: dfdReader._skip(4)._nextUint16(),
    descriptorType: dfdReader._nextUint16(),
    versionNumber: dfdReader._nextUint16(),
    descriptorBlockSize: dfdReader._nextUint16(),
    colorModel: dfdReader._nextUint8(),
    colorPrimaries: dfdReader._nextUint8(),
    transferFunction: dfdReader._nextUint8(),
    flags: dfdReader._nextUint8(),
    texelBlockDimension: [dfdReader._nextUint8(), dfdReader._nextUint8(), dfdReader._nextUint8(), dfdReader._nextUint8()],
    bytesPlane: [
      dfdReader._nextUint8(), dfdReader._nextUint8(), dfdReader._nextUint8(), dfdReader._nextUint8(),
      dfdReader._nextUint8(), dfdReader._nextUint8(), dfdReader._nextUint8(), dfdReader._nextUint8()
    ],
    samples: []
  };

  var sampleCount = (descriptor.descriptorBlockSize / 4 - 6) / 4;
  for (i in 0...sampleCount) {
    var sample = {
      bitOffset: dfdReader._nextUint16(),
      bitLength: dfdReader._nextUint8(),
      channelType: dfdReader._nextUint8(),
      samplePosition: [dfdReader._nextUint8(), dfdReader._nextUint8(), dfdReader._nextUint8(), dfdReader._nextUint8()],
      sampleLower: Math.NEGATIVE_INFINITY,
      sampleUpper: Math.POSITIVE_INFINITY
    };

    if ((sample.channelType & 64) != 0) {
      sample.sampleLower = dfdReader._nextInt32();
      sample.sampleUpper = dfdReader._nextInt32();
    } else {
      sample.sampleLower = dfdReader._nextUint32();
      sample.sampleUpper = dfdReader._nextUint32();
    }

    descriptor.samples[i] = sample;
  }

  container.dataFormatDescriptor.length = 0;
  container.dataFormatDescriptor.push(descriptor);

  var kvdReader = new DataViewReader(data, kvdByteOffset, kvdByteLength, true);
  while (kvdReader._offset < kvdByteLength) {
    var keyValueByteLength = kvdReader._nextUint32();
    var key = _decodeString(kvdReader._scan(keyValueByteLength));
    var value = kvdReader._scan(keyValueByteLength - key.length);
    container.keyValue[key] = ~/^ktx/i.match(key) ? _decodeString(value) : value;

    if (kvdReader._offset % 4 != 0) {
      kvdReader._skip(4 - kvdReader._offset % 4);
    }
  }

  if (sgdByteLength <= 0) {
    return container;
  }

  var sgdReader = new DataViewReader(data, Std.int(sgdByteOffset), Std.int(sgdByteLength), true);
  var endpointCount = sgdReader._nextUint16();
  var selectorCount = sgdReader._nextUint16();
  var endpointsDataByteLength = sgdReader._nextUint32();
  var selectorsDataByteLength = sgdReader._nextUint32();
  var tablesDataByteLength = sgdReader._nextUint32();
  var extendedDataByteLength = sgdReader._nextUint32();
  var imageDescs = [];
  for (i in 0...levelCount) {
    imageDescs.push({
      imageFlags: sgdReader._nextUint32(),
      rgbSliceByteOffset: sgdReader._nextUint32(),
      rgbSliceByteLength: sgdReader._nextUint32(),
      alphaSliceByteOffset: sgdReader._nextUint32(),
      alphaSliceByteLength: sgdReader._nextUint32()
    });
  }

  var endpointsDataByteOffset = Std.int(sgdByteOffset) + sgdReader._offset;
  var selectorsDataByteOffset = endpointsDataByteOffset + endpointsDataByteLength;
  var tablesDataByteOffset = selectorsDataByteOffset + selectorsDataByteLength;
  var extendedDataByteOffset = tablesDataByteOffset + tablesDataByteLength;

  container.globalData = {
    endpointCount: endpointCount,
    selectorCount: selectorCount,
    imageDescs: imageDescs,
    endpointsData: data.sub(endpointsDataByteOffset, endpointsDataByteLength),
    selectorsData: data.sub(selectorsDataByteOffset, selectorsDataByteLength),
    tablesData: data.sub(tablesDataByteOffset, tablesDataByteLength),
    extendedData: data.sub(extendedDataByteOffset, extendedDataByteLength)
  };

  return container;
}

function write(container: KTX2Container, options: { keepWriter: Bool } = { keepWriter: false }): Bytes {
  var sgd: Bytes = null;
  if (container.globalData != null) {
    var sgdBuffer = new BytesBuffer();
    sgdBuffer.addInt16(container.globalData.endpointCount);
    sgdBuffer.addInt16(container.globalData.selectorCount);
    sgdBuffer.addInt32(container.globalData.endpointsData.length);
    sgdBuffer.addInt32(container.globalData.selectorsData.length);
    sgdBuffer.addInt32(container.globalData.tablesData.length);
    sgdBuffer.addInt32(container.globalData.extendedData.length);

    for (imageDesc in container.globalData.imageDescs) {
      sgdBuffer.addInt32(imageDesc.imageFlags);
      sgdBuffer.addInt32(imageDesc.rgbSliceByteOffset);
      sgdBuffer.addInt32(imageDesc.rgbSliceByteLength);
      sgdBuffer.addInt32(imageDesc.alphaSliceByteOffset);
      sgdBuffer.addInt32(imageDesc.alphaSliceByteLength);
    }

    sgd = _concatBytes([
      sgdBuffer.getBytes(),
      container.globalData.endpointsData,
      container.globalData.selectorsData,
      container.globalData.tablesData,
      container.globalData.extendedData
    ]);
  }

  var kvd: Bytes = null;
  var keyValue = options.keepWriter ? container.keyValue : {
    'KTXwriter': 'KTX-Parse v0.3.1',
    ...container.keyValue
  };
  var kvdArrays = [];
  for (key in Reflect.fields(keyValue)) {
    var value = Reflect.field(keyValue, key);
    var encodedKey = _encodeString(key);
    var encodedValue = Std.is(value, String) ? _encodeString(cast value) : cast value;
    var keyValueByteLength = encodedKey.length + 1 + encodedValue.length + 1;
    var paddingByteLength = keyValueByteLength % 4 != 0 ? 4 - (keyValueByteLength % 4) : 0;
    var padding = Bytes.alloc(paddingByteLength);
    kvdArrays.push(_concatBytes([
      Bytes.ofData(new DataView(new haxe.io.ArrayBuffer(4)).setInt32(0, keyValueByteLength)),
      encodedKey,
      KTX2_ZERO_PADDING,
      encodedValue,
      KTX2_ZERO_PADDING,
      padding
    ]));
  }
  kvd = _concatBytes(kvdArrays);

  if (container.dataFormatDescriptor.length != 1 || container.dataFormatDescriptor[0].descriptorType != 0) {
    throw "Only BASICFORMAT Data Format Descriptor output supported.";
  }

  var descriptor = container.dataFormatDescriptor[0];
  var dfdByteLength = 28 + 16 * descriptor.samples.length;
  var dfd = Bytes.alloc(dfdByteLength);
  var dfdView = new DataView(dfd.buffer);
  dfdView.setUint32(0, dfdByteLength, true);
  dfdView.setUint16(4, descriptor.vendorId, true);
  dfdView.setUint16(6, descriptor.descriptorType, true);
  dfdView.setUint16(8, descriptor.versionNumber, true);
  dfdView.setUint16(10, 24 + 16 * descriptor.samples.length, true);
  dfdView.setUint8(12, descriptor.colorModel);
  dfdView.setUint8(13, descriptor.colorPrimaries);
  dfdView.setUint8(14, descriptor.transferFunction);
  dfdView.setUint8(15, descriptor.flags);

  if (!Std.is(descriptor.texelBlockDimension, Array)) {
    throw "texelBlockDimension is now an array. For dimensionality `d`, set `d - 1`.";
  }

  dfdView.setUint8(16, descriptor.texelBlockDimension[0]);
  dfdView.setUint8(17, descriptor.texelBlockDimension[1]);
  dfdView.setUint8(18, descriptor.texelBlockDimension[2]);
  dfdView.setUint8(19, descriptor.texelBlockDimension[3]);
  for (i in 0...8) {
    dfdView.setUint8(20 + i, descriptor.bytesPlane[i]);
  }

  for (i in 0...descriptor.samples.length) {
    var sample = descriptor.samples[i];
    var offset = 28 + 16 * i;

    if (Reflect.hasField(sample, 'channelID')) {
      throw "channelID has been renamed to channelType.";
    }

    dfdView.setUint16(offset + 0, sample.bitOffset, true);
    dfdView.setUint8(offset + 2, sample.bitLength);
    dfdView.setUint8(offset + 3, sample.channelType);
    dfdView.setUint8(offset + 4, sample.samplePosition[0]);
    dfdView.setUint8(offset + 5, sample.samplePosition[1]);
    dfdView.setUint8(offset + 6, sample.samplePosition[2]);
    dfdView.setUint8(offset + 7, sample.samplePosition[3]);

    if ((sample.channelType & 64) != 0) {
      dfdView.setInt32(offset + 8, sample.sampleLower, true);
      dfdView.setInt32(offset + 12, sample.sampleUpper, true);
    } else {
      dfdView.setUint32(offset + 8, sample.sampleLower, true);
      dfdView.setUint32(offset + 12, sample.sampleUpper, true);
    }
  }

  var dfdByteOffset = KTX2_IDENTIFIER.length + 68 + 3 * container.levels.length * 8;
  var kvdByteOffset = dfdByteOffset + dfd.length;
  var sgdByteOffset = sgd != null ? kvdByteOffset + kvd.length : 0;
  var sgdByteLength = sgd != null ? sgd.length : 0;
  var headerByteLength = sgdByteOffset > 0 ? sgdByteOffset + sgdByteLength : kvdByteOffset + kvd.length;
  var paddingByteLength = headerByteLength % 8 != 0 ? 8 - headerByteLength % 8 : 0;
  headerByteLength += paddingByteLength;

  var levelIndex = new DataView(new haxe.io.ArrayBuffer(3 * container.levels.length * 8));
  var levelDataOffset = headerByteLength;
  for (i in 0...container.levels.length) {
    var level = container.levels[i];
    levelIndex.setBigInt64(24 * i + 0, haxe.Int64.ofInt(levelDataOffset), true);
    levelIndex.setBigInt64(24 * i + 8, haxe.Int64.ofInt(level.levelData.length), true);
    levelIndex.setBigInt64(24 * i + 16, level.uncompressedByteLength, true);
    levelDataOffset += level.levelData.length;
  }

  var header = new DataView(new haxe.io.ArrayBuffer(68));
  header.setUint32(0, container.vkFormat, true);
  header.setUint32(4, container.typeSize, true);
  header.setUint32(8, container.pixelWidth, true);
  header.setUint32(12, container.pixelHeight, true);
  header.setUint32(16, container.pixelDepth, true);
  header.setUint32(20, container.layerCount, true);
  header.setUint32(24, container.faceCount, true);
  header.setUint32(28, container.levels.length, true);
  header.setUint32(32, container.supercompressionScheme, true);
  header.setUint32(36, dfdByteOffset, true);
  header.setUint32(40, dfd.length, true);
  header.setUint32(44, kvdByteOffset, true);
  header.setUint32(48, kvd.length, true);
  header.setBigInt64(52, haxe.Int64.ofInt(sgdByteOffset), true);
  header.setBigInt64(60, haxe.Int64.ofInt(sgdByteLength), true);

  var outputArrays = [
    Bytes.ofData(KTX2_IDENTIFIER),
    Bytes.ofData(header.buffer),
    Bytes.ofData(levelIndex.buffer),
    dfd,
    kvd
  ];

  if (sgdByteOffset > 0) {
    outputArrays.push(Bytes.alloc(paddingByteLength));
    outputArrays.push(sgd);
  }

  for (level in container.levels) {
    outputArrays.push(level.levelData);
  }

  return _concatBytes(outputArrays);
}