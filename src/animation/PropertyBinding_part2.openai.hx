class PropertyBinding {
  
  public var path:String;
  public var parsedPath:Dynamic;
  public var node:Dynamic;
  public var rootNode:Dynamic;
  public var getValue:Void->Void;
  public var setValue:Void->Void;

  public function new(rootNode:Dynamic, path:String, parsedPath:Dynamic = null) {
    this.path = path;
    this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
    this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
    this.rootNode = rootNode;
    this.getValue = this._getValue_unbound;
    this.setValue = this._setValue_unbound;
  }

  public static function create(root:Dynamic, path:String, parsedPath:Dynamic):PropertyBinding {
    if (root != null && Reflect.hasField(root, "isAnimationObjectGroup") && Reflect.field(root, "isAnimationObjectGroup")) {
      return new PropertyBinding.Composite(root, path, parsedPath);
    } else {
      return new PropertyBinding(root, path, parsedPath);
    }
  }
  
  public static function sanitizeNodeName(name:String):String {
    return StringTools.replace(StringTools.replace(name, " ", "_"), _reservedRe, "");
  }

  public static function parseTrackName(trackName:String):Dynamic {
    var matches = _trackRe.match(trackName);
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
    var lastDot = results.nodeName.lastIndexOf(".");
    if (lastDot != -1) {
      var objectName = results.nodeName.substr(lastDot + 1);
      if (_supportedObjectNames.indexOf(objectName) != -1) {
        results.nodeName = results.nodeName.substr(0, lastDot);
        results.objectName = objectName;
      }
    }
    if (results.propertyName == null || results.propertyName.length == 0) {
      throw new Error("PropertyBinding: can not parse propertyName from trackName: " + trackName);
    }
    return results;
  }

  public static function findNode(root:Dynamic, nodeName:String):Dynamic {
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
        for (childNode in children) {
          if (childNode.name == nodeName || childNode.uuid == nodeName) {
            return childNode;
          }
          var result = searchNodeSubtree(childNode.children);
          if (result != null) return result;
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

  public function _getValue_unavailable():Void {}
  public function _setValue_unavailable():Void {}
  public function _getValue_direct(buffer:Dynamic, offset:Int):Void {}
  public function _getValue_array(buffer:Dynamic, offset:Int):Void {}
  public function _getValue_arrayElement(buffer:Dynamic, offset:Int):Void {}
  public function _getValue_toArray(buffer:Dynamic, offset:Int):Void {}
  // other getter functions...
  // setter functions...
  // bind function...
  // unbind function...
}