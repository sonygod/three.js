import haxe.unit.TestCase;

import three.loaders.FileLoader;
import three.loaders.Loader;

class FileLoaderTests {
  public static function testInheritance() {
    var object = new FileLoader();
    TestCase.assertTrue(object instanceof Loader, 'FileLoader extends from Loader');
  }

  public static function testInstancing() {
    var object = new FileLoader();
    TestCase.assertNotNull(object, 'Can instantiate a FileLoader.');
  }

  // Note: QUnit.todo is not directly equivalent in Haxe, but we can use TestCase.ignore to skip a test
  public static function testLoad() {
    TestCase.ignore('load', 'Implement me!');
  }

  public static function testSetResponseType() {
    TestCase.ignore('setResponseType', 'Implement me!');
  }

  public static function testSetMimeType() {
    TestCase.ignore('setMimeType', 'Implement me!');
  }
}