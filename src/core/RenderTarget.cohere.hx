import haxe.ds.Vector;
import openfl.geom.Rectangle;
import openfl.events.EventDispatcher;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.display3D.textures.TextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Context3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureFilter;
import openfl.display3D.TextureWrap;
import openfl.display3D.VertexBuffer3DDataType;

class RenderTarget extends EventDispatcher {

	public var isRenderTarget:Bool;
	public var width:Int;
	public var height:Int;
	public var depth:Int;
	public var scissor:Rectangle;
	public var scissorTest:Bool;
	public var viewport:Rectangle;
	public var textures:Vector<Texture>;
	public var depthBuffer:Bool;
	public var stencilBuffer:Bool;
	public var resolveDepthBuffer:Bool;
	public var resolveStencilBuffer:Bool;
	public var depthTexture:Texture;
	public var samples:Int;

	public function new(width:Int = 1, height:Int = 1, ?options:Dynamic) {
		super();
		isRenderTarget = true;
		this.width = width;
		this.height = height;
		this.depth = 1;
		scissor = new Rectangle(0, 0, width, height);
		scissorTest = false;
		viewport = new Rectangle(0, 0, width, height);
		textures = new Vector<Texture>();

		var image = { width: width, height: height, depth: 1 };

		options = merge(options, {
			generateMipmaps: false,
			internalFormat: null,
			minFilter: TextureFilter.Linear,
			depthBuffer: true,
			stencilBuffer: false,
			resolveDepthBuffer: true,
			resolveStencilBuffer: true,
			depthTexture: null,
			samples: 0,
			count: 1
		});

		var texture = new Texture(image, options.mapping, options.wrapS, options.wrapT, options.magFilter, options.minFilter, options.format, options.type, options.anisotropy, options.colorSpace);

		texture.flipY = false;
		texture.generateMipmaps = options.generateMipmaps;
		texture.internalFormat = options.internalFormat;

		var count = options.count;
		for (i in 0...count) {
			textures.push(texture.clone());
			textures[i].isRenderTargetTexture = true;
		}

		depthBuffer = options.depthBuffer;
		stencilBuffer = options.stencilBuffer;
		resolveDepthBuffer = options.resolveDepthBuffer;
		resolveStencilBuffer = options.resolveStencilBuffer;
		depthTexture = options.depthTexture;
		samples = options.samples;
	}

	public function setSize(width:Int, height:Int, depth:Int = 1) {
		if (this.width != width || this.height != height || this.depth != depth) {
			this.width = width;
			this.height = height;
			this.depth = depth;

			for (i in 0...textures.length) {
				textures[i].image.width = width;
				textures[i].image.height = height;
				textures[i].image.depth = depth;
			}

			dispose();
		}

		viewport.setTo(0, 0, width, height);
		scissor.setTo(0, 0, width, height);
	}

	public function clone():RenderTarget {
		return new RenderTarget().copy(this);
	}

	public function copy(source:RenderTarget):RenderTarget {
		width = source.width;
		height = source.height;
		depth = source.depth;
		scissor.copyFrom(source.scissor);
		scissorTest = source.scissorTest;
		viewport.copyFrom(source.viewport);
		textures.length = 0;

		for (i in 0...source.textures.length) {
			textures.push(source.textures[i].clone());
			textures[i].isRenderTargetTexture = true;
		}

		var image = source.texture.image.copy();
		texture.source = new TextureBase(image);

		depthBuffer = source.depthBuffer;
		stencilBuffer = source.stencilBuffer;
		resolveDepthBuffer = source.resolveDepthBuffer;
		resolveStencilBuffer = source.resolveStencilBuffer;

		if (source.depthTexture != null) {
			depthTexture = source.depthTexture.clone();
		}

		samples = source.samples;

		return this;
	}

	public function dispose() {
		dispatchEvent(new openfl.events.Event('dispose', true, false));
	}

}

function merge(obj1:Dynamic, obj2:Dynamic):Dynamic {
	var obj3 = obj1.copy();

	for (var key in obj2) {
		obj3[key] = obj2[key];
	}

	return obj3;
}