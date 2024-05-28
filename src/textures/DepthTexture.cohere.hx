import js.Browser.Window;
import openfl.display.BitmapData;
import openfl.display3D.Context3DCompareMode;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Rectangle;

class DepthTexture extends TextureBase {
    public isDepthTexture:Bool;
    public image:BitmapData;
    public magFilter:Dynamic;
    public minFilter:Dynamic;
    public flipY:Bool;
    public generateMipmaps:Bool;
    public compareFunction:Context3DCompareMode;

    public function new(width:Int, height:Int, type:Dynamic, mapping:Int, wrapS:Int, wrapT:Int, magFilter:Dynamic, minFilter:Dynamic, anisotropy:Dynamic, format:Context3DTextureFormat = Context3DTextureFormat.DEPTH) {
        if (format != Context3DTextureFormat.DEPTH && format != Context3DTextureFormat.DEPTH_STENCIL) {
            throw $hxExceptions.EInvalidOp("DepthTexture format must be either Context3DTextureFormat.DEPTH or Context3DTextureFormat.DEPTH_STENCIL");
        }
        super(null, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy);
        this.isDepthTexture = true;
        this.image = BitmapData.create(width, height, false, 0xFFFFFFFF);
        this.magFilter = (magFilter != null) ? magFilter : Context3DTextureFilter.NEAREST;
        this.minFilter = (minFilter != null) ? minFilter : Context3DTextureFilter.NEAREST;
        this.flipY = false;
        this.generateMipmaps = false;
        this.compareFunction = null;
    }

    public function copy(source:DepthTexture):Void {
        super.copy(source);
        this.compareFunction = source.compareFunction;
    }

    public function toJSON(meta:Dynamic):Dynamic {
        var data = super.toJSON(meta);
        if (this.compareFunction != null) {
            data.compareFunction = this.compareFunction;
        }
        return data;
    }
}