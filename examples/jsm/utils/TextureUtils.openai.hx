package three.js.utils;

import three.js.core.PlaneGeometry;
import three.js.core.ShaderMaterial;
import three.js.core.Uniform;
import three.js.core.Mesh;
import three.js.core.PerspectiveCamera;
import three.js.core.Scene;
import three.js.renderers.WebGLRenderer;
import three.js.textures.CanvasTexture;
import three.js.enums.SRGBColorSpace;

class TextureUtils {
    private static var _renderer:WebGLRenderer;
    private static var fullscreenQuadGeometry:PlaneGeometry;
    private static var fullscreenQuadMaterial:ShaderMaterial;
    private static var fullscreenQuad:Mesh;

    public static function decompress(texture:Texture, maxTextureSize:Int = Math.POSITIVE_INFINITY, renderer:WebGLRenderer = null):CanvasTexture {
        if (fullscreenQuadGeometry == null) fullscreenQuadGeometry = new PlaneGeometry(2, 2, 1, 1);
        if (fullscreenQuadMaterial == null) fullscreenQuadMaterial = new ShaderMaterial({
            uniforms: {
                blitTexture: new Uniform(texture)
            },
            vertexShader: "
                varying vec2 vUv;
                void main(){
                    vUv = uv;
                    gl_Position = vec4(position.xy * 1.0, 0.0, 0.999999);
                }
            ",
            fragmentShader: "
                uniform sampler2D blitTexture; 
                varying vec2 vUv;

                void main(){ 
                    gl_FragColor = vec4(vUv.xy, 0.0, 1.0);
                    
                    #ifdef IS_SRGB
                    gl_FragColor = LinearTosRGB( texture2D( blitTexture, vUv) );
                    #else
                    gl_FragColor = texture2D( blitTexture, vUv);
                    #endif
                }
            "
        });

        fullscreenQuadMaterial.uniforms.blitTexture.value = texture;
        fullscreenQuadMaterial.defines.IS_SRGB = texture.colorSpace == SRGBColorSpace;
        fullscreenQuadMaterial.needsUpdate = true;

        if (fullscreenQuad == null) {
            fullscreenQuad = new Mesh(fullscreenQuadGeometry, fullscreenQuadMaterial);
            fullscreenQuad.frustumCulled = false;
        }

        var camera:PerspectiveCamera = new PerspectiveCamera();
        var scene:Scene = new Scene();
        scene.add(fullscreenQuad);

        if (renderer == null) {
            renderer = _renderer = new WebGLRenderer({ antialias: false });
        }

        var width:Int = Math.min(texture.image.width, maxTextureSize);
        var height:Int = Math.min(texture.image.height, maxTextureSize);

        renderer.setSize(width, height);
        renderer.clear();
        renderer.render(scene, camera);

        var canvas:js.html.CanvasElement = js.Browser.document.createCanvasElement();
        var context:js.html.CanvasRenderingContext2D = canvas.getContext2d();

        canvas.width = width;
        canvas.height = height;

        context.drawImage(renderer.domElement, 0, 0, width, height);

        var readableTexture:CanvasTexture = new CanvasTexture(canvas);

        readableTexture.minFilter = texture.minFilter;
        readableTexture.magFilter = texture.magFilter;
        readableTexture.wrapS = texture.wrapS;
        readableTexture.wrapT = texture.wrapT;
        readableTexture.name = texture.name;

        if (_renderer != null) {
            _renderer.forceContextLoss();
            _renderer.dispose();
            _renderer = null;
        }

        return readableTexture;
    }
}