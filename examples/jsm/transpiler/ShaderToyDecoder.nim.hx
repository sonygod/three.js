import AST.Return;
import AST.VariableDeclaration;
import AST.Accessor;
import GLSLDecoder from './GLSLDecoder.hx';

class ShaderToyDecoder extends GLSLDecoder {

	public function new() {

		super();

		this.addPolyfill( 'iTime', 'float iTime = timerGlobal();' );
		this.addPolyfill( 'iResolution', 'vec2 iResolution = viewportResolution;' );
		this.addPolyfill( 'fragCoord', 'vec3 fragCoord = vec3( viewportCoordinate.x, viewportResolution.y - viewportCoordinate.y, viewportCoordinate.z );' );

	}

	public function parseFunction() {

		var node = super.parseFunction();

		if ( node.name == 'mainImage' ) {

			node.params = []; // remove default parameters
			node.type = 'vec4';
			node.layout = false; // for now

			var fragColor = new Accessor( 'fragColor' );

			for ( subNode in node.body ) {

				if ( subNode.isReturn ) {

					subNode.value = fragColor;

				}

			}

			node.body.unshift( new VariableDeclaration( 'vec4', 'fragColor' ) );
			node.body.push( new Return( fragColor ) );

		}

		return node;

	}

}

export default ShaderToyDecoder;