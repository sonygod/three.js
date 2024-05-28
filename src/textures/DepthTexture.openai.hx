package three.textures;

import three.Texture;

class DepthTexture extends Texture {
    public var isDepthTexture:Bool = true;
    public var image:{ width:Int, height:Int };
    public var compareFunction:Null<Int>;

    public function new(width:Int, height:Int, type:Null<Int>, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Int, minFilter:Int, anisotropy:Float, format:Int = DepthFormat) {
        if (format != DepthFormat && format != DepthStencilFormat) {
            throw new Error('DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat');
        }

        if (type == null && format == DepthFormat) type = UnsignedIntType;
        if (type == null && format == DepthStencilFormat) type = UnsignedInt248Type;

        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        image = { width: width, height: height };

        magFilter = magFilter != null ? magFilter : NearestFilter;
        minFilter = minFilter != null ? minFilter : NearestFilter;

        flipY = false;
        generateMipmaps = false;
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