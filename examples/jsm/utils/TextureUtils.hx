Here is the equivalent Haxe code for the given JavaScript code:
```
package three.js.examples.javascript.utils;

import three.js.*;

class TextureUtils {
    static var _renderer:WebGLRenderer;
    static var fullscreenQuadGeometry:PlaneGeometry;
    static var fullscreenQuadMaterial:ShaderMaterial;
    static var fullscreenQuad:Mesh;

    public static function decompress(texture:Texture, maxTextureSize:Float = Math.POSITIVE_INFINITY, renderer:WebGLRenderer = null) {
        if (fullscreenQuadGeometry == null) fullscreenQuadGeometry = new PlaneGeometry(2, 2, 1, 1);
        if (fullscreenQuadMaterial == null) {
            fullscreenQuadMaterial = new ShaderMaterial({
                uniforms: {
                    blitTexture: {
                        value: texture
                    }
                },
                vertexShader: "
                    varying vec2 vUv;
                    void main(){
                        vUv = uv;
                        gl_Position = vec4(position.xy * 1.0,0.,.999999);
                    }
                ",
                fragmentShader: "
                    uniform sampler2D blitTexture; 
                    varying vec2 vUv;

                    void main(){ 
                        gl_FragColor = vec4(vUv.xy, 0, 1);
                        
                        #ifdef IS_SRGB
                        gl_FragColor = LinearTosRGB( texture2D( blitTexture, vUv) );
                        #else
                        gl_FragColor = texture2D( blitTexture, vUv);
                        #endif
                    }
                "
            });
        }

        fullscreenQuadMaterial.uniforms.blitTexture.value = texture;
        fullscreenQuadMaterial.defines.IS_SRGB = texture.colorSpace == SRGBColorSpace;
        fullscreenQuadMaterial.needsUpdate = true;

        if (fullscreenQuad == null) {
            fullscreenQuad = new Mesh(fullscreenQuadGeometry, fullscreenQuadMaterial);
            fullscreenQuad.frustumCulled = false;
        }

        var camera = new PerspectiveCamera();
        var scene = new Scene();
        scene.add(fullscreenQuad);

        if (renderer == null) {
            renderer = _renderer = new WebGLRenderer({ antialias: false });
        }

        var width = Math.min(texture.image.width, maxTextureSize);
        var height = Math.min(texture.image.height, maxTextureSize);

        renderer.setSize(width, height);
        renderer.clear();
        renderer.render(scene, camera);

        var canvas = js.Browser.document.createElement("canvas");
        var context = canvas.getContext("2d");

        canvas.width = width;
        canvas.height = height;

        context.drawImage(renderer.domElement, 0, 0, width, height);

        var readableTexture = new CanvasTexture(canvas);

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
```
Note that I had to make some assumptions about the Haxe externs for Three.js, as they are not officially supported. You may need to adjust the code to fit your specific setup.

Also, I replaced `document.createElement` with `js.Browser.document.createElement` to use the Haxe JavaScript externs.

Please test and verify that this code works as expected in your Haxe environment.