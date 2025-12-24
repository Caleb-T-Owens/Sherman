package je.cto.ctech.machine;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import je.cto.ctech.transport.ItemData;
import je.cto.ctech.transport.testutil.CopyingMockInventory;

@DisplayName("DefaultMachineProcessingService")
class DefaultMachineProcessingServiceTest {

    private MachineProcessingService service;
    private static final StackSizeLookup STACK_SIZE_LOOKUP = itemId -> 64;

    @BeforeEach
    void setUp() {
        service = new DefaultMachineProcessingService(STACK_SIZE_LOOKUP);
    }

    @Nested
    @DisplayName("basic processing")
    class BasicProcessingTests {

        @Test
        @DisplayName("processes simple recipe")
        void processesSimpleRecipe() {
            // Recipe: 1 coal (id=263) -> 1 iron (id=265)
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64)); // 5 coal

            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(List.of(recipe), input, output);

            assertTrue(result);
            assertEquals(4, input.getStack(0).get().getCount()); // Consumed 1 coal
            assertEquals(1, output.getStack(0).get().getCount()); // Produced 1 iron
            assertEquals(265, output.getStack(0).get().getItemId());
        }

        @Test
        @DisplayName("consumes exact ingredient count")
        void consumesExactIngredientCount() {
            // Recipe: 3 sticks -> 1 plank
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(280, 3)), // 3 sticks
                List.of(new MachineItem(5, 1))    // 1 plank
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(280, 0, 10, 64)); // 10 sticks

            CopyingMockInventory output = new CopyingMockInventory(1);

            service.tryProcess(List.of(recipe), input, output);

            assertEquals(7, input.getStack(0).get().getCount()); // 10 - 3 = 7
        }

        @Test
        @DisplayName("produces correct output count")
        void producesCorrectOutputCount() {
            // Recipe: 1 iron -> 9 nuggets
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(265, 1)),
                List.of(new MachineItem(371, 9))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(265, 0, 1, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);

            service.tryProcess(List.of(recipe), input, output);

            assertEquals(9, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("clears input slot when all consumed")
        void clearsInputSlotWhenAllConsumed() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 1, 64)); // Exactly 1

            CopyingMockInventory output = new CopyingMockInventory(1);

            service.tryProcess(List.of(recipe), input, output);

            assertTrue(input.getStack(0).isEmpty());
        }
    }

    @Nested
    @DisplayName("recipe matching")
    class RecipeMatchingTests {

        @Test
        @DisplayName("returns false when ingredient not available")
        void returnsFalseWhenIngredientNotAvailable() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            // Empty input

            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(List.of(recipe), input, output);

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false when not enough ingredients")
        void returnsFalseWhenNotEnoughIngredients() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 5)), // Needs 5
                List.of(new MachineItem(265, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 3, 64)); // Only have 3

            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(List.of(recipe), input, output);

            assertFalse(result);
            assertEquals(3, input.getStack(0).get().getCount()); // Unchanged
        }

        @Test
        @DisplayName("uses first matching recipe")
        void usesFirstMatchingRecipe() {
            MachineRecipe recipe1 = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 1)) // iron
            );
            MachineRecipe recipe2 = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(266, 1)) // gold
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);

            service.tryProcess(List.of(recipe1, recipe2), input, output);

            assertEquals(265, output.getStack(0).get().getItemId()); // Iron, not gold
        }

        @Test
        @DisplayName("skips recipe if first doesn't match, uses second")
        void skipsToSecondRecipe() {
            MachineRecipe recipe1 = new MachineRecipe(
                List.of(new MachineItem(999, 1)), // Not available
                List.of(new MachineItem(265, 1))
            );
            MachineRecipe recipe2 = new MachineRecipe(
                List.of(new MachineItem(263, 1)), // Available
                List.of(new MachineItem(266, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);

            service.tryProcess(List.of(recipe1, recipe2), input, output);

            assertEquals(266, output.getStack(0).get().getItemId());
        }
    }

    @Nested
    @DisplayName("multiple ingredients")
    class MultipleIngredientsTests {

        @Test
        @DisplayName("consumes multiple different ingredients")
        void consumesMultipleIngredients() {
            // Recipe: 2 sticks + 3 iron -> 1 sword
            MachineRecipe recipe = new MachineRecipe(
                List.of(
                    new MachineItem(280, 2), // 2 sticks
                    new MachineItem(265, 3)  // 3 iron
                ),
                List.of(new MachineItem(267, 1)) // 1 sword
            );

            CopyingMockInventory input = new CopyingMockInventory(2);
            input.setStack(0, new ItemData(280, 0, 10, 64)); // 10 sticks
            input.setStack(1, new ItemData(265, 0, 10, 64)); // 10 iron

            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(List.of(recipe), input, output);

            assertTrue(result);
            assertEquals(8, input.getStack(0).get().getCount());  // 10 - 2 sticks
            assertEquals(7, input.getStack(1).get().getCount());  // 10 - 3 iron
            assertEquals(1, output.getStack(0).get().getCount()); // 1 sword
        }

        @Test
        @DisplayName("fails if any ingredient missing")
        void failsIfAnyIngredientMissing() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(
                    new MachineItem(280, 2),
                    new MachineItem(265, 3)
                ),
                List.of(new MachineItem(267, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(280, 0, 10, 64)); // Only sticks, no iron

            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(List.of(recipe), input, output);

            assertFalse(result);
        }

        @Test
        @DisplayName("gathers ingredients from multiple slots")
        void gathersFromMultipleSlots() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 5)), // Need 5 coal
                List.of(new MachineItem(265, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(3);
            input.setStack(0, new ItemData(263, 0, 2, 64)); // 2 coal
            input.setStack(1, new ItemData(263, 0, 2, 64)); // 2 coal
            input.setStack(2, new ItemData(263, 0, 2, 64)); // 2 coal (total 6)

            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(List.of(recipe), input, output);

            assertTrue(result);
            // Should have consumed 5 total: 2 + 2 + 1
            assertTrue(input.getStack(0).isEmpty());
            assertTrue(input.getStack(1).isEmpty());
            assertEquals(1, input.getStack(2).get().getCount());
        }
    }

    @Nested
    @DisplayName("multiple outputs")
    class MultipleOutputsTests {

        @Test
        @DisplayName("produces multiple different outputs")
        void producesMultipleOutputs() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(
                    new MachineItem(265, 2), // 2 iron
                    new MachineItem(266, 3)  // 3 gold
                )
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64));

            CopyingMockInventory output = new CopyingMockInventory(2);

            service.tryProcess(List.of(recipe), input, output);

            assertEquals(2, output.getStack(0).get().getCount());
            assertEquals(265, output.getStack(0).get().getItemId());
            assertEquals(3, output.getStack(1).get().getCount());
            assertEquals(266, output.getStack(1).get().getItemId());
        }
    }

    @Nested
    @DisplayName("output space checking")
    class OutputSpaceTests {

        @Test
        @DisplayName("fails if output inventory is full")
        void failsIfOutputFull() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);
            output.setStack(0, new ItemData(999, 0, 64, 64)); // Full with different item

            boolean result = service.tryProcess(List.of(recipe), input, output);

            assertFalse(result);
            assertEquals(5, input.getStack(0).get().getCount()); // Unchanged
        }

        @Test
        @DisplayName("merges into existing matching stack")
        void mergesIntoExistingStack() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 5))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);
            output.setStack(0, new ItemData(265, 0, 10, 64)); // Already has 10 iron

            service.tryProcess(List.of(recipe), input, output);

            assertEquals(15, output.getStack(0).get().getCount()); // 10 + 5
        }

        @Test
        @DisplayName("fails if not enough space even with merging")
        void failsIfNotEnoughSpaceWithMerging() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 10))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);
            output.setStack(0, new ItemData(265, 0, 60, 64)); // Only 4 spaces left

            boolean result = service.tryProcess(List.of(recipe), input, output);

            assertFalse(result);
        }
    }

    @Nested
    @DisplayName("edge cases")
    class EdgeCaseTests {

        @Test
        @DisplayName("returns false for null recipes list")
        void returnsFalseForNullRecipes() {
            CopyingMockInventory input = new CopyingMockInventory(1);
            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(null, input, output);

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false for empty recipes list")
        void returnsFalseForEmptyRecipes() {
            CopyingMockInventory input = new CopyingMockInventory(1);
            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(List.of(), input, output);

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false for null input")
        void returnsFalseForNullInput() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 1))
            );
            CopyingMockInventory output = new CopyingMockInventory(1);

            boolean result = service.tryProcess(List.of(recipe), null, output);

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false for null output")
        void returnsFalseForNullOutput() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 1))
            );
            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64));

            boolean result = service.tryProcess(List.of(recipe), input, null);

            assertFalse(result);
        }

        @Test
        @DisplayName("marks inventories as dirty")
        void marksInventoriesAsDirty() {
            MachineRecipe recipe = new MachineRecipe(
                List.of(new MachineItem(263, 1)),
                List.of(new MachineItem(265, 1))
            );

            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(263, 0, 5, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);

            service.tryProcess(List.of(recipe), input, output);

            assertTrue(input.getMarkDirtyCount() > 0);
            assertTrue(output.getMarkDirtyCount() > 0);
        }
    }
}
