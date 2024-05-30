import js.Browser.window;
import js.QUnit.*;
import js.Three.*;

class _TestMeshLambertMaterial {
	public static function main() {
		module("Materials");

		module("MeshLambertMaterial");

		// INHERITANCE
		test("Extending", function() {
			var object = new MeshLambertMaterial();
			ok(object instanceof Material, "MeshLambertMaterial extends from Material");
		});

		// INSTANCING
		test("Instancing", function() {
			var object = new MeshLambertMaterial();
			ok(object, "Can instantiate a MeshLambertMaterial.");
		});

		// PROPERTIES
		test("type", function() {
			var object = new MeshLambertMaterial();
			ok(object.type == "MeshLambertMaterial", "MeshLambertMaterial.type should be MeshLambertMaterial");
		});

		test("color", function() {
			ok(false, "everything's gonna be alright");
		});

		test("map", function() {
			ok(false, "everything's gonna be alright");
		});

		test("lightMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("lightMapIntensity", function() {
			ok(false, "everything's gonna be alright");
		});

		test("aoMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("aoMapIntensity", function() {
			ok(false, "everything's gonna be alright");
		});

		test("emissive", function() {
			ok(false, "everything's gonna be alright");
		});

		test("emissiveIntensity", function() {
			ok(false, "everything's gonna be alright");
		});

		test("emissiveMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("bumpMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("bumpScale", function() {
			ok(false, "everything's gonna be alright");
		});

		test("normalMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("normalMapType", function() {
			ok(false, "everything's gonna be alright");
		});

		test("normalScale", function() {
			ok(false, "everything's gonna be alright");
		});

		test("displacementMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("displacementScale", function() {
			ok(false, "everything's gonna be alright");
		});

		test("displacementBias", function() {
			ok(false, "everything's gonna be alright");
		});

		test("specularMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("alphaMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("envMap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("combine", function() {
			ok(false, "everything's gonna be alright");
		});

		test("reflectivity", function() {
			ok(false, "everything's gonna be alright");
		});

		test("refractionRatio", function() {
			ok(false, "everything's gonna be alright");
		});

		test("wireframe", function() {
			ok(false, "everything's gonna be alright");
		});

		test("wireframeLinewidth", function() {
			ok(false, "everything's gonna be alright");
		});

		test("wireframeLinecap", function() {
			ok(false, "everything's gonna be alright");
		});

		test("wireframeLinejoin", function() {
			ok(false, "everything's gonna be alright");
		});

		test("flatShading", function() {
			ok(false, "everything's gonna be alright");
		});

		test("fog", function() {
			ok(false, "everything's gonna be alright");
		});

		// PUBLIC
		test("isMeshLambertMaterial", function() {
			var object = new MeshLambertMaterial();
			ok(object.isMeshLambertMaterial, "MeshLambertMaterial.isMeshLambertMaterial should be true");
		});

		test("copy", function() {
			ok(false, "everything's gonna be alright");
		});
	}
}

class TestMeshLambertMaterial {
	public static function main() {
		_TestMeshLambertMaterial.main();
	}
}

TestMeshLambertMaterial.main();