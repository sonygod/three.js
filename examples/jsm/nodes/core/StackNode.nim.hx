import Node, { addNodeClass } from './Node.js';
import { cond } from '../math/CondNode.js';
import { ShaderNode, nodeProxy, getCurrentStack, setCurrentStack } from '../shadernode/ShaderNode.js';

class StackNode extends Node {

	public var nodes:Array<Dynamic>;
	public var outputNode:Dynamic;

	public var parent:Dynamic;

	public var _currentCond:Dynamic;

	public var isStackNode:Bool;

	public function new( parent:Dynamic = null ) {

		super();

		this.nodes = [];
		this.outputNode = null;

		this.parent = parent;

		this._currentCond = null;

		this.isStackNode = true;

	}

	public function getNodeType( builder:Dynamic ) {

		return this.outputNode ? this.outputNode.getNodeType( builder ) : 'void';

	}

	public function add( node:Dynamic ) {

		this.nodes.push( node );

		return this;

	}

	public function if( boolNode:Dynamic, method:Dynamic ) {

		const methodNode = new ShaderNode( method );
		this._currentCond = cond( boolNode, methodNode );

		return this.add( this._currentCond );

	}

	public function elseif( boolNode:Dynamic, method:Dynamic ) {

		const methodNode = new ShaderNode( method );
		const ifNode = cond( boolNode, methodNode );

		this._currentCond.elseNode = ifNode;
		this._currentCond = ifNode;

		return this;

	}

	public function else( method:Dynamic ) {

		this._currentCond.elseNode = new ShaderNode( method );

		return this;

	}

	public function build( builder:Dynamic, params:Array<Dynamic> ) {

		const previousStack = getCurrentStack();

		setCurrentStack( this );

		for ( node in this.nodes ) {

			node.build( builder, 'void' );

		}

		setCurrentStack( previousStack );

		return this.outputNode ? this.outputNode.build( builder, params ) : super.build( builder, params );

	}

}

export default StackNode;

export const stack = nodeProxy( StackNode );

addNodeClass( 'StackNode', StackNode );