package three.core;

import three.core.UniformsGroup;
import three.core.EventDispatcher;
import utest.Test;
import utest.Runner;
import utest.ui.Report;

class UniformsGroupTests {
  public function new() {}

  public function testAll() {
    var runner = new Runner();
    runner.addCase(new UniformsGroupTests());
    var report = new Report(runner);
    report.display();
  }

  function testExtending() {
    var object = new UniformsGroup();
    assertTrue(object instanceof EventDispatcher);
  }

  function testInstancing() {
    var object = new UniformsGroup();
    assertTrue(object != null);
  }

  function testId() {
    todo("id");
  }

  function testName() {
    todo("name");
  }

  function testUsage() {
    todo("usage");
  }

  function testUniforms() {
    todo("uniforms");
  }

  function testIsUniformsGroup() {
    var object = new UniformsGroup();
    assertTrue(object.isUniformsGroup);
  }

  function testAdd() {
    todo("add");
  }

  function testRemove() {
    todo("remove");
  }

  function testSetName() {
    todo("setName");
  }

  function testSetUsage() {
    todo("setUsage");
  }

  function testDispose() {
    var object = new UniformsGroup();
    object.dispose();
  }

  function testCopy() {
    todo("copy");
  }

  function testClone() {
    todo("clone");
  }
}