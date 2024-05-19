package three.js.examples.jsm.geometries;

import three.js.BufferAttribute;
import three.js.BufferGeometry;
import three.js.FloatType;
import three.js.Mesh;
import three.js.OrthographicCamera;
import three.js.PlaneGeometry;
import three.js.Scene;
import three.js.ShaderMaterial;
import three.js.Vector2;
import three.js.WebGLRenderTarget;

class SDFGeometryGenerator {
    public var renderer:three.js.Renderer;

    public function new(renderer:three.js.Renderer) {
        this.renderer = renderer;
    }

    public function generate(?res:Int = 64, ?distFunc:String = 'float dist( vec3 p ){ return length(p) - 0.5; }', ?bounds:Float = 1):BufferGeometry {
        var w:Int, h:Int;
        switch (res) {
            case 8:
                w = 32; h = 16;
            case 16:
                w = 64; h = 64;
            case 32:
                w = 256; h = 128;
            case 64:
                w = 512; h = 512;
            case 128:
                w = 2048; h = 1024;
            case 256:
                w = 4096; h = 4096;
            case 512:
                w = 16384; h = 8096;
            case 1024:
                w = 32768; h = 32768;
            default:
                throw new Error('THREE.SDFGeometryGenerator: Resolution must be in range 8 < res < 1024 and must be ^2');
        }

        var maxTexSize:Int = this.renderer.capabilities.maxTextureSize;

        if (w > maxTexSize || h > maxTexSize) {
            throw new Error('THREE.SDFGeometryGenerator: Your device does not support this resolution ( ' + res + ' ), decrease [res] param.');
        }

        var tilesX:Int = Std.int(w / res);
        var tilesY:Int = Std.int(h / res);

        var sdfCompute:String = '
            varying vec2 vUv;
            uniform float tileNum;
            uniform float bounds;
            [#dist#]
            void main()	{ gl_FragColor=vec4( ( dist( vec3( vUv, tileNum ) * 2.0 * bounds - vec3( bounds ) ) < 0.00001 ) ? 1.0 : 0.0 ); }
        ';

        var sdfRT:WebGLRenderTarget = computeSDF(w, h, tilesX, tilesY, bounds, sdfCompute.replace('[#dist#]', distFunc));

        var read:Array<Float> = new Array<Float>();
        for (i in 0...w * h * 4) {
            read.push(0);
        }
        this.renderer.readRenderTargetPixels(sdfRT, 0, 0, w, h, read);
        sdfRT.dispose();

        var mesh:Array<Array<Float>> = surfaceNet([res, res, res], function(x:Float, y:Float, z:Float):Float {
            x = (x + bounds) * (res / (bounds * 2));
            y = (y + bounds) * (res / (bounds * 2));
            z = (z + bounds) * (res / (bounds * 2));
            var p:Int = Std.int((x + (z % tilesX) * res) + y * w + (Std.int(z / tilesX) * res * w));
            p *= 4;
            return (read[p + 3] > 0) ? -0.000000001 : 1;
        }, [[-bounds, -bounds, -bounds], [bounds, bounds, bounds]]);

        var ps:Array<Float> = [];
        var ids:Array<Int> = [];
        var geometry:BufferGeometry = new BufferGeometry();
        for (p in mesh.positions) {
            ps.push(p[0], p[1], p[2]);
        }
        for (p in mesh.cells) {
            ids.push(p[0], p[1], p[2]);
        }
        geometry.setAttribute('position', new BufferAttribute(new Float32Array(ps), 3));
        geometry.setIndex(ids);

        return geometry;
    }

    private function computeSDF(width:Int, height:Int, tilesX:Int, tilesY:Int, bounds:Float, shader:String):WebGLRenderTarget {
        var rt:WebGLRenderTarget = new WebGLRenderTarget(width, height, { type: FloatType });
        var scn:Scene = new Scene();
        var cam:OrthographicCamera = new OrthographicCamera();
        var tiles:Int = tilesX * tilesY;
        var currentTile:Int = 0;

        cam.left = -width / 2;
        cam.right = width / 2;
        cam.top = height / 2;
        cam.bottom = -height / 2;
        cam.updateProjectionMatrix();
        cam.position.z = 2;

        var tileSize:Float = width / tilesX;
        var geometry:PlaneGeometry = new PlaneGeometry(tileSize, tileSize);

        while (currentTile++ < tiles) {
            var c:Int = currentTile - 1;
            var px:Float = (tileSize) / 2 + (c % tilesX) * (tileSize) - width / 2;
            var py:Float = (tileSize) / 2 + Std.int(c / tilesX) * (tileSize) - height / 2;
            var compPlane:Mesh = new Mesh(geometry, new ShaderMaterial({
                uniforms: {
                    res: { value: new Vector2(width, height) },
                    tileNum: { value: c / (tilesX * tilesY - 1) },
                    bounds: { value: bounds }
                },
                vertexShader: 'varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}',
                fragmentShader: shader
            }));
            compPlane.position.set(px, py, 0);
            scn.add(compPlane);
        }

        this.renderer.setRenderTarget(rt);
        this.renderer.render(scn, cam);
        this.renderer.setRenderTarget(null);

        geometry.dispose();

        scn.traverse(function(object:Mesh) {
            if (object.material != null) object.material.dispose();
        });

        return rt;
    }
}