package three.js.test.unit.src.renderers.shaders;

import three.js.renderers.shaders.UniformsLib;

class UniformsLibTests {

    public function new() {}

    public static function main() {
        var assert = new Assert();
        Test.run( new UniformsLibTests() );

        TestSuite.add( "Renderers", function() {
            TestSuite.add( "Shaders", function() {
                TestSuite.add( "UniformsLib", function() {
                    Test.addCase( "Instancing", function( assert ) {
                        assert.isTrue( Lambda.has( UniformsLib ), "UniformsLib is defined." );
                    } );
                } );
            } );
        } );
    }
}