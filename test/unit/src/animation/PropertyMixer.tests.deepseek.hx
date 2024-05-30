import haxe.unit.Test;
import haxe.unit.Assert;

class PropertyMixerTest {

    static function main() {
        var test = new Test();

        test.add(instancingTest, "Instancing");
        test.add(bindingTest, "binding");
        test.add(valueSizeTest, "valueSize");
        test.add(bufferTest, "buffer");
        test.add(cumulativeWeightTest, "cumulativeWeight");
        test.add(cumulativeWeightAdditiveTest, "cumulativeWeightAdditive");
        test.add(useCountTest, "useCount");
        test.add(referenceCountTest, "referenceCount");
        test.add(accumulateTest, "accumulate");
        test.add(accumulateAdditiveTest, "accumulateAdditive");
        test.add(applyTest, "apply");
        test.add(saveOriginalStateTest, "saveOriginalState");
        test.add(restoreOriginalStateTest, "restoreOriginalState");

        test.run();
    }

    static function instancingTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function bindingTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function valueSizeTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function bufferTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function cumulativeWeightTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function cumulativeWeightAdditiveTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function useCountTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function referenceCountTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function accumulateTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function accumulateAdditiveTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function applyTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function saveOriginalStateTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }

    static function restoreOriginalStateTest(assert:Assert) {
        assert.ok(false, 'everything\'s gonna be alright');
    }
}