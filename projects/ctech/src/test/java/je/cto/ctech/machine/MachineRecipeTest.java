package je.cto.ctech.machine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

@DisplayName("MachineRecipe")
class MachineRecipeTest {

    @Nested
    @DisplayName("construction")
    class ConstructionTests {

        @Test
        @DisplayName("creates recipe with inputs and outputs")
        void createsRecipe() {
            List<MachineItem> inputs = List.of(
                new MachineItem(1, 5),
                new MachineItem(2, 3)
            );
            List<MachineItem> outputs = List.of(
                new MachineItem(3, 2)
            );

            MachineRecipe recipe = new MachineRecipe(inputs, outputs);

            assertEquals(2, recipe.getInputs().size());
            assertEquals(1, recipe.getOutputs().size());
        }

        @Test
        @DisplayName("throws on null inputs")
        void throwsOnNullInputs() {
            List<MachineItem> outputs = List.of(new MachineItem(1, 1));

            assertThrows(IllegalArgumentException.class, () ->
                new MachineRecipe(null, outputs)
            );
        }

        @Test
        @DisplayName("throws on empty inputs")
        void throwsOnEmptyInputs() {
            List<MachineItem> outputs = List.of(new MachineItem(1, 1));

            assertThrows(IllegalArgumentException.class, () ->
                new MachineRecipe(List.of(), outputs)
            );
        }

        @Test
        @DisplayName("throws on null outputs")
        void throwsOnNullOutputs() {
            List<MachineItem> inputs = List.of(new MachineItem(1, 1));

            assertThrows(IllegalArgumentException.class, () ->
                new MachineRecipe(inputs, null)
            );
        }

        @Test
        @DisplayName("throws on empty outputs")
        void throwsOnEmptyOutputs() {
            List<MachineItem> inputs = List.of(new MachineItem(1, 1));

            assertThrows(IllegalArgumentException.class, () ->
                new MachineRecipe(inputs, List.of())
            );
        }

        @Test
        @DisplayName("inputs list is immutable")
        void inputsListIsImmutable() {
            List<MachineItem> inputs = List.of(new MachineItem(1, 1));
            List<MachineItem> outputs = List.of(new MachineItem(2, 1));
            MachineRecipe recipe = new MachineRecipe(inputs, outputs);

            assertThrows(UnsupportedOperationException.class, () ->
                recipe.getInputs().add(new MachineItem(3, 1))
            );
        }

        @Test
        @DisplayName("outputs list is immutable")
        void outputsListIsImmutable() {
            List<MachineItem> inputs = List.of(new MachineItem(1, 1));
            List<MachineItem> outputs = List.of(new MachineItem(2, 1));
            MachineRecipe recipe = new MachineRecipe(inputs, outputs);

            assertThrows(UnsupportedOperationException.class, () ->
                recipe.getOutputs().add(new MachineItem(3, 1))
            );
        }
    }
}
