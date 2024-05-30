import Texture.Texture;
import Constants.NearestFilter;
import Constants.UnsignedIntType;
import Constants.UnsignedInt248Type;
import Constants.DepthFormat;
import Constants.DepthStencilFormat;

class DepthTexture extends Texture {

    public var isDepthTexture(default, null):Bool;
    public var image(default, null):Dynamic;
    public var magFilter(default, null):NearestFilter;
    public var minFilter(default, null):NearestFilter;
    public var flipY(default, null):Bool;
    public var generateMipmaps(default, null):Bool;
    public var compareFunction(default, null):Dynamic;

    public function new(width:Int, height:Int, type:Dynamic, mapping:Dynamic, wrapS:Dynamic, wrapT:Dynamic, magFilter:NearestFilter, minFilter:NearestFilter, anisotropy:Dynamic, format:Dynamic = DepthFormat) {

        if (format !== DepthFormat && format !== DepthStencilFormat) {

            throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");

        }

        if (type == null && format == DepthFormat) type = UnsignedIntType;
        if (type == null && format == DepthStencilFormat) type = UnsignedInt248Type;

        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);

        this.isDepthTexture = true;

        this.image = { width: width, height: height };

        this.magFilter = magFilter != null ? magFilter : NearestFilter;
        this.minFilter = minFilter != null ? minFilter : NearestFilter;

        this.flipY = false;
        this.generateMipmaps = false;

        this.compareFunction = null;

    }

    public function copy(source:DepthTexture):DepthTexture {

        super.copy(source);

        this.compareFunction = source.compareFunction;

        return this;

    }

    public function toJSON(meta:Dynamic):Dynamic {

        var data = super.toJSON(meta);

        if (this.compareFunction != null) data.compareFunction = this.compareFunction;

        return data;

    }

}

export DepthTexture;