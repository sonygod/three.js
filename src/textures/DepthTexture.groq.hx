package three.js.src.textures;

import three.js.src.textures.Texture;

class DepthTexture extends Texture {
    public var isDepthTexture:Bool;
    public var image:{ width:Int, height:Int };
    public var flipY:Bool;
    public var generateMipmaps:Bool;
    public var compareFunction:Null<Int>;

    public function new(width:Int, height:Int, type:Null<Int>, mapping:Null<Int>, wrapS:Null<Int>, wrapT:Null<Int>, magFilter:Null<Int>, minFilter:Null<Int>, anisotropy:Null<Float>, format:Int = DepthFormat) {
        if (format != DepthFormat && format != DepthStencilFormat) {
            throw new Error('DepthTexture format must be either DepthFormat or DepthStencilFormat');
        }

        if (type == null && format == DepthFormat) type = UnsignedIntType;
        if (type == null && format == DepthStencilFormat) type = UnsignedInt248Type;

        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        isDepthTexture = true;

        image = { width: width, height: height };

        magFilter = magFilter != null ? magFilter : NearestFilter;
        minFilter = minFilter != null ? minFilter : NearestFilter;

        flipY = false;
        generateMipmaps = false;

        compareFunction = null;
    }

    public function copy(source:DepthTexture):DepthTexture {
        super.copy(source);

        compareFunction = source.compareFunction;

        return this;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data:Dynamic = super.toJSON(meta);

        if (compareFunction != null) data.compareFunction = compareFunction;

        return data;
    }
}