import threejsLessonUtils from "threejs-lesson-utils";
import three from "three";

class Main {

	static function makeSphere( widthDivisions: Int, heightDivisions: Int ): three.SphereGeometry {
		var radius = 7;
		return new three.SphereGeometry(radius, widthDivisions, heightDivisions);
	}

	static var highPolySphereGeometry: three.SphereGeometry = function() {
		var widthDivisions = 100;
		var heightDivisions = 50;
		return makeSphere(widthDivisions, heightDivisions);
	}();

	static var lowPolySphereGeometry: three.SphereGeometry = function() {
		var widthDivisions = 12;
		var heightDivisions = 9;
		return makeSphere(widthDivisions, heightDivisions);
	}();

	static function smoothOrFlat( flatShading: Bool, radius: Float = 7 ): three.Mesh {
		var widthDivisions = 12;
		var heightDivisions = 9;
		var geometry = new three.SphereGeometry(radius, widthDivisions, heightDivisions);
		var material = new three.MeshPhongMaterial({
			flatShading: flatShading,
			color: "hsl(300,50%,50%)",
		});
		return new three.Mesh(geometry, material);
	}

	static function basicLambertPhongExample( MaterialCtor: Class<three.Material>, lowPoly: Bool = false, params: Dynamic = {} ): {obj3D: three.Mesh, trackball: Bool} {
		var geometry = lowPoly ? lowPolySphereGeometry : highPolySphereGeometry;
		var material = new MaterialCtor({
			color: "hsl(210,50%,50%)",
			...params,
		});
		return {
			obj3D: new three.Mesh(geometry, material),
			trackball: lowPoly,
		};
	}

	static function sideExample( side: Int ): three.Object3D {
		var base = new three.Object3D();
		var size = 6;
		var geometry = new three.PlaneGeometry(size, size);
		[
			{position: [-1, 0, 0], up: [0, 1, 0]},
			{position: [1, 0, 0], up: [0, -1, 0]},
			{position: [0, -1, 0], up: [0, 0, -1]},
			{position: [0, 1, 0], up: [0, 0, 1]},
			{position: [0, 0, -1], up: [1, 0, 0]},
			{position: [0, 0, 1], up: [-1, 0, 0]},
		].forEach((settings, ndx) -> {
			var material = new three.MeshBasicMaterial({side: side});
			material.color.setHSL(ndx / 6, .5, .5);
			var mesh = new three.Mesh(geometry, material);
			mesh.up.set(settings.up[0], settings.up[1], settings.up[2]);
			mesh.lookAt(settings.position[0], settings.position[1], settings.position[2]);
			mesh.position.set(settings.position[0], settings.position[1], settings.position[2]).multiplyScalar(size * .75);
			base.add(mesh);
		});
		return base;
	}

	static function makeStandardPhysicalMaterialGrid( elem: HtmlElement, physical: Bool, update: (Array<Array<three.Mesh>>) -> Void ): {obj3D: Null<three.Mesh>, trackball: Bool, render: (renderInfo: {camera: three.Camera, scene: three.Scene, renderer: three.Renderer, pixelRatio: Float}) -> Void} {
		var numMetal = 5;
		var numRough = 7;
		var meshes = new Array<Array<three.Mesh>>();
		var MatCtor = physical ? three.MeshPhysicalMaterial : three.MeshStandardMaterial;
		var color = physical ? "hsl(160,50%,50%)" : "hsl(140,50%,50%)";
		for (m in 0...numMetal) {
			var row = new Array<three.Mesh>();
			for (r in 0...numRough) {
				var material = new MatCtor({
					color: color,
					roughness: r / (numRough - 1),
					metalness: 1 - m / (numMetal - 1),
				});
				var mesh = new three.Mesh(highPolySphereGeometry, material);
				row.push(mesh);
			}
			meshes.push(row);
		}
		return {
			obj3D: null,
			trackball: false,
			render: function(renderInfo: {camera: three.Camera, scene: three.Scene, renderer: three.Renderer, pixelRatio: Float}) {
				var camera = renderInfo.camera;
				var scene = renderInfo.scene;
				var renderer = renderInfo.renderer;
				var rect = elem.getBoundingClientRect();
				var width = (rect.right - rect.left) * renderInfo.pixelRatio;
				var height = (rect.bottom - rect.top) * renderInfo.pixelRatio;
				var left = rect.left * renderInfo.pixelRatio;
				var bottom = (renderer.domElement.clientHeight - rect.bottom) * renderInfo.pixelRatio;
				var cellSize = Math.min(width / numRough, height / numMetal) | 0;
				var xOff = (width - cellSize * numRough) / 2;
				var yOff = (height - cellSize * numMetal) / 2;
				camera.aspect = 1;
				camera.updateProjectionMatrix();
				if (update != null) {
					update(meshes);
				}
				for (m in 0...numMetal) {
					for (r in 0...numRough) {
						var x = left + xOff + r * cellSize;
						var y = bottom + yOff + m * cellSize;
						renderer.setViewport(x, y, cellSize, cellSize);
						renderer.setScissor(x, y, cellSize, cellSize);
						var mesh = meshes[m][r];
						scene.add(mesh);
						renderer.render(scene, camera);
						scene.remove(mesh);
					}
				}
			},
		};
	}

