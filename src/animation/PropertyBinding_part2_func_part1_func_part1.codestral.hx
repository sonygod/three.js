class PropertyBinding {

    var path: String;
    var parsedPath: Dynamic;
    var node: Dynamic;
    var rootNode: Dynamic;
    var getValue: Function;
    var setValue: Function;

    public function new(rootNode: Dynamic, path: String, parsedPath: Dynamic = null) {
        this.path = path;
        this.parsedPath = parsedPath != null ? parsedPath : PropertyBinding.parseTrackName(path);
        this.node = PropertyBinding.findNode(rootNode, this.parsedPath.nodeName);
        this.rootNode = rootNode;
        this.getValue = this._getValue_unbound;
        this.setValue = this._setValue_unbound;
    }

    static public function create(root: Dynamic, path: String, parsedPath: Dynamic = null): PropertyBinding {
        if (root == null || !Std.is(root, "isAnimationObjectGroup")) {
            return new PropertyBinding(root, path, parsedPath);
        } else {
            return new PropertyBinding.Composite(root, path, parsedPath);
        }
    }

    static public function sanitizeNodeName(name: String): String {
        return name.replace(/\s/g, '_').replace(ReservedRe, '');
    }

    static public function parseTrackName(trackName: String): Dynamic {
        var matches = TrackRe.exec(trackName);

        if (matches == null) {
            throw 'PropertyBinding: Cannot parse trackName: ' + trackName;
        }

        var results = {
            nodeName: matches[2],
            objectName: matches[3],
            objectIndex: matches[4],
            propertyName: matches[5],
            propertyIndex: matches[6]
        };

        var lastDot = results.nodeName != null ? results.nodeName.lastIndexOf('.') : -1;

        if (lastDot != -1) {
            var objectName = results.nodeName.substring(lastDot + 1);

            if (SupportedObjectNames.indexOf(objectName) != -1) {
                results.nodeName = results.nodeName.substring(0, lastDot);
                results.objectName = objectName;
            }
        }

        if (results.propertyName == null || results.propertyName.length == 0) {
            throw 'PropertyBinding: can not parse propertyName from trackName: ' + trackName;
        }

        return results;
    }

    static public function findNode(root: Dynamic, nodeName: String): Dynamic {
        if (nodeName == null || nodeName == '' || nodeName == '.' || nodeName == '-1' || nodeName == root.name || nodeName == root.uuid) {
            return root;
        }

        if (root.skeleton != null) {
            var bone = root.skeleton.getBoneByName(nodeName);

            if (bone != null) {
                return bone;
            }
        }

        if (root.children != null) {
            var searchNodeSubtree = function(children: Array<Dynamic>): Dynamic {
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

    public function _getValue_unavailable() {}
    public function _setValue_unavailable() {}
    public function _getValue_direct(buffer: Array<Float>, offset: Int) {
        buffer[offset] = this.targetObject[this.propertyName];
    }

    // ... rest of the methods converted here ...

}