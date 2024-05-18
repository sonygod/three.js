package three.textures;

import three.textures.Texture;
import three.constants.NearestFilter;
import three.constants.UnsignedIntType;
import three.constants.UnsignedInt248Type;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;

class DepthTexture extends Texture {
    public var isDepthTexture:Bool;
    public var image:{ width:Int, height:Int };
    public var compareFunction:Null<Dynamic>;

    public function new(width:Int, height:Int, type:Null<Dynamic> = null, mapping:Null<Dynamic> = null, wrapS:Null<Dynamic> = null, wrapT:Null<Dynamic> = null, magFilter:Null<Dynamic> = null, minFilter:Null<Dynamic> = null, anisotropy:Null<Dynamic> = null, format:Dynamic = DepthFormat) {
        if (format != DepthFormat && format != DepthStencilFormat) {
            throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");
        }

        if (type == null && format == DepthFormat) type = UnsignedIntType;
        if (type == null && format == DepthStencilFormat) type = UnsignedInt248Type;

        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        isDepthTexture = true;

        image = { width: width, height: height };

        magFilter = (magFilter != null) ? magFilter : NearestFilter;
        minFilter = (minFilter != null) ? minFilter : NearestFilter;

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
        var data = super.toJSON(meta);

        if (compareFunction != null) data.compareFunction = compareFunction;

        return data;
    }
}