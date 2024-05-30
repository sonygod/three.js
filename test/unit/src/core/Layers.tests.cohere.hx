import js.QUnit;

class LayersTest {
    static var all:LayersTest;

    static function test() {
        QUnit.module( 'Core', setup, () -> {
            QUnit.module( 'Layers', () -> {
                QUnit.test( 'Instancing', LayersTest.instancing );
                QUnit.test( 'set', LayersTest.set );
                QUnit.test( 'enable', LayersTest.enable );
                QUnit.test( 'toggle', LayersTest.toggle );
                QUnit.test( 'disable', LayersTest.disable );
                QUnit.test( 'test', LayersTest.test );
                QUnit.test( 'isEnabled', LayersTest.isEnabled );
            });
        });
    }

    static function setup() {
        all = new LayersTest();
    }

    static function instancing(assert:QUnit.Assert) {
        var object = new Layers();
        assert.ok( object != null, 'Can instantiate a Layers.' );
    }

    static function set(assert:QUnit.Assert) {
        var a = new Layers();

        for (i in 0...31) {
            a.set(i);
            assert.strictEqual( a.mask, Math.pow(2, i), 'Mask has the expected value for channel: ' + i );
        }
    }

    static function enable(assert:QUnit.Assert) {
        var a = new Layers();

        a.set(0);
        a.enable(0);
        assert.strictEqual( a.mask, 1, 'Enable channel 0 with mask 0' );

        a.set(0);
        a.enable(1);
        assert.strictEqual( a.mask, 3, 'Enable channel 1 with mask 0' );

        a.set(1);
        a.enable(0);
        assert.strictEqual( a.mask, 3, 'Enable channel 0 with mask 1' );

        a.set(1);
        a.enable(1);
        assert.strictEqual( a.mask, 2, 'Enable channel 1 with mask 1' );
    }

    static function toggle(assert:QUnit.Assert) {
        var a = new Layers();

        a.set(0);
        a.toggle(0);
        assert.strictEqual( a.mask, 0, 'Toggle channel 0 with mask 0' );

        a.set(0);
        a.toggle(1);
        assert.strictEqual( a.mask, 3, 'Toggle channel 1 with mask 0' );

        a.set(1);
        a.toggle(0);
        assert.strictEqual( a.mask, 3, 'Toggle channel 0 with mask 1' );

        a.set(1);
        a.toggle(1);
        assert.strictEqual( a.mask, 0, 'Toggle channel 1 with mask 1' );
    }

    static function disable(assert:QUnit.Assert) {
        var a = new Layers();

        a.set(0);
        a.disable(0);
        assert.strictEqual( a.mask, 0, 'Disable channel 0 with mask 0' );

        a.set(0);
        a.disable(1);
        assert.strictEqual( a.mask, 1, 'Disable channel 1 with mask 0' );

        a.set(1);
        a.disable(0);
        assert.strictEqual( a.mask, 2, 'Disable channel 0 with mask 1' );

        a.set(1);
        a.disable(1);
        assert<BOS_TOKEN>
assert.strictEqual( a.mask, 0, 'Disable channel 1 with mask 1' );
    }

    static function test(assert:QUnit.Assert) {
        var a = new Layers();
        var b = new Layers();

        assert.ok( a.test(b), 'Start out true' );

        a.set(1);
        assert.notOk( a.test(b), 'Set channel 1 in a and fail the QUnit.test' );

        b.toggle(1);
        assert.ok( a.test(b), 'Toggle channel 1 in b and pass again' );
    }

    static function isEnabled(assert:QUnit.Assert) {
        var a = new Layers();

        a.enable(1);
        assert.ok( a.isEnabled(1), 'Enable channel 1 and pass the QUnit.test' );

        a.enable(2);
        assert.ok( a.isEnabled(2), 'Enable channel 2 and pass the QUnit.test' );

        a.toggle(1);
        assert.notOk( a.isEnabled(1), 'Toggle channel 1 and fail the QUnit.test' );
        assert.ok( a.isEnabled(2), 'Channel 2 still enabled and pass the QUnit.test' );
    }
}