import js.QUnit.*;
import js.QUnit.QUnitTest;

import js.Three.Math.SphericalHarmonics3;

class SphericalHarmonics3Test extends QUnitTest {

	public function new() {
		super();

		// INSTANCING
		test( 'Instancing', function() {
			var object = new SphericalHarmonics3();
			assert.ok( object, 'Can instantiate a SphericalHarmonics3.' );
		} );

		// PROPERTIES
		test( 'coefficients', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		// PUBLIC
		test( 'isSphericalHarmonics3', function() {
			var object = new SphericalHarmonics3();
			assert.ok(
				object.isSphericalHarmonics3,
				'SphericalHarmonics3.isSphericalHarmonics3 should be true'
			);
		} );

		test( 'set', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'zero', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'getAt', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'getIrradianceAt', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'add', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'addScaledSH', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'scale', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'lerp', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'equals', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'copy', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'clone', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'fromArray', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		test( 'toArray', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

		// PUBLIC - STATIC
		test( 'getBasisAt', function() {
			assert.ok( false, 'everything\'s gonna be alright' );
		} );

	}

}

static function main() {
	#if js
	var runner = new QUnit.QUnitTestRunner();
	runner.run( SphericalHarmonics3Test );
	#end
}