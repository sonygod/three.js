package;

import js.three.*;
import js.surfnet.*;

class SDFGeometryGenerator {
    var renderer:WebGLRenderer;

    public function new(renderer:WebGLRenderer) {
        this.renderer = renderer;
    }

    public function generate(res:Int, distFunc:String, bounds:Float) -> BufferGeometry {
        var w:Int, h:Int;
        if (res == 8) {
            w = 32;
            h = 16;
        } else if (res == 16) {
            w = 64;
            h = 64;
        } else if (res == 32) {
            w = 256;
            h = 128;
        } else if (res == 64) {
            w = 512;
            h = 512;
        } else if (res == 128) {
            w = 2048;
            h = 1024;
        } else if (res == 256) {
            w = 4096;
            h = 4096;
        } else if (res == 512) {
            w = 16384;
            h = 8096;
        } else if (res == 1024) {
            w = 32768;
            h = 32768;
        } else {
            throw "Resolution must be in range 8 < res < 1024 and must be ^2";
        }

        var maxTexSize = renderer.capabilities.maxTextureSize;
        if (w > maxTexSize || h > maxTexSize) {
            throw "Your device does not support this resolution (${res}). Decrease [res] param.";
        }

        var tilesX = Std.int(w / res);
        var tilesY = Std.int(h / res);

        var sdfCompute = "
            varying vec2 vUv;
            uniform float tileNum;
            uniform float bounds;
            ${distFunc}
            void main() {
                gl_FragColor = vec4((dist(vec3(vUv, tileNum) * 2.0 * bounds - vec3(bounds)) < 0.00001) ? 1.0 : 0.0);
            }
        ";

        var sdfRT = computeSDF(w, h, tilesX, tilesY, bounds, sdfCompute);

        var read = new Float32Array(w * h * 4);
        renderer.readRenderTargetPixels(sdfRT, 0, 0, w, h, read);
        sdfRT.dispose();

        var mesh = surfaceNet([res, res, res], function(x:Float, y:Float, z:Float):Float {
            x = (x + bounds) * (res / (bounds * 2));
            y = (y + bounds) * (res / (bounds * 2));
            z = (z + bounds) * (res / (bounds * 2));
            var p = (x + (z % tilesX) * res) + y * w + (Std.int(z / tilesX) * res * w);
            p *= 4;
            return (read[p + 3] > 0) ? -0.000000001 : 1;
        }, [[-bounds, -bounds, -bounds], [bounds, bounds, bounds]]);

        var ps = [];
        var ids = [];
        var geometry = new BufferGeometry();
        mesh.positions.forEach(function(p:Float[]) {
            ps.push(p[0], p[1], p[2]);
        });
        mesh.cells.forEach(function(p:Int[]) {
            ids.push(p[0], p[1], p[2]);
        });
        geometry.setAttribute("position", new BufferAttribute(new Float32Array(ps), 3));
        geometry.setIndex(ids);

        return geometry;
    }

    function computeSDF(width:Int, height:Int, tilesX:Int, tilesY:Int, bounds:Float, shader:String) -> WebGLRenderTarget {
        var rt = new WebGLRenderTarget(width, height, {type: FloatType.INSTANCE});
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
            var py = (tileSize) / 2 + Std.int(c / tilesX) * (tileSize) - height / 2;
            var compPlane = new Mesh(geometry, new ShaderMaterial({
                uniforms: {
                    res: {value: new Vector2(width, height)},
                    tileNum: {value: c / (tilesX * tilesY - 1)},
                    bounds: {value: bounds}
                },
                vertexShader: "varying vec2 vUv; void main() { vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }",
                fragmentShader: shader
            }));
            compPlane.position.set(px, py, 0);
            scn.add(compPlane);
        }

        renderer.setRenderTarget(rt);
        renderer.render(scn, cam);
        renderer.setRenderTarget(null);

        geometry.dispose();

        scn.traverse(function(object:Object) {
            if (Reflect.hasField(object, "material")) {
                object.material.dispose();
            }
        });

        return rt;
    }
}