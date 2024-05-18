package three.js.examples.jm.nodes.core;

import three.js.examples.jm.nodes.core.Node;

class TempNode extends Node {

    public var isTempNode:Bool = true;

    public function new(type:String) {
        super(type);
    }

    public function hasDependencies(builder:Dynamic):Bool {
        return builder.getDataFromNode(this).usageCount > 1;
    }

    public function build(builder:Dynamic, output:Dynamic):Dynamic {
        var buildStage:String = builder.getBuildStage();
        if (buildStage == 'generate') {
            var type:String = builder.getVectorType(getNodeType(builder, output));
            var nodeData:Dynamic = builder.getDataFromNode(this);
            if (builder.context.tempRead != false && nodeData.propertyName != null) {
                return builder.format(nodeData.propertyName, type, output);
            } else if (builder.context.tempWrite != false && type != 'void' && output != 'void' && hasDependencies(builder)) {
                var snippet:String = super.build(builder, type);
                var nodeVar:String = builder.getVarFromNode(this, null, type);
                var propertyName:String = builder.getPropertyName(nodeVar);
                builder.addLineFlowCode('${propertyName} = ${snippet}');
                nodeData.snippet = snippet;
                nodeData.propertyName = propertyName;
                return builder.format(nodeData.propertyName, type, output);
            }
        }
        return super.build(builder, output);
    }

}

addNodeClass('TempNode', TempNode);