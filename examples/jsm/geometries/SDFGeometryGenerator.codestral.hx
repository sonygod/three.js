// SDFGeometryGenerator.hx

import js.three.BufferAttribute;
import js.three.BufferGeometry;
import js.three.FloatType;
import js.three.Mesh;
import js.three.OrthographicCamera;
import js.three.PlaneGeometry;
import js.three.Scene;
import js.three.ShaderMaterial;
import js.three.Vector2;
import js.three.WebGLRenderTarget;
import js.three.WebGLRenderer;

import js.surfaceNet.surfaceNet;

class SDFGeometryGenerator {

    var renderer:WebGLRenderer;

    public function new(renderer:WebGLRenderer) {
        this.renderer = renderer;
    }

    public function generate(res:Int = 64, distFunc:String = 'float dist( vec3 p ){ return length(p) - 0.5; }', bounds:Float = 1.0):BufferGeometry {
        var w:Int;
        var h:Int;
        switch (res) {
            case 8:
                w = 32;
                h = 16;
                break;
            case 16:
                w = 64;
                h = 64;
                break;
            case 32:
                w = 256;
                h = 128;
                break;
            case 64:
                w = 512;
                h = 512;
                break;
            case 128:
                w = 2048;
                h = 1024;
                break;
            case 256:
                w = 4096;
                h = 4096;
                break;
            case 512:
                w = 16384;
                h = 8096;
                break;
            case 1024:
                w = 32768;
                h = 32768;
                break;
            default:
                throw new Error('THREE.SDFGeometryGenerator: Resolution must be in range 8 < res < 1024 and must be ^2');
        }

        var maxTexSize = this.renderer.capabilities.maxTextureSize;

        if (w > maxTexSize || h > maxTexSize) {
            throw new Error('THREE.SDFGeometryGenerator: Your device does not support this resolution ( ' + res + ' ), decrease [res] param.');
        }

        var tilesX = (w / res);
        var tilesY = (h / res);

        var sdfCompute = 'varying vec2 vUv;uniform float tileNum;uniform float bounds;[#dist#]void main()	{ gl_FragColor=vec4( ( dist( vec3( vUv, tileNum ) * 2.0 * bounds - vec3( bounds ) ) < 0.00001 ) ? 1.0 : 0.0 ); }';

        var sdfRT = this.computeSDF(w, h, tilesX, tilesY, bounds, sdfCompute.replace('[#dist#]', distFunc));

        var read = new Float32Array(w * h * 4);
        this.renderer.readRenderTargetPixels(sdfRT, 0, 0, w, h, read);
        sdfRT.dispose();

        var mesh = surfaceNet([res, res, res], (x, y, z) => {
            x = (x + bounds) * (res / (bounds * 2));
            y = (y + bounds) * (res / (bounds * 2));
            z = (z + bounds) * (res / (bounds * 2));
            var p = (x + (z % tilesX) * res) + y * w + (Std.int(Math.floor(z / tilesX)) * res * w);
            p *= 4;
            return (read[p + 3] > 0) ? -0.000000001 : 1;
        }, [[-bounds, -bounds, -bounds], [bounds, bounds, bounds]]);

        var ps = [];
        var ids = [];
        var geometry = new BufferGeometry();
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
        var rt = new WebGLRenderTarget(width, height, {type: FloatType});
        var scn = new Scene();
        var cam = new OrthographicCamera();
        var tiles = tilesX * tilesY;
        var currentTile = 0;

        cam.left = width / -2;
        cam.right = width / 2;
        cam.top = height / 2;
        cam.bottom = height / -2;
        cam.updateProjectionMatrix();
        cam.position.z = 2;

        var tileSize = width / tilesX;
        var geometry = new PlaneGeometry(tileSize, tileSize);

        while (currentTile++ < tiles) {
            var c = currentTile - 1;
            var px = (tileSize) / 2 + (c % tilesX) * (tileSize) - width / 2;
            var py = (tileSize) / 2 + Std.int(Math.floor(c / tilesX)) * (tileSize) - height / 2;
            var compPlane = new Mesh(geometry, new ShaderMaterial({
                uniforms: {
                    res: {value: new Vector2(width, height)},
                    tileNum: {value: c / (tilesX * tilesY - 1)},
                    bounds: {value: bounds}
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

        scn.traverse(function (object) {
            if (object.material !== null) {
                object.material.dispose();
            }
        });

        return rt;
    }
}