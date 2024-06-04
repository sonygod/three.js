import Node from "./Node";

class TempNode extends Node {

  public var isTempNode:Bool = true;

  public function new(type:String) {
    super(type);
  }

  public function hasDependencies(builder:Dynamic):Bool {
    return builder.getDataFromNode(this).usageCount > 1;
  }

  public function build(builder:Dynamic, output:String):String {
    var buildStage = builder.getBuildStage();

    if (buildStage == "generate") {
      var type = builder.getVectorType(this.getNodeType(builder, output));
      var nodeData = builder.getDataFromNode(this);

      if (builder.context.tempRead != false && nodeData.propertyName != null) {
        return builder.format(nodeData.propertyName, type, output);
      } else if (builder.context.tempWrite != false && type != "void" && output != "void" && this.hasDependencies(builder)) {
        var snippet = super.build(builder, type);
        var nodeVar = builder.getVarFromNode(this, null, type);
        var propertyName = builder.getPropertyName(nodeVar);

        builder.addLineFlowCode("$propertyName = $snippet");
        nodeData.snippet = snippet;
        nodeData.propertyName = propertyName;

        return builder.format(nodeData.propertyName, type, output);
      }
    }

    return super.build(builder, output);
  }

}

class TempNodeClass extends Node {

  public static function addNodeClass(name:String, c:Dynamic) {
    Node.addNodeClass(name, c);
  }

}

TempNodeClass.addNodeClass("TempNode", TempNode);

export default TempNode;