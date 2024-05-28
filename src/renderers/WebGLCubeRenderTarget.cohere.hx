package ;

import openfl.display.DisplayObject;
import openfl.display.IBitmapDrawable;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.EventDispatcher;
import openfl.geom.Rectangle;

class WebGLCubeRenderTarget extends WebGLRenderTarget {
    public var isWebGLCubeRenderTarget:Bool;
    private var image:CubeTextureImage;
    private var images:Array<CubeTextureImage>;
    private var texture:CubeTexture;

    public function new(size:Int = 1, options:Dynamic = null) {
        super(size, size, options);
        isWebGLCubeRenderTarget = true;
        image = { _width: size, _height: size, _depth: 1 };
        images = [image, image, image, image, image, image];
        texture = new CubeTexture(images, options.mapping, options.wrapS, options.wrapT, options.magFilter, options.minFilter, options.format, options.type, options.anisotropy, options.colorSpace);
        texture.isRenderTargetTexture = true;
        texture.generateMipmaps = if (options.generateMipmaps != null) options.generateMipmaps else false;
        texture.minFilter = if (options.minFilter != null) options.minFilter else LinearFilter;
    }

    public function fromEquirectangularTexture(renderer:Renderer, texture:Texture) {
        this.texture.type = texture.type;
        this.texture.colorSpace = texture.colorSpace;
        this.texture.generateMipmaps = texture.generateMipmaps;
        this.texture.minFilter = texture.minFilter;
        this.texture.magFilter = texture.magFilter;
        var shader:Shader = {
            uniforms: {
                tEquirect: { value: null }
            },
            vertexShader: "varying vec3 vWorldDirection;\n\nvec3 transformDirection( in vec3 dir, in mat4 matrix ) {\n\nreturn normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );\n\n}\n\nvoid main() {\n\nvWorldDirection = transformDirection( position, modelMatrix );\n\n#include <begin_vertex>\n#include <project_vertex>\n\n}",
            fragmentShader: "uniform sampler2D tEquirect;\n\nvarying vec3 vWorldDirection;\n\n#include <common>\n\nvoid main() {\n\nvec3 direction = normalize( vWorldDirection );\n\nvec2 sampleUV = equirectUv( direction );\n\ngl_FragColor = texture2D( tEquirect, sampleUV );\n\n}"
        };
        var geometry:BoxGeometry = new BoxGeometry(5, 5, 5);
        var material:ShaderMaterial = new ShaderMaterial({
            name: "CubemapFromEquirect",
            uniforms: cloneUniforms(shader.uniforms),
            vertexShader: shader.vertexShader,
            fragmentShader: shader.fragmentShader,
            side: BackSide,
            blending: NoBlending
        });
        material.uniforms.tEquirect.value = texture;
        var mesh:Mesh = new Mesh(geometry, material);
        var currentMinFilter:Dynamic = texture.minFilter;
        if (texture.minFilter == LinearMipmapLinearFilter) texture.minFilter = LinearFilter;
        var camera:CubeCamera = new CubeCamera(1, 10, this);
        camera.update(renderer, mesh);
        texture.minFilter = currentMinFilter;
        mesh.geometry.dispose();
        mesh.material.dispose();
        return this;
    }

    public function clear(renderer:Renderer, color:Int, depth:Float, stencil:Int) {
        var currentRenderTarget:Dynamic = renderer.getRenderTarget();
        var i:Int;
        for (i = 0; i < 6; i++) {
            renderer.setRenderTarget(this, i);
            renderer.clear(color, depth, stencil);
        }
        renderer.setRenderTarget(currentRenderTarget);
    }
}

class CubeTextureImage {
    public var _width:Int;
    public var _height:Int;
    public var _depth:Int;
}

class CubeTexture extends TextureBase {
    public var isRenderTargetTexture:Bool;
    public var generateMipmaps:Bool;
    public var minFilter:Dynamic;
}

class BoxGeometry extends Geometry {
    public function new(width:Float, height:Float, depth:Float) {
        super();
    }
}

class ShaderMaterial extends Material {
    public var name:String;
    public var uniforms:Dynamic;
    public var vertexShader:String;
    public var fragmentShader:String;
    public var side:Dynamic;
    public var blending:Dynamic;

    public function new(parameters:Dynamic) {
        super();
    }
}

class Mesh extends DisplayObject {
    public function new(geometry:Dynamic = null, material:Dynamic = null) {
        super();
    }
}

class CubeCamera {
    public function update(renderer:Renderer, mesh:Mesh) {
        // Update camera
    }
}

class Renderer extends EventDispatcher implements IBitmapDrawable {
    public function getRenderTarget():Dynamic {
        // Get current render target
    }

    public function setRenderTarget(renderTarget:Dynamic, activeCubeFace:Int) {
        // Set render target
    }

    public function clear(color:Int, depth:Float, stencil:Int) {
        // Clear renderer
    }
}

class Material extends EventDispatcher {
}

class Geometry extends EventDispatcher {
    public function dispose() {
        // Dispose geometry
    }
}

class Shader {
    public var uniforms:Dynamic;
    public var vertexShader:String;
    public var fragmentShader:String;
}

class LinearFilter {
}

class BackSide {
}

class NoBlending {
}

class LinearMipmapLinearFilter {
}