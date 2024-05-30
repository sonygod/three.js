import qunit.QUnit;

class TestExtras {
    public static function main() {
        var module = QUnit.module("Extras");

        module.module("Earcut", function() {
            QUnit.todo("triangulate", function(assert) {
                assert.ok(false, "everything's gonna be alright");
            });
        });
    }
}