import three.src.core.GLBufferAttribute;

class GLBufferAttributeTests {

    public static function main() {

        // INSTANCING
        test('Instancing', function(assert:Assert) {
            var object:GLBufferAttribute = new GLBufferAttribute();
            assert.notNull(object, 'Can instantiate a GLBufferAttribute.');
        });

        // PUBLIC
        test('isGLBufferAttribute', function(assert:Assert) {
            var object:GLBufferAttribute = new GLBufferAttribute();
            assert.isTrue(
                object.isGLBufferAttribute,
                'GLBufferAttribute.isGLBufferAttribute should be true'
            );
        });

        // TODO: PROPERTIES and other methods
        /*
        todo('name', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('buffer', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('type', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('itemSize', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('elementSize', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('count', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('version', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('needsUpdate', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('setBuffer', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('setType', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('setItemSize', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });

        todo('setCount', function(assert:Assert) {
            assert.fail('everything\'s gonna be alright');
        });
        */
    }

    private static function test(name:String, fn:(Assert) -> Void) {
        print('Test: ' + name);
        fn(new Assert());
    }

    private static function todo(name:String, fn:(Assert) -> Void) {
        print('TODO: ' + name);
    }
}

class Assert {
    public function notNull(value:Dynamic, message:String) {
        if (value == null) {
            throw new js.Boot.AssertionError(message);
        }
    }

    public function isTrue(value:Bool, message:String) {
        if (!value) {
            throw new js.Boot.AssertionError(message);
        }
    }

    public function fail(message:String) {
        throw new js.Boot.AssertionError(message);
    }
}