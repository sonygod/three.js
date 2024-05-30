import haxe.unit.TestCase;
import three.loaders.Loader;
import three.loaders.LoadingManager;

class LoaderTest {
  public function new() { }

  public function testInstancing() {
    var object = new Loader();
    assertTrue(object != null, 'Can instantiate a Loader.');
  }

  public function testManager() {
    var object = new Loader().manager;
    assertTrue(Std.is(object, LoadingManager), 'Loader defines a default manager if not supplied in constructor.');
  }

  public function testCrossOrigin() {
    var actual = new Loader().crossOrigin;
    var expected = 'anonymous';
    assertEquals(actual, expected, 'Loader defines crossOrigin.');
  }

  public function testWithCredentials() {
    var actual = new Loader().withCredentials;
    var expected = false;
    assertEquals(actual, expected, 'Loader defines withCredentials.');
  }

  public function testPath() {
    var actual = new Loader().path;
    var expected = '';
    assertEquals(actual, expected, 'Loader defines path.');
  }

  public function testResourcePath() {
    var actual = new Loader().resourcePath;
    var expected = '';
    assertEquals(actual, expected, 'Loader defines resourcePath.');
  }

  public function testRequestHeader() {
    var actual = new Loader().requestHeader;
    var expected = {};
    assertEquals(actual, expected, 'Loader defines requestHeader.');
  }

  public function todoLoad() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoLoadAsync() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoParse() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoSetCrossOrigin() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoSetWithCredentials() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoSetPath() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoSetResourcePath() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  public function todoSetRequestHeader() {
    assertTrue(false, 'everything\'s gonna be alright');
  }

  static public function main() {
    var testCase = new LoaderTest();
    testCase.testInstancing();
    testCase.testManager();
    testCase.testCrossOrigin();
    testCase.testWithCredentials();
    testCase.testPath();
    testCase.testResourcePath();
    testCase.testRequestHeader();
    testCase.todoLoad();
    testCase.todoLoadAsync();
    testCase.todoParse();
    testCase.todoSetCrossOrigin();
    testCase.todoSetWithCredentials();
    testCase.todoSetPath();
    testCase.todoSetResourcePath();
    testCase.todoSetRequestHeader();
  }
}