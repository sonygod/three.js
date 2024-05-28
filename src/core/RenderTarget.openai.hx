package three.js.src.core;

import three.js.src.core.EventDispatcher;
import three.js.src.textures.Texture;
import three.js.src.constants.LinearFilter;
import three.js.src.math.Vector4;
import three.js.src.textures.Source;

class RenderTarget extends EventDispatcher {
    
    public var isRenderTarget:Bool;
    public var width:Int;
    public var height:Int;
    public var depth:Int;
    public var scissor:Vector4;
    public var scissorTest:Bool;
    public var viewport:Vector4;
    public var textures:Array<Texture>;
    public var depthBuffer:Bool;
    public var stencilBuffer:Bool;
    public var resolveDepthBuffer:Bool;
    public var resolveStencilBuffer:Bool;
    public var depthTexture:Texture;
    public var samples:Int;

    public function new(width:Int = 1, height:Int = 1, options:Dynamic = {}) {
        super();

        isRenderTarget = true;

        this.width = width;
        this.height = height;
        this.depth = 1;

        scissor = new Vector4(0, 0, width, height);
        scissorTest = false;

        viewport = new Vector4(0, 0, width, height);

        var image:Dynamic = { width: width, height: height, depth: 1 };

        options = Object.assign({
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
        }, options);

        var texture:Texture = new Texture(image, options.mapping, options.wrapS, options.wrapT, options.magFilter, options.minFilter, options.format, options.type, options.anisotropy, options.colorSpace);

        texture.flipY = false;
        texture.generateMipmaps = options.generateMipmaps;
        texture.internalFormat = options.internalFormat;

        textures = [];

        for (i in 0...options.count) {
            textures[i] = texture.clone();
            textures[i].isRenderTargetTexture = true;
        }

        depthBuffer = options.depthBuffer;
        stencilBuffer = options.stencilBuffer;

        resolveDepthBuffer = options.resolveDepthBuffer;
        resolveStencilBuffer = options.resolveStencilBuffer;

        depthTexture = options.depthTexture;

        samples = options.samples;
    }

    public function get_texture():Texture {
        return textures[0];
    }

    public function set_texture(value:Texture) {
        textures[0] = value;
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

        viewport.set(0, 0, width, height);
        scissor.set(0, 0, width, height);
    }

    public function clone():RenderTarget {
        return new RenderTarget().copy(this);
    }

    public function copy(source:RenderTarget) {
        width = source.width;
        height = source.height;
        depth = source.depth;

        scissor.copy(source.scissor);
        scissorTest = source.scissorTest;

        viewport.copy(source.viewport);

        textures.resize(0);

        for (i in 0...source.textures.length) {
            textures[i] = source.textures[i].clone();
            textures[i].isRenderTargetTexture = true;
        }

        var image:Dynamic = Object.assign({}, source.texture.image);
        texture.source = new Source(image);

        depthBuffer = source.depthBuffer;
        stencilBuffer = source.stencilBuffer;

        resolveDepthBuffer = source.resolveDepthBuffer;
        resolveStencilBuffer = source.resolveStencilBuffer;

        if (source.depthTexture != null) depthTexture = source.depthTexture.clone();

        samples = source.samples;

        return this;
    }

    public function dispose() {
        dispatchEvent({ type: 'dispose' });
    }
}

#else
extern class RenderTarget extends EventDispatcher {}
#end