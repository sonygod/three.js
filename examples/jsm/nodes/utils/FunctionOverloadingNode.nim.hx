import Node, { addNodeClass } from '../core/Node.js';
import { nodeProxy } from '../shadernode/ShaderNode.js';

class FunctionOverloadingNode extends Node {

	public var functionNodes:Array<Dynamic>;
	public var parametersNodes:Array<Dynamic>;
	private var _candidateFnCall:Dynamic;

	public function new( functionNodes:Array<Dynamic> = [], ...parametersNodes:Array<Dynamic> ) {

		super();

		this.functionNodes = functionNodes;
		this.parametersNodes = parametersNodes;

		this._candidateFnCall = null;

	}

	public function getNodeType():Dynamic {

		return this.functionNodes[ 0 ].shaderNode.layout.type;

	}

	public function setup( builder:Dynamic ):Dynamic {

		var params:Array<Dynamic> = this.parametersNodes;

		var candidateFnCall:Dynamic = this._candidateFnCall;

		if ( candidateFnCall === null ) {

			var candidateFn:Dynamic = null;
			var candidateScore:Int = - 1;

			for ( functionNode in this.functionNodes ) {

				var shaderNode:Dynamic = functionNode.shaderNode;
				var layout:Dynamic = shaderNode.layout;

				if ( layout === null ) {

					throw new Error( 'FunctionOverloadingNode: FunctionNode must be a layout.' );

				}

				var inputs:Array<Dynamic> = layout.inputs;

				if ( params.length === inputs.length ) {

					var score:Int = 0;

					for ( i in 0...params.length ) {

						var param:Dynamic = params[ i ];
						var input:Dynamic = inputs[ i ];

						if ( param.getNodeType( builder ) === input.type ) {

							score ++;

						} else {

							score = 0;

						}

					}

					if ( score > candidateScore ) {

						candidateFn = functionNode;
						candidateScore = score;

					}

				}

			}

			this._candidateFnCall = candidateFnCall = candidateFn( ...params );

		}

		return candidateFnCall;

	}

}

addNodeClass( 'FunctionOverloadingNode', FunctionOverloadingNode );

const overloadingBaseFn:Dynamic = nodeProxy( FunctionOverloadingNode );

export const overloadingFn:Dynamic = ( functionNodes:Array<Dynamic> ) => ( ...params:Array<Dynamic> ) => overloadingBaseFn( functionNodes, ...params );