import editors.BaseNodeEditor;
import editors.NodeEditorUtils;

class Vector4Editor extends BaseNodeEditor {
    
    public function new() {
        var { element, inputNode } = NodeEditorUtils.createElementFromJSON({
            inputType: "vec4",
            inputConnection: false
        });
        
        super("Vector 4", inputNode, 350);
        
        element.addEventListener("changeInput", function(_) { invalidate(); });
        
        add(element);
    }
    
}