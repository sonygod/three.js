import three.core.Object3D;
import three.materials.LineBasicMaterial;
import three.materials.LineDashedMaterial;
import three.materials.Material;
import three.materials.MeshBasicMaterial;
import three.materials.MeshDepthMaterial;
import three.materials.MeshLambertMaterial;
import three.materials.MeshMatcapMaterial;
import three.materials.MeshNormalMaterial;
import three.materials.MeshPhongMaterial;
import three.materials.MeshPhysicalMaterial;
import three.materials.MeshStandardMaterial;
import three.materials.MeshToonMaterial;
import three.materials.PointsMaterial;
import three.materials.RawShaderMaterial;
import three.materials.ShaderMaterial;
import three.materials.ShadowMaterial;
import three.materials.SpriteMaterial;
import three.math.MathUtils;
import three.objects.Line;
import three.objects.Mesh;
import three.objects.Points;
import three.objects.Sprite;

import ui.UIButton;
import ui.UIInput;
import ui.UIPanel;
import ui.UIRow;
import ui.UISelect;
import ui.UIText;
import ui.UITextArea;

// Commands
import commands.SetMaterialCommand;
import commands.SetMaterialValueCommand;

// Properties
import SidebarMaterialBooleanProperty from "./Sidebar.Material.BooleanProperty";
import SidebarMaterialColorProperty from "./Sidebar.Material.ColorProperty";
import SidebarMaterialConstantProperty from "./Sidebar.Material.ConstantProperty";
import SidebarMaterialMapProperty from "./Sidebar.Material.MapProperty";
import SidebarMaterialNumberProperty from "./Sidebar.Material.NumberProperty";
import SidebarMaterialProgram from "./Sidebar.Material.Program";
import SidebarMaterialRangeValueProperty from "./Sidebar.Material.RangeValueProperty";

class SidebarMaterial {

    static var materialClasses:Map<String, Class<Material>> = [
        'LineBasicMaterial' => LineBasicMaterial,
        'LineDashedMaterial' => LineDashedMaterial,
        'MeshBasicMaterial' => MeshBasicMaterial,
        'MeshDepthMaterial' => MeshDepthMaterial,
        'MeshNormalMaterial' => MeshNormalMaterial,
        'MeshLambertMaterial' => MeshLambertMaterial,
        'MeshMatcapMaterial' => MeshMatcapMaterial,
        'MeshPhongMaterial' => MeshPhongMaterial,
        'MeshToonMaterial' => MeshToonMaterial,
        'MeshStandardMaterial' => MeshStandardMaterial,
        'MeshPhysicalMaterial' => MeshPhysicalMaterial,
        'RawShaderMaterial' => RawShaderMaterial,
        'ShaderMaterial' => ShaderMaterial,
        'ShadowMaterial' => ShadowMaterial,
        'SpriteMaterial' => SpriteMaterial,
        'PointsMaterial' => PointsMaterial
    ];

    static var vertexShaderVariables = [
        'uniform mat4 projectionMatrix;',
        'uniform mat4 modelViewMatrix;\n',
        'attribute vec3 position;\n\n',
    ].join('\n');

    static var meshMaterialOptions:Map<String, String> = [
        'MeshBasicMaterial' => 'MeshBasicMaterial',
        'MeshDepthMaterial' => 'MeshDepthMaterial',
        'MeshNormalMaterial' => 'MeshNormalMaterial',
        'MeshLambertMaterial' => 'MeshLambertMaterial',
        'MeshMatcapMaterial' => 'MeshMatcapMaterial',
        'MeshPhongMaterial' => 'MeshPhongMaterial',
        'MeshToonMaterial' => 'MeshToonMaterial',
        'MeshStandardMaterial' => 'MeshStandardMaterial',
        'MeshPhysicalMaterial' => 'MeshPhysicalMaterial',
        'RawShaderMaterial' => 'RawShaderMaterial',
        'ShaderMaterial' => 'ShaderMaterial',
        'ShadowMaterial' => 'ShadowMaterial'
    ];

    static var lineMaterialOptions:Map<String, String> = [
        'LineBasicMaterial' => 'LineBasicMaterial',
        'LineDashedMaterial' => 'LineDashedMaterial',
        'RawShaderMaterial' => 'RawShaderMaterial',
        'ShaderMaterial' => 'ShaderMaterial'
    ];

    static var spriteMaterialOptions:Map<String, String> = [
        'SpriteMaterial' => 'SpriteMaterial',
        'RawShaderMaterial' => 'RawShaderMaterial',
        'ShaderMaterial' => 'ShaderMaterial'
    ];

    static var pointsMaterialOptions:Map<String, String> = [
        'PointsMaterial' => 'PointsMaterial',
        'RawShaderMaterial' => 'RawShaderMaterial',
        'ShaderMaterial' => 'ShaderMaterial'
    ];

    var editor:Editor;
    var signals:Signals;
    var strings:Strings;

    var currentObject:Object3D;
    var currentMaterialSlot:Int = 0;

    // UI Elements
    var container:UIPanel;
    var materialSlotRow:UIRow;
    var materialSlotSelect:UISelect;
    var materialClassRow:UIRow;
    var materialClass:UISelect;
    var materialUUIDRow:UIRow;
    var materialUUID:UIInput;
    var materialUUIDRenew:UIButton;
    var materialNameRow:UIRow;
    var materialName:UIInput;
    var materialProgram:SidebarMaterialProgram;
    var materialColor:SidebarMaterialColorProperty;
    var materialSpecular:SidebarMaterialColorProperty;
    var materialShininess:SidebarMaterialNumberProperty;
    var materialEmissive:SidebarMaterialColorProperty;
    var materialReflectivity:SidebarMaterialNumberProperty;
    var materialIOR:SidebarMaterialNumberProperty;
    var materialRoughness:SidebarMaterialNumberProperty;
    var materialMetalness:SidebarMaterialNumberProperty;
    // ... (rest of the material properties)

    var materialUserDataRow:UIRow;
    var materialUserData:UITextArea;
    var exportJson:UIButton;

    public function new(editor:Editor) {
        this.editor = editor;
        this.signals = editor.signals;
        this.strings = editor.strings;

        // Create UI elements
        container = new UIPanel();
        container.setBorderTop('0');
        container.setDisplay('none');
        container.setPaddingTop('20px');

        // ... (rest of the UI element creation)

        // Events
        signals.objectSelected.add(objectSelected);
        signals.materialChanged.add(refreshUI);
    }

    function objectSelected(object:Object3D):Void {
        var hasMaterial = false;

        if (object != null && object.material != null) {
            hasMaterial = true;

            if (Std.is(object.material, Array) && cast(object.material, Array<Material>).length == 0) {
                hasMaterial = false;
            }
        }

        if (hasMaterial) {
            currentObject = object;
            refreshUI();
            container.setDisplay('');
        } else {
            currentObject = null;
            container.setDisplay('none');
        }
    }

    // ... (rest of the functions)

    public function getContainer():UIPanel {
        return container;
    }
}

export default SidebarMaterial;