import Node from "./Node";
import StructTypeNode from "./StructTypeNode";
import ShaderNode from "../shadernode/ShaderNode";

class OutputStructNode extends Node {

	public members:Array<Node>;
	public isOutputStructNode:Bool = true;

	public function new( ...members:Array<Node> ) {
		super();
		this.members = members;
	}

	override public function setup( builder:ShaderNode ):Void {
		super.setup( builder );

		var types:Array<String> = [];

		for ( i in 0...members.length ) {
			types.push( members[ i ].getNodeType( builder ) );
		}

		this.nodeType = builder.getStructTypeFromNode( new StructTypeNode( types ) ).name;
	}

	override public function generate( builder:ShaderNode, output:String ):String {
		var nodeVar = builder.getVarFromNode( this );
		nodeVar.isOutputStructVar = true;

		var propertyName:String = builder.getPropertyName( nodeVar );

		var structPrefix:String = propertyName != "" ? propertyName + "." : "";

		for ( i in 0...members.length ) {
			var snippet:String = members[ i ].build( builder, output );
			builder.addLineFlowCode( "${structPrefix}m${i} = ${snippet}" );
		}

		return propertyName;
	}

}

export var outputStruct:ShaderNode.NodeProxy<OutputStructNode> = new ShaderNode.NodeProxy<OutputStructNode>(OutputStructNode);

Node.addNodeClass( "OutputStructNode", OutputStructNode );