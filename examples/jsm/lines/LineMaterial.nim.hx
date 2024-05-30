import three.js.examples.jsm.lines.ShaderLib;
import three.js.examples.jsm.lines.ShaderMaterial;
import three.js.examples.jsm.lines.UniformsLib;
import three.js.examples.jsm.lines.UniformsUtils;
import three.js.examples.jsm.lines.Vector2;

class Main {
    static function main() {
        UniformsLib.line = {
            worldUnits: { value: 1 },
            linewidth: { value: 1 },
            resolution: { value: new Vector2( 1, 1 ) },
            dashOffset: { value: 0 },
            dashScale: { value: 1 },
            dashSize: { value: 1 },
            gapSize: { value: 1 } // todo FIX - maybe change to totalSize
        };

        ShaderLib[ 'line' ] = {
            uniforms: UniformsUtils.merge( [
                UniformsLib.common,
                UniformsLib.fog,
                UniformsLib.line
            ] ),

            vertexShader:
            /* glsl */`
                // ...
            `,

            fragmentShader:
            /* glsl */`
                // ...
            `
        };

        class LineMaterial extends ShaderMaterial {
            public function new( parameters ) {
                super( {
                    type: 'LineMaterial',
                    uniforms: UniformsUtils.clone( ShaderLib[ 'line' ].uniforms ),
                    vertexShader: ShaderLib[ 'line' ].vertexShader,
                    fragmentShader: ShaderLib[ 'line' ].fragmentShader,
                    clipping: true // required for clipping support
                } );

                this.isLineMaterial = true;

                this.setValues( parameters );
            }

            // ...
        }
    }
}