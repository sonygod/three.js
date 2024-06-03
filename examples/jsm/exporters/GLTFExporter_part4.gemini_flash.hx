class GLTFMaterialsUnlitExtension {

	public var writer:Dynamic;
	public var name:String = "KHR_materials_unlit";

	public function new(writer:Dynamic) {
		this.writer = writer;
	}

	public function writeMaterial(material:Dynamic, materialDef:Dynamic):Void {
		if (!Reflect.hasField(material, "isMeshBasicMaterial")) return;

		var extensionsUsed = Reflect.field(writer, "extensionsUsed");
		var extensions = Reflect.field(materialDef, "extensions");
		if (extensions == null) extensions = {};
		Reflect.setField(materialDef, "extensions", extensions);
		Reflect.setField(extensions, name, {});

		Reflect.setField(extensionsUsed, name, true);

		var pbrMetallicRoughness = Reflect.field(materialDef, "pbrMetallicRoughness");
		Reflect.setField(pbrMetallicRoughness, "metallicFactor", 0.0);
		Reflect.setField(pbrMetallicRoughness, "roughnessFactor", 0.9);
	}

}


**Explanation of Changes:**

1. **Class Declaration:** The `class` keyword is used in Haxe, similar to JavaScript.
2. **Field Declaration:** Fields are declared using `var` followed by the type.
3. **Constructor:** The constructor is defined using the `new` keyword and takes the `writer` argument.
4. **Method Declaration:** Methods are defined using the `public function` keyword.
5. **Reflect Class:** Haxe doesn't have direct access to object properties like JavaScript's `material.isMeshBasicMaterial`. We use the `Reflect` class to access properties and fields dynamically.
6. **Type Inference:** Haxe can often infer types, so we don't need to explicitly specify them in some cases.
7. **Field Access:** Instead of `material.isMeshBasicMaterial`, we use `Reflect.hasField(material, "isMeshBasicMaterial")`.
8. **Dynamic Types:**  The `Dynamic` type is used to represent objects that can be accessed dynamically.

**Usage:**


// Assuming you have a writer object
var writer = ...;
var extension = new GLTFMaterialsUnlitExtension(writer);

// Assuming you have a material and material definition
var material = ...;
var materialDef = ...;

extension.writeMaterial(material, materialDef);