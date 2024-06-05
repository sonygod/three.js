import EventDispatcher.EventDispatcher;
import Texture.Texture;
import LinearFilter.LinearFilter;
import Vector4.Vector4;
import Source.Source;

/*
 In options, we can specify:
 * Texture parameters for an auto-generated target texture
 * depthBuffer/stencilBuffer: Booleans to indicate if we should generate these buffers
*/
class RenderTarget extends EventDispatcher {

	public var isRenderTarget:Bool = true;

	public var width:Int;
	public var height:Int;
	public var depth:Int = 1;

	public var scissor:Vector4 = new Vector4(0, 0, width, height);
	public var scissorTest:Bool = false;

	public var viewport:Vector4 = new Vector4(0, 0, width, height);

	public var textures:Array<Texture>;

	public var depthBuffer:Bool;
	public var stencilBuffer:Bool;

	public var resolveDepthBuffer:Bool;
	public var resolveStencilBuffer:Bool;

	public var depthTexture:Texture;

	public var samples:Int;

	public function new(width:Int = 1, height:Int = 1, options:Dynamic = {}) {

		super();

		this.width = width;
		this.height = height;

		const image = { width: width, height: height, depth: 1 };

		options = Reflect.setField(Reflect.setField({
			generateMipmaps: false,
			internalFormat: null,
			minFilter: LinearFilter,
			depthBuffer: true,
			stencilBuffer: false,
			resolveDepthBuffer: true,
			resolveStencilBuffer: true,
			depthTexture: null,
			samples: 0,
			count: 1
		}, "mapping", options.mapping), "wrapS", options.wrapS);

		options = Reflect.setField(options, "wrapT", options.wrapT);
		options = Reflect.setField(options, "magFilter", options.magFilter);
		options = Reflect.setField(options, "minFilter", options.minFilter);
		options = Reflect.setField(options, "format", options.format);
		options = Reflect.setField(options, "type", options.type);
		options = Reflect.setField(options, "anisotropy", options.anisotropy);
		options = Reflect.setField(options, "colorSpace", options.colorSpace);

		const texture = new Texture(image, options.mapping, options.wrapS, options.wrapT, options.magFilter, options.minFilter, options.format, options.type, options.anisotropy, options.colorSpace);

		texture.flipY = false;
		texture.generateMipmaps = options.generateMipmaps;
		texture.internalFormat = options.internalFormat;

		this.textures = [];

		const count = options.count;
		for (i in 0...count) {

			this.textures[i] = texture.clone();
			this.textures[i].isRenderTargetTexture = true;

		}

		this.depthBuffer = options.depthBuffer;
		this.stencilBuffer = options.stencilBuffer;

		this.resolveDepthBuffer = options.resolveDepthBuffer;
		this.resolveStencilBuffer = options.resolveStencilBuffer;

		this.depthTexture = options.depthTexture;

		this.samples = options.samples;

	}

	public function get texture():Texture {

		return this.textures[0];

	}

	public function set texture(value:Texture) {

		this.textures[0] = value;

	}

	public function setSize(width:Int, height:Int, depth:Int = 1) {

		if (this.width !== width || this.height !== height || this.depth !== depth) {

			this.width = width;
			this.height = height;
			this.depth = depth;

			for (i in 0...this.textures.length) {

				this.textures[i].image.width = width;
				this.textures[i].image.height = height;
				this.textures[i].image.depth = depth;

			}

			this.dispose();

		}

		this.viewport.set(0, 0, width, height);
		this.scissor.set(0, 0, width, height);

	}

	public function clone():RenderTarget {

		return new this.constructor().copy(this);

	}

	public function copy(source:RenderTarget):RenderTarget {

		this.width = source.width;
		this.height = source.height;
		this.depth = source.depth;

		this.scissor.copy(source.scissor);
		this.scissorTest = source.scissorTest;

		this.viewport.copy(source.viewport);

		this.textures.length = 0;

		for (i in 0...source.textures.length) {

			this.textures[i] = source.textures[i].clone();
			this.textures[i].isRenderTargetTexture = true;

		}

		// ensure image object is not shared, see #20328

		const image = Reflect.copy(source.texture.image);
		this.texture.source = new Source(image);

		this.depthBuffer = source.depthBuffer;
		this.stencilBuffer = source.stencilBuffer;

		this.resolveDepthBuffer = source.resolveDepthBuffer;
		this.resolveStencilBuffer = source.resolveStencilBuffer;

		if (source.depthTexture !== null) this.depthTexture = source.depthTexture.clone();

		this.samples = source.samples;

		return this;

	}

	public function dispose() {

		this.dispatchEvent({ type: 'dispose' });

	}

}

export RenderTarget;