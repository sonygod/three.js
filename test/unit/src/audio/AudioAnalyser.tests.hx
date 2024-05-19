import utest.Test;
import utest.Assert;
import three.audio.AudioAnalyser;

class AudioAnalyserTests {
  public function new() {}

  public static function main() {
    var suite = new TestSuite();
    suite.add(new AudioAnalyserTests());
    utest.Runner.run(suite);
  }

  public function testInstancing() {
    Assert.fail("everything's gonna be alright");
  }

  public function testAnalyser() {
    Assert.fail("everything's gonna be alright");
  }

  public function testData() {
    Assert.fail("everything's gonna be alright");
  }

  public function testGetFrequencyData() {
    Assert.fail("everything's gonna be alright");
  }

  public function testGetAverageFrequency() {
    Assert.fail("everything's gonna be alright");
  }
}