	static function main() {
		threejsLessonUtils.addDiagrams({
			smoothShading: {
				create: function(): three.Mesh {
					return smoothOrFlat(false);
				},
			},
			flatShading: {
				create: function(): three.Mesh {
					return smoothOrFlat(true);
				},
			},
			MeshBasicMaterial: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshBasicMaterial);
				},
			},
			MeshLambertMaterial: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshLambertMaterial);
				},
			},
			MeshPhongMaterial: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshPhongMaterial);
				},
			},
			MeshBasicMaterialLowPoly: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshBasicMaterial, true);
				},
			},
			MeshLambertMaterialLowPoly: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshLambertMaterial, true);
				},
			},
			MeshPhongMaterialLowPoly: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshPhongMaterial, true);
				},
			},
			MeshPhongMaterialShininess0: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshPhongMaterial, false, {
						color: "red",
						shininess: 0,
					});
				},
			},
			MeshPhongMaterialShininess30: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshPhongMaterial, false, {
						color: "red",
						shininess: 30,
					});
				},
			},
			MeshPhongMaterialShininess150: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshPhongMaterial, false, {
						color: "red",
						shininess: 150,
					});
				},
			},
			MeshBasicMaterialCompare: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshBasicMaterial, false, {
						color: "purple",
					});
				},
			},
			MeshLambertMaterialCompare: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshLambertMaterial, false, {
						color: "black",
						emissive: "purple",
					});
				},
			},
			MeshPhongMaterialCompare: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshPhongMaterial, false, {
						color: "black",
						emissive: "purple",
						shininess: 0,
					});
				},
			},
			MeshToonMaterial: {
				create: function(): {obj3D: three.Mesh, trackball: Bool} {
					return basicLambertPhongExample(three.MeshToonMaterial);
				},
			},
			MeshStandardMaterial: {
				create: function(props: {renderInfo: {elem: HtmlElement, camera: three.Camera, scene: three.Scene, renderer: three.Renderer, pixelRatio: Float}}): {obj3D: Null<three.Mesh>, trackball: Bool, render: (renderInfo: {camera: three.Camera, scene: three.Scene, renderer: three.Renderer, pixelRatio: Float}) -> Void} {
					return makeStandardPhysicalMaterialGrid(props.renderInfo.elem, false, null);
				},
			},
			MeshPhysicalMaterial: {
				create: function(props: {renderInfo: {elem: HtmlElement, camera: three.Camera, scene: three.Scene, renderer: three.Renderer, pixelRatio: Float}}): {obj3D: Null<three.Mesh>, trackball: Bool, render: (renderInfo: {camera: three.Camera, scene: three.Scene, renderer: three.Renderer, pixelRatio: Float}) -> Void} {
					var settings = {
						clearcoat: .5,
						clearcoatRoughness: 0,
					};
					function addElem(parent: HtmlElement, type: String, style: Dynamic = {}): HtmlElement {
						var elem = document.createElement(type);
						for (key in style) {
							elem.style[key] = style[key];
						}
						parent.appendChild(elem);
						return elem;
					}
					function addRange(elem: HtmlElement, obj: Dynamic, prop: String, min: Float, max: Float) {
						var outer = addElem(elem, "div", {
							width: "100%",
							textAlign: "center",
							"font-family": "monospace",
						});
						var div = addElem(outer, "div", {
							textAlign: "left",
							display: "inline-block",
						});
						var label = addElem(div, "label", {
							display: "inline-block",
							width: "12em",
						});
						label.textContent = prop;
						var num = addElem(div, "div", {
							display: "inline-block",
							width: "3em",
						});
						function updateNum() {
							num.textContent = obj[prop].toFixed(2);
						}
						updateNum();
						var input = addElem(div, "input", {});
						input.type = "range";
						input.min = 0;
						input.max = 100;
						input.value = (obj[prop] - min) / (max - min) * 100;
						input.addEventListener("input", function() {
							obj[prop] = min + (max - min) * input.value / 100;
							updateNum();
						});
					}
					var elem = props.renderInfo.elem;
					addRange(elem, settings, "clearcoat", 0, 1);
					addRange(elem, settings, "clearcoatRoughness", 0, 1);
					var area = addElem(elem, "div", {
						width: "100%",
						height: "400px",
					});
					return makeStandardPhysicalMaterialGrid(area, true, function(meshes: Array<Array<three.Mesh>>) {
						meshes.forEach(function(row: Array<three.Mesh>) {
							row.forEach(function(mesh: three.Mesh) {
								mesh.material.clearcoat = settings.clearcoat;
								mesh.material.clearcoatRoughness = settings.clearcoatRoughness;
							});
						});
					});
				},
			},
			MeshDepthMaterial: {
				create: function(props: {camera: three.Camera}): three.Mesh {
					var camera = props.camera;
					var radius = 4;
					var tube = 1.5;
					var radialSegments = 8;
					var tubularSegments = 64;
					var p = 2;
					var q = 3;
					var geometry = new three.TorusKnotGeometry(radius, tube, tubularSegments, radialSegments, p, q);
					var material = new three.MeshDepthMaterial();
					camera.near = 7;
					camera.far = 20;
					return new three.Mesh(geometry, material);
				},
			},
			MeshNormalMaterial: {
				create: function(): three.Mesh {
					var radius = 4;
					var tube = 1.5;
					var radialSegments = 8;
					var tubularSegments = 64;
					var p = 2;
					var q = 3;
					var geometry = new three.TorusKnotGeometry(radius, tube, tubularSegments, radialSegments, p, q);
					var material = new three.MeshNormalMaterial();
					return new three.Mesh(geometry, material);
				},
			},
			sideDefault: {
				create: function(): three.Object3D {
					return sideExample(three.FrontSide);
				},
			},
			sideDouble: {
				create: function(): three.Object3D {
					return sideExample(three.DoubleSide);
				},
			},
		});
	}
}

Main.main();