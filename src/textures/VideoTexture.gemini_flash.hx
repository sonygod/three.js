package;

import three.textures.Texture;
import three.textures.TextureMapping;
import three.textures.Wrapping;
import three.textures.TextureFilter;
import three.textures.PixelFormat;
import three.textures.PixelType;
import js.html.VideoElement;

class VideoTexture extends Texture {

	public var isVideoTexture(default,null) : Bool;

	public function new( video : VideoElement, mapping : TextureMapping, wrapS : Wrapping, wrapT : Wrapping, magFilter : TextureFilter, minFilter : TextureFilter, format : PixelFormat, type : PixelType, anisotropy : Int ) {

		super( video, mapping, wrapS, wrapT, magFilter, minFilter, format, type, anisotropy );

		this.isVideoTexture = true;

		this.minFilter = ( minFilter != null ) ? minFilter : TextureFilter.LinearFilter;
		this.magFilter = ( magFilter != null ) ? magFilter : TextureFilter.LinearFilter;

		this.generateMipmaps = false;

		var scope = this;

		function updateVideo() {
			scope.needsUpdate = true;
			video.requestVideoFrameCallback( updateVideo );
		}

		if ( Reflect.hasField(video, "requestVideoFrameCallback") ) {
			video.requestVideoFrameCallback( updateVideo );
		}

	}

	public function clone() : VideoTexture {

		return new VideoTexture( this.image, this.mapping, this.wrapS, this.wrapT, this.magFilter, this.minFilter, this.format, this.type, this.anisotropy );

	}

	override public function update() : Void {

		var video : VideoElement = cast this.image;
		var hasVideoFrameCallback = Reflect.hasField(video, "requestVideoFrameCallback");

		if ( !hasVideoFrameCallback && video.readyState >= video.HAVE_CURRENT_DATA ) {
			this.needsUpdate = true;
		}

	}

}