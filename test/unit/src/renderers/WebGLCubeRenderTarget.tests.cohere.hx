import js.QUnit;

import js.WebGLCubeRenderTarget from "../../../../src/renderers/WebGLCubeRenderTarget.js";

import js.WebGLRenderTarget from "../../../../src/renderers/WebGLRenderTarget.js";

@:exportDefault
@:module( 'Renderers' )
class TestModule {
    static testExtending() {
        var object = new WebGLCubeRenderTarget();
        var assert = js.QUnit.test.assert;
        assert.strictEqual( object instanceof WebGLRenderTarget, true, 'WebGLCubeRenderTarget extends from WebGLRenderTarget' );
    }

    static testInstancing() {
        var object = new WebGLCubeRenderTarget();
        var assert = js.QUnit.test.assert;
        assert.ok( object, 'Can instantiate a WebGLCubeRenderTarget.' );
    }

    static testProperties() {
        // doc update needed, this needs to be a CubeTexture unlike parent class
        var assert = js.QUnit.test.assert;
        assert.ok( false, 'everything\'s gonna be alright' );
    }

    static testIsWebGLCubeRenderTarget() {
        var assert = js.QUnit.test.assert;
        assert.ok( false, 'everything\'s gonna be alright' );
    }

    static testFromEquirectangularTexture() {
        var assert = js.QUnit.test.assert;
        assert.ok( false, 'everything\'s gonna be alright' );
    }

    static testClear() {
        var assert = js.QUnit.test.assert;
        assert.ok( false, 'everything\'s gonna be alright' );
    }
}

js.QUnit.module( 'Renderers', function() {
    js.QUnit.module( 'WebGLCubeRenderTarget', function() {
        js.QUnit.test( 'Extending', TestModule.testExtending );
        js.QUnit.test( 'Instancing', TestModule.testInstancing );
        js.QUnit.test( 'PROPERTIES', TestModule.testProperties );
        js.QUnit.test( 'PUBLIC', TestModule.testIsWebGLCubeRenderTarget );
        js.QUnit.test( 'fromEquirectangularTexture', TestModule.testFromEquirectangularTexture );
        js.QUnit.test( 'clear', TestModule.testClear );
    } );
} );