import js.QUnit.*;
import js.WebGL.*;

import js.Three.Material;
import js.Three.ShaderMaterial;

class TestShaderMaterial {
	public static function main() {
		module("Materials");

		module("ShaderMaterial", {
			setup:function() {
			},
			teardown:function() {
			}
		});

		// INHERITANCE
		test("Extending", function() {
			var object = new ShaderMaterial();
			ok(Std.is(object, Material), "ShaderMaterial extends from Material");
		});

		// INSTANCING
		test("Instancing", function() {
			var object = new ShaderMaterial();
			ok(object, "Can instantiate a ShaderMaterial.");
		});

		// PROPERTIES
		test("type", function() {
			var object = new ShaderMaterial();
			ok(object.type == "ShaderMaterial", "ShaderMaterial.type should be ShaderMaterial");
		});

		test("defines", function() {
			ok(false, "everything's gonna be alright");
		});

		test("uniforms", function() {
			ok(false, "everything's gonna be alright");
		});

		test("uniformsGroups", function() {
			ok(false, "everything's gonna be alright");
		});

		test("vertexShader", function() {
			ok(false, "everything's gonna be alright");
		});

		test("fragmentShader", function() {
			ok(false, "everything's gonna be alright");
		});

		test("linewidth", function() {
			ok(false, "everything's gonna be alright");
		});

		test("wireframe", function() {
			ok(false, "everything's gonna be alright");
		});

		test("wireframeLinewidth", function() {
			ok(false, "everything's gonna be alright");
		});

		test("fog", function() {
			ok(false, "everything's gonna be alright");
		});

		test("lights", function() {
			ok(false, "everything's gonna be alright");
		});

		test("clipping", function() {
			ok(false, "everything's gonna be alright");
		});

		test("extensions", function() {
			ok(false, "everything's gonna be alright");
		});

		test("defaultAttributeValues", function() {
			ok(false, "everything's gonna be alright");
		});

		test("index0AttributeName", function() {
			ok(false, "everything's gonna be alright");
		});

		test("uniformsNeedUpdate", function() {
			ok(false, "everything's gonna be alright");
		});

		test("glslVersion", function() {
			ok(false, "everything's gonna be alright");
		});

		// PUBLIC
		test("isShaderMaterial", function() {
			var object = new ShaderMaterial();
			ok(object.isShaderMaterial, "ShaderMaterial.isShaderMaterial should be true");
		});

		test("copy", function() {
			ok(false, "everything's gonna be alright");
		});

		test("toJSON", function() {
			ok(false, "everything's gonna be alright");
		});
	}
}

TestShaderMaterial.main();