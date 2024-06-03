import haxe.ds.Vector;
import haxe.ui.EventDispatcher;
import openfl.display.BitmapData;
import openfl.display.IBitmapDrawable;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.IMemoryRange;
import openfl.utils.Rectangle;
import openfl.utils.Vector;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.IMemoryRange;
import openfl.utils.Rectangle;
import openfl.utils.Vector;
import openfl.display.BitmapData;
import openfl.display.IBitmapDrawable;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Transform;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.geom.Transform;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.IMemoryRange;
import openfl.utils.Rectangle;
import openfl.utils.Vector;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.geom.Transform;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.IMemoryRange;
import openfl.utils.Rectangle;
import openfl.utils.Vector;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Matrix;
import openfl.geom.Transform;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.InteractiveObject;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.IMemoryRange;
import openfl.utils.Rectangle;
import openfl.utils.Vector;
import openfl.text.TextField;
import openfl.text.TextFormat;

class RenderTarget extends EventDispatcher {

	public var isRenderTarget : Bool = true;
	public var width : Int;
	public var height : Int;
	public var depth : Int;
	public var scissor : Vector<Float>;
	public var scissorTest : Bool;
	public var viewport : Vector<Float>;
	public var textures : Array<BitmapData>;
	public var depthBuffer : Bool;
	public var stencilBuffer : Bool;
	public var resolveDepthBuffer : Bool;
	public var resolveStencilBuffer : Bool;
	public var depthTexture : BitmapData;
	public var samples : Int;

	public function new(width:Int = 1, height:Int = 1, options:Dynamic = null) {
		super();
		this.width = width;
		this.height = height;
		this.depth = 1;
		this.scissor = new Vector<Float>(0, 0, width, height);
		this.scissorTest = false;
		this.viewport = new Vector<Float>(0, 0, width, height);
		options = (options != null) ? options : {};
		var generateMipmaps = (options.generateMipmaps != null) ? options.generateMipmaps : false;
		var internalFormat = (options.internalFormat != null) ? options.internalFormat : null;
		var minFilter = (options.minFilter != null) ? options.minFilter : 0;
		var depthBuffer = (options.depthBuffer != null) ? options.depthBuffer : true;
		var stencilBuffer = (options.stencilBuffer != null) ? options.stencilBuffer : false;
		var resolveDepthBuffer = (options.resolveDepthBuffer != null) ? options.resolveDepthBuffer : true;
		var resolveStencilBuffer = (options.resolveStencilBuffer != null) ? options.resolveStencilBuffer : true;
		var depthTexture = (options.depthTexture != null) ? options.depthTexture : null;
		var samples = (options.samples != null) ? options.samples : 0;
		var count = (options.count != null) ? options.count : 1;
		this.textures = new Array();
		for (var i = 0; i < count; i++) {
			var texture = new BitmapData(width, height);
			texture.generateMipmaps = generateMipmaps;
			texture.internalFormat = internalFormat;
			texture.minFilter = minFilter;
			this.textures.push(texture);
		}
		this.depthBuffer = depthBuffer;
		this.stencilBuffer = stencilBuffer;
		this.resolveDepthBuffer = resolveDepthBuffer;
		this.resolveStencilBuffer = resolveStencilBuffer;
		this.depthTexture = depthTexture;
		this.samples = samples;
	}

	public function get texture() : BitmapData {
		return this.textures[0];
	}

	public function set texture(value:BitmapData) {
		this.textures[0] = value;
	}

	public function setSize(width:Int, height:Int, depth:Int = 1) {
		if (this.width != width || this.height != height || this.depth != depth) {
			this.width = width;
			this.height = height;
			this.depth = depth;
			for (var i = 0; i < this.textures.length; i++) {
				this.textures[i].width = width;
				this.textures[i].height = height;
			}
			this.dispose();
		}
		this.viewport.set(0, 0, width, height);
		this.scissor.set(0, 0, width, height);
	}

	public function clone() : RenderTarget {
		return new RenderTarget().copy(this);
	}

	public function copy(source:RenderTarget) : RenderTarget {
		this.width = source.width;
		this.height = source.height;
		this.depth = source.depth;
		this.scissor.copy(source.scissor);
		this.scissorTest = source.scissorTest;
		this.viewport.copy(source.viewport);
		this.textures = new Array();
		for (var i = 0; i < source.textures.length; i++) {
			this.textures.push(source.textures[i].clone());
		}
		this.depthBuffer = source.depthBuffer;
		this.stencilBuffer = source.stencilBuffer;
		this.resolveDepthBuffer = source.resolveDepthBuffer;
		this.resolveStencilBuffer = source.resolveStencilBuffer;
		if (source.depthTexture != null) {
			this.depthTexture = source.depthTexture.clone();
		}
		this.samples = source.samples;
		return this;
	}

	public function dispose() {
		this.dispatchEvent(new Event("dispose"));
	}

}