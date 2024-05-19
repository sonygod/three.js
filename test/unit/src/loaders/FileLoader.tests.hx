Here is the converted Haxe code:
```
package three.test.unit.src.loaders;

import three.loaders.FileLoader;
import three.loaders.Loader;
import utest Assert;
import utest.Test;

@:keep
class FileLoaderTests {
    public function new() {}

    public function testExtending() {
        var object = new FileLoader();
        Assert.isTrue(Std.is(object, Loader), 'FileLoader extends from Loader');
    }

    public function testInstancing() {
        var object = new FileLoader();
        Assert.notNull(object, 'Can instantiate a FileLoader.');
    }

    public function todoLoad() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoSetResponseType() {
        Assert.fail('everything\'s gonna be alright');
    }

    public function todoSetMimeType() {
        Assert.fail('everything\'s gonna be alright');
    }
}
```
Note that I've used the `utest` framework for testing, which is a popular testing framework for Haxe. I've also removed the `QUnit.module` and `QUnit.test` syntax, as they are specific to QUnit and not compatible with Haxe.

Additionally, I've used the `@:keep` metadata to ensure that the test class is not optimized away by the Haxe compiler. This is a common pattern in Haxe testing.

You'll need to adjust the import paths and package names to match your specific Haxe project setup.