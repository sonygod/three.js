import three.textures.Texture;
import three.constants.NearestFilter;
import three.constants.UnsignedIntType;
import three.constants.UnsignedInt248Type;
import three.constants.DepthFormat;
import three.constants.DepthStencilFormat;

class DepthTexture extends Texture {

    public var isDepthTexture:Bool;
    public var compareFunction:Dynamic;
    public var image:{ var width:Int; var height:Int; };

    public function new(width:Int, height:Int, ?type:Dynamic, ?mapping:Dynamic, ?wrapS:Dynamic, ?wrapT:Dynamic, ?magFilter:Dynamic, ?minFilter:Dynamic, ?anisotropy:Dynamic, ?format:Dynamic = DepthFormat) {

        if (format != DepthFormat && format != DepthStencilFormat) {
            throw "DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat";
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

        if (this.compareFunction != null) {
            data.compareFunction = this.compareFunction;
        }

        return data;
    }
}