import utest.Runner;
import utest.ui.Report;

import three.loaders.ObjectLoader;
import three.loaders.Loader;

class ObjectLoaderTest {
  public function new() {}

  public function testExtending() {
    var object = new ObjectLoader();
    Assert.isTrue(Std.is(object, Loader), 'ObjectLoader extends from Loader');
  }

  public function testInstancing() {
    var object = new ObjectLoader();
    Assert.notNull(object, 'Can instantiate an ObjectLoader.');
  }

  public function testLoad() {
    Assert.fail('Not implemented');
  }

  public function testLoadAsync() {
    Assert.fail('Not implemented');
  }

  public function testParse() {
    Assert.fail('Not implemented');
  }

  public function testParseAsync() {
    Assert.fail('Not implemented');
  }

  public function testParseShapes() {
    Assert.fail('Not implemented');
  }

  public function testParseSkeletons() {
    Assert.fail('Not implemented');
  }

  public function testParseGeometries() {
    Assert.fail('Not implemented');
  }

  public function testParseMaterials() {
    Assert.fail('Not implemented');
  }

  public function testParseAnimations() {
    Assert.fail('Not implemented');
  }

  public function testParseImages() {
    Assert.fail('Not implemented');
  }

  public function testParseImagesAsync() {
    Assert.fail('Not implemented');
  }

  public function testParseTextures() {
    Assert.fail('Not implemented');
  }

  public function testParseObject() {
    Assert.fail('Not implemented');
  }

  public function testBindSkeletons() {
    Assert.fail('Not implemented');
  }

  public static function addTests(runner:Runner) {
    runner.addCase(new ObjectLoaderTest());
  }

  public static function main() {
    var runner = new Runner();
    addTests(runner);
    Report.create(runner);
    runner.run();
  }
}