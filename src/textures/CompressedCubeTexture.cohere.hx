package ;

import openfl.display.DisplayObject;
import openfl.display3D.Context3DTextureFilter;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.CubeTexture;
import openfl.events.EventDispatcher;
import openfl.utils.ByteArrayData;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;

class CompressedCubeTexture extends CompressedTexture {

	public var isCompressedCubeTexture:Bool;
	public var isCubeTexture:Bool;
	public var image:Array<BitmapData>;

	public function new(images:Array<BitmapData>, format:String, type:String) {
		super(undefined, images[0].width, images[0].height, format, type, CubeReflectionMapping);
		isCompressedCubeTexture = true;
		isCubeTexture = true;
		image = images;
	}

}