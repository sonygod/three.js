import three.core.BufferGeometry;
import three.core.BufferAttribute;
import three.math.Vector2;
import three.scenes.Scene;
import three.renderers.WebGLRenderer;
import three.cameras.OrthographicCamera;
import three.geometries.PlaneGeometry;
import three.materials.ShaderMaterial;
import three.objects.Mesh;
import three.renderers.WebGLRenderTarget;
import three.math.Color;
import three.textures.Texture;
import three.textures.DataTexture;
import three.textures.TextureEncoding;
import three.math.Matrix4;

import surfaceNet from "surfaceNet";

class SDFGeometryGenerator {
	public var renderer:WebGLRenderer;

	public function new(renderer:WebGLRenderer) {
		this.renderer = renderer;
	}

	public function generate(res:Int = 64, distFunc:String = 'float dist( vec3 p ){ return length(p) - 0.5; }', bounds:Float = 1):BufferGeometry {
		var w:Int, h:Int;
		switch (res) {
			case 8:
				[w, h] = [32, 16];
			case 16:
				[w, h] = [64, 64];
			case 32:
				[w, h] = [256, 128];
			case 64:
				[w, h] = [512, 512];
			case 128:
				[w, h] = [2048, 1024];
			case 256:
				[w, h] = [4096, 4096];
			case 512:
				[w, h] = [16384, 8096];
			case 1024:
				[w, h] = [32768, 32768];
			default:
				throw new Error("THREE.SDFGeometryGenerator: Resolution must be in range 8 < res < 1024 and must be ^2");
		}

		var maxTexSize = renderer.capabilities.maxTextureSize;

		if (w > maxTexSize || h > maxTexSize) throw new Error("THREE.SDFGeometryGenerator: Your device does not support this resolution ( " + res + " ), decrease [res] param.");

		var [tilesX, tilesY] = [(w / res), (h / res)];

		var sdfCompute = `
			varying vec2 vUv;
			uniform float tileNum;
			uniform float bounds;
			[#dist#]
			void main()	{ gl_FragColor=vec4( ( dist( vec3( vUv, tileNum ) * 2.0 * bounds - vec3( bounds ) ) < 0.00001 ) ? 1.0 : 0.0 ); }
		`;

		var sdfRT = computeSDF(w, h, tilesX, tilesY, bounds, sdfCompute.replace("[#dist#]", distFunc));

		var read = new Float32Array(w * h * 4);
		renderer.readRenderTargetPixels(sdfRT, 0, 0, w, h, read);
		sdfRT.dispose();

		//

		var mesh = surfaceNet([res, res, res], (x, y, z) -> {
			x = (x + bounds) * (res / (bounds * 2));
			y = (y + bounds) * (res / (bounds * 2));
			z = (z + bounds) * (res / (bounds * 2));
			var p = (x + (z % tilesX) * res) + y * w + (Math.floor(z / tilesX) * res * w);
			p *= 4;
			return (read[p + 3] > 0) ? -0.000000001 : 1;
		}, [[-bounds, -bounds, -bounds], [bounds, bounds, bounds]]);

		var ps:Array<Float> = [];
		var ids:Array<Int> = [];
		var geometry = new BufferGeometry();
		mesh.positions.forEach((p) -> {
			ps.push(p[0], p[1], p[2]);
		});
		mesh.cells.forEach((p) -> ids.push(p[0], p[1], p[2]));
		geometry.setAttribute("position", new BufferAttribute(new Float32Array(ps), 3));
		geometry.setIndex(ids);

		return geometry;
	}

	public function computeSDF(width:Int, height:Int, tilesX:Float, tilesY:Float, bounds:Float, shader:String):WebGLRenderTarget {
		var rt = new WebGLRenderTarget(width, height, {type: TextureEncoding.Linear});
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
			var [px, py] = [(tileSize) / 2 + (c % tilesX) * (tileSize) - width / 2, (tileSize) / 2 + Math.floor(c / tilesX) * (tileSize) - height / 2];
			var compPlane = new Mesh(geometry, new ShaderMaterial({
				uniforms: {
					res: {value: new Vector2(width, height)},
					tileNum: {value: c / (tilesX * tilesY - 1)},
					bounds: {value: bounds}
				},
				vertexShader: "varying vec2 vUv;void main(){vUv=uv;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}",
				fragmentShader: shader
			}));
			compPlane.position.set(px, py, 0);
			scn.add(compPlane);
		}

		renderer.setRenderTarget(rt);
		renderer.render(scn, cam);
		renderer.setRenderTarget(null);

		//

		geometry.dispose();

		scn.traverse(function(object) {
			if (object.material != null) object.material.dispose();
		});

		return rt;
	}
}