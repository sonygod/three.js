import UniformNode from '../core/UniformNode.js';
import { NodeUpdateType } from '../core/constants.js';
import { nodeObject, nodeImmutable } from '../shadernode/ShaderNode.js';
import { addNodeClass } from '../core/Node.js';

class TimerNode extends UniformNode {

	public static var LOCAL:String = 'local';
	public static var GLOBAL:String = 'global';
	public static var DELTA:String = 'delta';
	public static var FRAME:String = 'frame';

	public var scope:String;
	public var scale:Float;

	public function new( scope:String = TimerNode.LOCAL, scale:Float = 1, value:Float = 0 ) {

		super( value );

		this.scope = scope;
		this.scale = scale;

		this.updateType = NodeUpdateType.FRAME;

	}

	public function update( frame:Dynamic ) {

		switch ( this.scope ) {

			case TimerNode.LOCAL:

				this.value += frame.deltaTime * this.scale;

				break;

			case TimerNode.DELTA:

				this.value = frame.deltaTime * this.scale;

				break;

			case TimerNode.FRAME:

				this.value = frame.frameId;

				break;

			default:

				// global

				this.value = frame.time * this.scale;

		}

	}

	public function serialize( data:Dynamic ) {

		super.serialize( data );

		data.scope = this.scope;
		data.scale = this.scale;

	}

	public function deserialize( data:Dynamic ) {

		super.deserialize( data );

		this.scope = data.scope;
		this.scale = data.scale;

	}

}

// @TODO: add support to use node in timeScale
export const timerLocal = ( timeScale:Float, value:Float = 0 ) => nodeObject( new TimerNode( TimerNode.LOCAL, timeScale, value ) );
export const timerGlobal = ( timeScale:Float, value:Float = 0 ) => nodeObject( new TimerNode( TimerNode.GLOBAL, timeScale, value ) );
export const timerDelta = ( timeScale:Float, value:Float = 0 ) => nodeObject( new TimerNode( TimerNode.DELTA, timeScale, value ) );
export const frameId = nodeImmutable( TimerNode, TimerNode.FRAME ).toUint();

addNodeClass( 'TimerNode', TimerNode );