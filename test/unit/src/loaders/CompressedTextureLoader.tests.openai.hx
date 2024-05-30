import utest.RUNNER;
import utest.ui.Report;

class CompressedTextureLoaderTests {
  public static function main() {
    var runner = new RUNNER();
    runner.addCase(new CompressedTextureLoaderTests());
    Report.createrunner(runner);
    runner.run();
  }

  public function new() {}

  public function testExtending(): Void {
    var object = new CompressedTextureLoader();
    utest.Asssert.isTrue(object instanceof Loader, 'CompressedTextureLoader extends from Loader');
  }

  public function testInstancing(): Void {
    var object = new CompressedTextureLoader();
    utest.Assert.isTrue(object != null, 'Can instantiate a CompressedTextureLoader.');
  }

  public function testLoad(): Void {
    // todo: implement load test
    utest.Assert.fail('Not implemented');
  }
}