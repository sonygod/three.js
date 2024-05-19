import js.three.EventDispatcher;
import js.three.textures.Texture;
import js.three.constants.LinearFilter;
import js.three.math.Vector4;
import js.three.textures.Source;

class RenderTarget extends EventDispatcher {
    public var width(default, null):Int;
    public var height(default, null):Int;
    public var depth(default, null):Int;
    public var scissor(default, null):Vector4;
    public var scissorTest(default, null):Bool;
    public var viewport(default, null):Vector4;
    public var textures:Array<Texture>;
    public var depthBuffer(default, null):Bool;
    public var stencilBuffer(default, null):Bool;
    public var resolveDepthBuffer(default, null):Bool;
    public var resolveStencilBuffer(default, null):Bool;
    public var depthTexture(default, null):Texture;
    public var samples(default, null):Int;
    
    public function new(width:Int = 1, height:Int = 1, options:Dynamic = {}) {
        super();
        
        this.isRenderTarget = true;
        
        this.width = width;
        this.height = height;
        this.depth = 1;
        
        this.scissor = new Vector4(0, 0, width, height);
        this.scissorTest = false;
        
        this.viewport = new Vector4(0, 0, width, height);
        
        var image = { width: width, height: height, depth: 1 };
        
        options = { 
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
        };
        
        var texture = new Texture(image, options.mapping, options.wrapS, options.wrapT, options.magFilter, options.minFilter, options.format, options.type, options.anisotropy, options.colorSpace);
        
        texture.flipY = false;
        texture.generateMipmaps = options.generateMipmaps;
        texture.internalFormat = options.internalFormat;
        
        this.textures = [];
        
        var count = options.count;
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
    
    public function get_texture():Texture {
        return this.textures[0];
    }
    
    public function set_texture(value:Texture):Void {
        this.textures[0] = value;
    }
    
    public function setSize(width:Int, height:Int, depth:Int = 1):Void {
        if (this.width != width || this.height != height || this.depth != depth) {
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
        
        this.textures = [];
        
        for (i in 0...source.textures.length) {
            this.textures[i] = source.textures[i].clone();
            this.textures[i].isRenderTargetTexture = true;
        }
        
        // ensure image object is not shared, see #20328
        
        var image = { }.fromObject(source.texture.image);
        this.texture.source = new Source(image);
        
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
    
    public function dispose():Void {
        this.dispatchEvent({ type: 'dispose' });
    }
}

    export { RenderTarget };