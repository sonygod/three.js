Here is the equivalent Haxe code:
```
package three.js.examples.jm.renderers.common.nodes;

import Uniform;

class FloatNodeUniform extends Uniform.FloatUniform {
  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super(nodeUniform.name, nodeUniform.value);
    this.nodeUniform = nodeUniform;
  }

  public function getValue():Dynamic {
    return this.nodeUniform.value;
  }
}

class Vector2NodeUniform extends Uniform.Vector2Uniform {
  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super(nodeUniform.name, nodeUniform.value);
    this.nodeUniform = nodeUniform;
  }

  public function getValue():Dynamic {
    return this.nodeUniform.value;
  }
}

class Vector3NodeUniform extends Uniform.Vector3Uniform {
  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super(nodeUniform.name, nodeUniform.value);
    this.nodeUniform = nodeUniform;
  }

  public function getValue():Dynamic {
    return this.nodeUniform.value;
  }
}

class Vector4NodeUniform extends Uniform.Vector4Uniform {
  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super(nodeUniform.name, nodeUniform.value);
    this.nodeUniform = nodeUniform;
  }

  public function getValue():Dynamic {
    return this.nodeUniform.value;
  }
}

class ColorNodeUniform extends Uniform.ColorUniform {
  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super(nodeUniform.name, nodeUniform.value);
    this.nodeUniform = nodeUniform;
  }

  public function getValue():Dynamic {
    return this.nodeUniform.value;
  }
}

class Matrix3NodeUniform extends Uniform.Matrix3Uniform {
  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super(nodeUniform.name, nodeUniform.value);
    this.nodeUniform = nodeUniform;
  }

  public function getValue():Dynamic {
    return this.nodeUniform.value;
  }
}

class Matrix4NodeUniform extends Uniform.Matrix4Uniform {
  public var nodeUniform:Dynamic;

  public function new(nodeUniform:Dynamic) {
    super(nodeUniform.name, nodeUniform.value);
    this.nodeUniform = nodeUniform;
  }

  public function getValue():Dynamic {
    return this.nodeUniform.value;
  }
}
```
Note that in Haxe, we don't need to use the `export` keyword to make the classes publicly accessible. Instead, we use the `public` access modifier to make the classes and their members publicly accessible.

Also, note that in Haxe, we need to specify the package name at the top of the file, and use the `import` statement to import the `Uniform` class from the `Uniform.hx` file.