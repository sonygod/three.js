import three.loaders.MaterialLoader;
import materials.Materials;

class NodeMaterialLoader extends MaterialLoader {

  public var nodes:Dynamic = {};

  public function new(manager:Dynamic) {
    super(manager);
  }

  override function parse(json:Dynamic):Dynamic {
    var material = super.parse(json);

    var inputNodes = json.inputNodes;
    for (property in inputNodes) {
      var uuid = inputNodes[property];
      material[property] = nodes[uuid];
    }

    return material;
  }

  public function setNodes(value:Dynamic):NodeMaterialLoader {
    nodes = value;
    return this;
  }
}

var superFromTypeFunction = MaterialLoader.createMaterialFromType;

MaterialLoader.createMaterialFromType = function(type:Dynamic):Dynamic {
  var material = Materials.createNodeMaterialFromType(type);
  if (material != null) {
    return material;
  }
  return superFromTypeFunction.call(this, type);
};

class NodeMaterialLoader extends MaterialLoader {

  public function new(manager:Dynamic) {
    super(manager);
    this.nodes = {};
  }

  override function parse(json:Dynamic):Dynamic {
    var material = super.parse(json);

    var nodes = this.nodes;
    var inputNodes = json.inputNodes;
    for (property in inputNodes) {
      var uuid = inputNodes[property];
      material[property] = nodes[uuid];
    }

    return material;
  }

  public function setNodes(value:Dynamic):NodeMaterialLoader {
    this.nodes = value;
    return this;
  }
}

export default NodeMaterialLoader;


**Explanation:**

* **Imports:** We import the necessary classes from the `three` and `materials` libraries.
* **NodeMaterialLoader Class:**
    * We define the `NodeMaterialLoader` class which extends the `MaterialLoader` class.
    * We create a `nodes` field to store the node materials.
    * The `parse` method overrides the parent method to handle the node materials. It iterates through the `inputNodes` in the JSON and sets the corresponding node material from the `nodes` field to the material.
    * The `setNodes` method allows setting the `nodes` field.
* **Overriding `createMaterialFromType`:**
    * We store the original `createMaterialFromType` function in `superFromTypeFunction`.
    * We override the function and first call `createNodeMaterialFromType` from the `Materials` class.
    * If the result is not null, we return it. Otherwise, we call the original function using `superFromTypeFunction.call(this, type)`.

**Important Notes:**

* This code assumes that the `materials` library is available and has a `createNodeMaterialFromType` function.
* The `inputNodes` field in the JSON is assumed to contain the UUIDs of the node materials.
* The `nodes` field in the `NodeMaterialLoader` should be populated with the actual node materials before parsing the JSON.

**Usage:**

1. Create an instance of `NodeMaterialLoader`.
2. Set the `nodes` field with the node materials.
3. Use the `parse` method to parse the JSON and get the material with the node materials applied.


var loader = new NodeMaterialLoader();
loader.setNodes({
  "uuid1": nodeMaterial1,
  "uuid2": nodeMaterial2
});

var material = loader.parse(json);