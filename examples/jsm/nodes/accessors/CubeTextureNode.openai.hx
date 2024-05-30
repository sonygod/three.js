package three.js.examples.jsm.nodes.accessors;

import three.js.examples.jsm.nodes.TextureNode;
import three.js.examples.jsm.nodes.ReflectVectorNode;
import three.js.core.Node;
import three.js.shadernode.ShaderNode;

class CubeTextureNode extends TextureNode {
	
	public var isCubeTextureNode:Bool;

	public function new(value:Dynamic, uvNode:Dynamic = null, levelNode:Dynamic = null) {
		super(value, uvNode, levelNode);
		isCubeTextureNode = true;
	}

	override public function getInputType(builder:Dynamic):String {
		return 'cubeTexture';
	}

	override public function getDefaultUV():Dynamic {
		return ReflectVectorNode.reflectVector;
	}

	public function setUpdateMatrix(updateMatrix:Dynamic):Void {} // Ignore .updateMatrix for CubeTextureNode

	public function setupUV(builder:Dynamic, uvNode:Dynamic):Dynamic {
		var texture:Dynamic = value;
		if (builder.renderer.coordinateSystem == WebGPUCoordinateSystem || !texture.isRenderTargetTexture) {
			return vec3(-uvNode.x, uvNode.y, uvNode.z);
		} else {
			return uvNode;
		}
	}

	public function generateUV(builder:Dynamic, cubeUV:Dynamic):Dynamic {
		return cubeUV.build(builder, 'vec3');
	}
}

// export default CubeTextureNode;
// export const cubeTexture = nodeProxy( CubeTextureNode );
// addNodeElement( 'cubeTexture', cubeTexture );
// addNodeClass( 'CubeTextureNode', CubeTextureNode );

// In Haxe, we use a single file for a single class, so we don't need the export statements.
// We'll also need to create separate files for the node proxy and the addNodeElement/addNodeClass functions.

// You may want to create a separate file for the node proxy, e.g., CubeTextureNodeProxy.hx:
// package three.js.examples.jsm.nodes.accessors;
// import three.js.examples.jsm.nodes.accessors.CubeTextureNode;
// class CubeTextureNodeProxy {
//     public static var cubeTexture:Dynamic = nodeProxy( CubeTextureNode );
// }

// And another file for the addNodeElement/addNodeClass functions, e.g., NodeRegistrar.hx:
// package three.js.examples.jsm.nodes;
// import three.js.examples.jsm.nodes.accessors.CubeTextureNode;
// class NodeRegistrar {
//     public static function init():Void {
//         addNodeElement('cubeTexture', CubeTextureNodeProxy.cubeTexture);
//         addNodeClass('CubeTextureNode', CubeTextureNode);
//     }
// }