package three.js.examples.jsm.libs;

class Component {
  public var _pool:Null<Component>;

  public function new(props:Dynamic = false) {
    if (props != false) {
      var schema = Type.getClass(this).schema;

      for (key in schema.keys()) {
        if (props != null && Reflect.hasField(props, key)) {
          Reflect.setField(this, key, props[key]);
        } else {
          var schemaProp = schema[key];
          if (schemaProp.hasOwnProperty("default")) {
            Reflect.setField(this, key, schemaProp.type.clone(schemaProp.default));
          } else {
            var type = schemaProp.type;
            Reflect.setField(this, key, type.clone(type.default));
          }
        }
      }

      if (props != null) {
        this.checkUndefinedAttributes(props);
      }
    }

    this._pool = null;
  }

  public function copy(source:Dynamic):Component {
    var schema = Type.getClass(this).schema;

    for (key in schema.keys()) {
      var prop = schema[key];

      if (Reflect.hasField(source, key)) {
        Reflect.setField(this, key, prop.type.copy(Reflect.field(source, key), Reflect.field(this, key)));
      }
    }

    // @DEBUG
    {
      this.checkUndefinedAttributes(source);
    }

    return this;
  }

  public function clone():Component {
    return new Type.getClass(this)().copy(this);
  }

  public function reset():Void {
    var schema = Type.getClass(this).schema;

    for (key in schema.keys()) {
      var schemaProp = schema[key];

      if (schemaProp.hasOwnProperty("default")) {
        Reflect.setField(this, key, schemaProp.type.copy(schemaProp.default, Reflect.field(this, key)));
      } else {
        var type = schemaProp.type;
        Reflect.setField(this, key, type.copy(type.default, Reflect.field(this, key)));
      }
    }
  }

  public function dispose():Void {
    if (this._pool != null) {
      this._pool.release(this);
    }
  }

  public function getName():String {
    return Type.getClass(this).getName();
  }

  public function checkUndefinedAttributes(src:Dynamic):Void {
    var schema = Type.getClass(this).schema;

    // Check that the attributes defined in source are also defined in the schema
    for (key in Reflect.fields(src)) {
      if (!Reflect.hasField(schema, key)) {
        trace('Trying to set attribute \'$key\' not defined in the \'${Type.getClassName(Type.getClass(this))}\' schema. Please fix the schema, the attribute value won\'t be set');
      }
    }
  }
}