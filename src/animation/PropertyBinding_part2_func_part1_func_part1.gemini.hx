class PropertyBinding {
  public var path:String;
  public var parsedPath:Dynamic;
  public var node:Dynamic;
  public var rootNode:Dynamic;
  public var getValue:Dynamic;
  public var setValue:Dynamic;

  public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
    this.path = path;
    this.parsedPath = parsedPath == null ? PropertyBinding.parseTrackName(path) : parsedPath;
    this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
    this.rootNode = rootNode;
    this.getValue = this._getValue_unbound;
    this.setValue = this._setValue_unbound;
  }

  static public function create(root:Dynamic, path:String, parsedPath:Dynamic):PropertyBinding {
    if (!root || !root.isAnimationObjectGroup) {
      return new PropertyBinding(root, path, parsedPath);
    }
    return new PropertyBinding.Composite(root, path, parsedPath);
  }

  static public function sanitizeNodeName(name:String):String {
    return name.replace(new EReg("\\s", "g"), "_").replace(_reservedRe, "");
  }

  static public function parseTrackName(trackName:String):Dynamic {
    var matches = _trackRe.exec(trackName);
    if (matches == null) {
      throw new Error("PropertyBinding: Cannot parse trackName: " + trackName);
    }
    var results = {
      nodeName: matches[2],
      objectName: matches[3],
      objectIndex: matches[4],
      propertyName: matches[5],
      propertyIndex: matches[6]
    };
    var lastDot = results.nodeName != null && results.nodeName.lastIndexOf(".");
    if (lastDot != null && lastDot != -1) {
      var objectName = results.nodeName.substring(lastDot + 1);
      if (_supportedObjectNames.indexOf(objectName) != -1) {
        results.nodeName = results.nodeName.substring(0, lastDot);
        results.objectName = objectName;
      }
    }
    if (results.propertyName == null || results.propertyName.length == 0) {
      throw new Error("PropertyBinding: can not parse propertyName from trackName: " + trackName);
    }
    return results;
  }

  static public function findNode(root:Dynamic, nodeName:String):Dynamic {
    if (nodeName == null || nodeName == "" || nodeName == "." || nodeName == -1 || nodeName == root.name || nodeName == root.uuid) {
      return root;
    }
    if (root.skeleton != null) {
      var bone = root.skeleton.getBoneByName(nodeName);
      if (bone != null) {
        return bone;
      }
    }
    if (root.children != null) {
      var searchNodeSubtree = function(children:Array<Dynamic>):Dynamic {
        for (var i = 0; i < children.length; i++) {
          var childNode = children[i];
          if (childNode.name == nodeName || childNode.uuid == nodeName) {
            return childNode;
          }
          var result = searchNodeSubtree(childNode.children);
          if (result != null) {
            return result;
          }
        }
        return null;
      };
      var subTreeNode = searchNodeSubtree(root.children);
      if (subTreeNode != null) {
        return subTreeNode;
      }
    }
    return null;
  }

  public function _getValue_unavailable(targetArray:Array<Float>, offset:Int):Void {
  }

  public function _setValue_unavailable(sourceArray:Array<Float>, offset:Int):Void {
  }

  public function _getValue_direct(buffer:Array<Float>, offset:Int):Void {
    buffer[offset] = this.targetObject[this.propertyName];
  }

  public function _getValue_array(buffer:Array<Float>, offset:Int):Void {
    var source = this.resolvedProperty;
    for (var i = 0, n = source.length; i != n; i++) {
      buffer[offset++] = source[i];
    }
  }

  public function _getValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
    buffer[offset] = this.resolvedProperty[this.propertyIndex];
  }

  public function _getValue_toArray(buffer:Array<Float>, offset:Int):Void {
    this.resolvedProperty.toArray(buffer, offset);
  }

  public function _setValue_direct(buffer:Array<Float>, offset:Int):Void {
    this.targetObject[this.propertyName] = buffer[offset];
  }

  public function _setValue_direct_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
    this.targetObject[this.propertyName] = buffer[offset];
    this.targetObject.needsUpdate = true;
  }

  public function _setValue_direct_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
    this.targetObject[this.propertyName] = buffer[offset];
    this.targetObject.matrixWorldNeedsUpdate = true;
  }

  public function _setValue_array(buffer:Array<Float>, offset:Int):Void {
    var dest = this.resolvedProperty;
    for (var i = 0, n = dest.length; i != n; i++) {
      dest[i] = buffer[offset++];
    }
  }

  public function _setValue_array_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
    var dest = this.resolvedProperty;
    for (var i = 0, n = dest.length; i != n; i++) {
      dest[i] = buffer[offset++];
    }
    this.targetObject.needsUpdate = true;
  }

  public function _setValue_array_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
    var dest = this.resolvedProperty;
    for (var i = 0, n = dest.length; i != n; i++) {
      dest[i] = buffer[offset++];
    }
    this.targetObject.matrixWorldNeedsUpdate = true;
  }

  public function _setValue_arrayElement(buffer:Array<Float>, offset:Int):Void {
    this.resolvedProperty[this.propertyIndex] = buffer[offset];
  }

  public function _setValue_arrayElement_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
    this.resolvedProperty[this.propertyIndex] = buffer[offset];
    this.targetObject.needsUpdate = true;
  }

  public function _setValue_arrayElement_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
    this.resolvedProperty[this.propertyIndex] = buffer[offset];
    this.targetObject.matrixWorldNeedsUpdate = true;
  }

  public function _setValue_fromArray(buffer:Array<Float>, offset:Int):Void {
    this.resolvedProperty.fromArray(buffer, offset);
  }

  public function _setValue_fromArray_setNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
    this.resolvedProperty.fromArray(buffer, offset);
    this.targetObject.needsUpdate = true;
  }

  public function _setValue_fromArray_setMatrixWorldNeedsUpdate(buffer:Array<Float>, offset:Int):Void {
    this.resolvedProperty.fromArray(buffer, offset);
    this.targetObject.matrixWorldNeedsUpdate = true;
  }

  public function _getValue_unbound(targetArray:Array<Float>, offset:Int):Void {
    this.bind();
    this.getValue(targetArray, offset);
  }

  public function _setValue_unbound(sourceArray:Array<Float>, offset:Int):Void {
    this.bind();
    this.setValue(sourceArray, offset);
  }

  public function bind():Void {
    var targetObject = this.node;
    var parsedPath = this.parsedPath;
    var objectName = parsedPath.objectName;
    var propertyName = parsedPath.propertyName;
    var propertyIndex = parsedPath.propertyIndex;
    if (targetObject == null) {
      targetObject = PropertyBinding.findNode(this.rootNode, parsedPath.nodeName);
      this.node = targetObject;
    }
    this.getValue = this._getValue_unavailable;
    this.setValue = this._setValue_unavailable;
    if (targetObject == null) {
      Sys.println("THREE.PropertyBinding: No target node found for track: " + this.path + ".");
      return;
    }
    if (objectName != null) {
      var objectIndex = parsedPath.objectIndex;
      switch (objectName) {
        case "materials":
          if (targetObject.material == null) {
            Sys.println("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
            return;
          }
          if (targetObject.material.materials == null) {
            Sys.println("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.", this);
            return;
          }
          targetObject = targetObject.material.materials;
          break;
        case "bones":
          if (targetObject.skeleton == null) {
            Sys.println("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.", this);
            return;
          }
          targetObject = targetObject.skeleton.bones;
          for (var i = 0; i < targetObject.length; i++) {
            if (targetObject[i].name == objectIndex) {
              objectIndex = i;
              break;
            }
          }
          break;
        case "map":
          if ("map" in targetObject) {
            targetObject = targetObject.map;
            break;
          }
          if (targetObject.material == null) {
            Sys.println("THREE.PropertyBinding: Can not bind to material as node does not have a material.", this);
            return;
          }
          if (targetObject.material.map == null) {
            Sys.println("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.", this);
            return;
          }
          targetObject = targetObject.material.map;
          break;
        default:
          if (targetObject[objectName] == null) {
            Sys.println("THREE.PropertyBinding: Can not bind to objectName of node undefined.", this);
            return;
          }
          targetObject = targetObject[objectName];
      }
      if (objectIndex != null) {
        if (targetObject[objectIndex] == null) {
          Sys.println("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.", this, targetObject);
          return;
        }
        targetObject = targetObject[objectIndex];
      }
    }
    var nodeProperty = targetObject[propertyName];
    if (nodeProperty == null) {
      var nodeName = parsedPath.nodeName;
      Sys.println("THREE.PropertyBinding: Trying to update property for track: " + nodeName + "." + propertyName + " but it wasn't found.", targetObject);
      return;
    }
    var versioning = this.Versioning.None;
    this.targetObject = targetObject;
    if (targetObject.needsUpdate != null) {
      versioning = this.Versioning.NeedsUpdate;
    } else if (targetObject.matrixWorldNeedsUpdate != null) {
      versioning = this.Versioning.MatrixWorldNeedsUpdate;
    }
    var bindingType = this.BindingType.Direct;
    if (propertyIndex != null) {
      if (propertyName == "morphTargetInfluences") {
        if (targetObject.geometry == null) {
          Sys.println("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.", this);
          return;
        }
        if (targetObject.geometry.morphAttributes == null) {
          Sys.println("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.", this);
          return;
        }
        if (targetObject.morphTargetDictionary[propertyIndex] != null) {
          propertyIndex = targetObject.morphTargetDictionary[propertyIndex];
        }
      }
      bindingType = this.BindingType.ArrayElement;
      this.resolvedProperty = nodeProperty;
      this.propertyIndex = propertyIndex;
    } else if (nodeProperty.fromArray != null && nodeProperty.toArray != null) {
      bindingType = this.BindingType.HasFromToArray;
      this.resolvedProperty = nodeProperty;
    } else if (Std.is(nodeProperty, Array)) {
      bindingType = this.BindingType.EntireArray;
      this.resolvedProperty = nodeProperty;
    } else {
      this.propertyName = propertyName;
    }
    this.getValue = this.GetterByBindingType[bindingType];
    this.setValue = this.SetterByBindingTypeAndVersioning[bindingType][versioning];
  }

  public function unbind():Void {
    this.node = null;
    this.getValue = this._getValue_unbound;
    this.setValue = this._setValue_unbound;
  }

  static private var _trackRe:EReg = new EReg("\\s*(.*?)\\[(.*?)\\]\\.(.*?)(\\s*\\(.*?\\))?(.*?)$");
  static private var _reservedRe:EReg = new EReg("(?:[\\s\\.])?(?:[\\s\\.]*)?(?:[\\s\\.]*)?");
  static private var _supportedObjectNames = ["materials", "bones", "map"];
  static private var Versioning = {
    None: 0,
    NeedsUpdate: 1,
    MatrixWorldNeedsUpdate: 2
  };
  static private var BindingType = {
    Direct: 0,
    ArrayElement: 1,
    HasFromToArray: 2,
    EntireArray: 3
  };
  static private var GetterByBindingType = [
    _getValue_direct,
    _getValue_arrayElement,
    _getValue_toArray,
    _getValue_array
  ];
  static private var SetterByBindingTypeAndVersioning = [
    [
      _setValue_direct,
      _setValue_direct_setNeedsUpdate,
      _setValue_direct_setMatrixWorldNeedsUpdate
    ],
    [
      _setValue_arrayElement,
      _setValue_arrayElement_setNeedsUpdate,
      _setValue_arrayElement_setMatrixWorldNeedsUpdate
    ],
    [
      _setValue_fromArray,
      _setValue_fromArray_setNeedsUpdate,
      _setValue_fromArray_setMatrixWorldNeedsUpdate
    ],
    [
      _setValue_array,
      _setValue_array_setNeedsUpdate,
      _setValue_array_setMatrixWorldNeedsUpdate
    ]
  ];
  public var resolvedProperty:Dynamic;
  public var propertyIndex:Int;
  public var propertyName:String;
  public var targetObject:Dynamic;
  static public class Composite extends PropertyBinding {
    public var _targetGroups:Array<Dynamic>;
    public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic) {
      this._targetGroups = [];
      super(rootNode, path, parsedPath);
    }

    override public function bind():Void {
      if (this._targetGroups.length == 0) {
        var root = this.rootNode;
        for (var i = 0; i < root.length; i++) {
          this._targetGroups.push(new PropertyBinding(root[i], this.path, this.parsedPath));
        }
      }
      var targetGroups = this._targetGroups;
      for (var i = 0; i < targetGroups.length; i++) {
        targetGroups[i].bind();
      }
    }

    override public function unbind():Void {
      var targetGroups = this._targetGroups;
      for (var i = 0; i < targetGroups.length; i++) {
        targetGroups[i].unbind();
      }
    }

    override public function getValue(targetArray:Array<Float>, offset:Int):Void {
      var targetGroups = this._targetGroups;
      for (var i = 0; i < targetGroups.length; i++) {
        targetGroups[i].getValue(targetArray, offset);
        offset += targetGroups[i].resolvedProperty.length;
      }
    }

    override public function setValue(sourceArray:Array<Float>, offset:Int):Void {
      var targetGroups = this._targetGroups;
      for (var i = 0; i < targetGroups.length; i++) {
        var length = targetGroups[i].resolvedProperty.length;
        targetGroups[i].setValue(sourceArray, offset);
        offset += length;
      }
    }
  }
}