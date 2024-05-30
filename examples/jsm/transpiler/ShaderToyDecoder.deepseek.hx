import three.js.examples.jsm.transpiler.AST.*;
import three.js.examples.jsm.transpiler.GLSLDecoder;

class ShaderToyDecoder extends GLSLDecoder {

	public function new() {

		super();

		this.addPolyfill( 'iTime', 'float iTime = timerGlobal();' );
		this.addPolyfill( 'iResolution', 'vec2 iResolution = viewportResolution;' );
		this.addPolyfill( 'fragCoord', 'vec3 fragCoord = vec3( viewportCoordinate.x, viewportResolution.y - viewportCoordinate.y, viewportCoordinate.z );' );

	}

	public function parseFunction():Node {

		var node = super.parseFunction();

		if (node.name == 'mainImage') {

			node.params = []; // remove default parameters
			node.type = 'vec4';
			node.layout = false; // for now

			var fragColor = new Accessor( 'fragColor' );

			for (subNode in node.body) {

				if (subNode.isReturn) {

					subNode.value = fragColor;

				}

			}

			node.body.unshift( new VariableDeclaration( 'vec4', 'fragColor' ) );
			node.body.push( new Return( fragColor ) );

		}

		return node;

	}

}

typedef ShaderToyDecoder = three.js.examples.jsm.transpiler.ShaderToyDecoder;