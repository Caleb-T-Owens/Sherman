package je.cto.ctech.transport.impl;

import static org.junit.jupiter.api.Assertions.*;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import je.cto.ctech.transport.ItemData;
import je.cto.ctech.transport.ItemTransferService;
import je.cto.ctech.transport.testutil.CopyingMockInventory;
import je.cto.ctech.transport.testutil.MockInventory;

@DisplayName("DefaultItemTransferService")
class DefaultItemTransferServiceTest {

    private ItemTransferService transferService;

    @BeforeEach
    void setUp() {
        transferService = new DefaultItemTransferService();
    }

    @Nested
    @DisplayName("basic transfer")
    class BasicTransferTests {

        @Test
        @DisplayName("transfers one item to empty slot")
        void transfersToEmptySlot() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 64, 64));

            MockInventory output = new MockInventory(1);

            boolean result = transferService.transferOne(List.of(input), List.of(output));

            assertTrue(result);
            assertEquals(63, input.getStack(0).get().getCount());
            assertEquals(1, output.getStack(0).get().getCount());
            assertEquals(42, output.getStack(0).get().getItemId());
        }

        @Test
        @DisplayName("transfers one item, not entire stack")
        void transfersOnlyOneItem() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(1);

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(9, input.getStack(0).get().getCount());
            assertEquals(1, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("cleans up source when last item transferred")
        void cleansUpEmptySource() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 1, 64));

            MockInventory output = new MockInventory(1);

            transferService.transferOne(List.of(input), List.of(output));

            assertTrue(input.getStack(0).isEmpty());
            assertEquals(1, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("preserves item damage value")
        void preservesDamageValue() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 15, 10, 64));

            MockInventory output = new MockInventory(1);

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(15, output.getStack(0).get().getDamage());
        }

        @Test
        @DisplayName("marks inventories as dirty")
        void marksInventoriesDirty() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(1);

            transferService.transferOne(List.of(input), List.of(output));

            assertTrue(input.getMarkDirtyCount() > 0);
            assertTrue(output.getMarkDirtyCount() > 0);
        }
    }

    @Nested
    @DisplayName("stack merging")
    class StackMergingTests {

        @Test
        @DisplayName("merges into existing stack of same type")
        void mergesIntoExistingStack() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(1);
            output.setStack(0, new ItemData(42, 0, 32, 64));

            boolean result = transferService.transferOne(List.of(input), List.of(output));

            assertTrue(result);
            assertEquals(9, input.getStack(0).get().getCount());
            assertEquals(33, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("prefers merging over empty slot")
        void prefersMergingOverEmptySlot() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(2);
            output.setStack(0, new ItemData(42, 0, 32, 64)); // Matching stack
            // Slot 1 is empty

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(33, output.getStack(0).get().getCount());
            assertTrue(output.getStack(1).isEmpty()); // Empty slot unused
        }

        @Test
        @DisplayName("does not merge different item types")
        void doesNotMergeDifferentTypes() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(2);
            output.setStack(0, new ItemData(99, 0, 32, 64)); // Different item
            // Slot 1 is empty

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(32, output.getStack(0).get().getCount()); // Unchanged
            assertEquals(1, output.getStack(1).get().getCount()); // Used empty slot
        }

        @Test
        @DisplayName("does not merge different damage values")
        void doesNotMergeDifferentDamage() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 5, 10, 64));

            MockInventory output = new MockInventory(2);
            output.setStack(0, new ItemData(42, 10, 32, 64)); // Same item, different damage
            // Slot 1 is empty

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(32, output.getStack(0).get().getCount()); // Unchanged
            assertEquals(5, output.getStack(1).get().getDamage()); // New stack with original damage
        }

        @Test
        @DisplayName("does not merge into full stack")
        void doesNotMergeIntoFullStack() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(2);
            output.setStack(0, new ItemData(42, 0, 64, 64)); // Full matching stack
            // Slot 1 is empty

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(64, output.getStack(0).get().getCount()); // Still full
            assertEquals(1, output.getStack(1).get().getCount()); // Used empty slot
        }
    }

    @Nested
    @DisplayName("no transfer conditions")
    class NoTransferTests {

        @Test
        @DisplayName("returns false when inputs list is empty")
        void returnsFalseForEmptyInputs() {
            MockInventory output = new MockInventory(1);

            boolean result = transferService.transferOne(List.of(), List.of(output));

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false when outputs list is empty")
        void returnsFalseForEmptyOutputs() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            boolean result = transferService.transferOne(List.of(input), List.of());

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false when inputs list is null")
        void returnsFalseForNullInputs() {
            MockInventory output = new MockInventory(1);

            boolean result = transferService.transferOne(null, List.of(output));

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false when outputs list is null")
        void returnsFalseForNullOutputs() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            boolean result = transferService.transferOne(List.of(input), null);

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false when all input slots are empty")
        void returnsFalseForEmptyInputSlots() {
            MockInventory input = new MockInventory(3);
            // All slots empty

            MockInventory output = new MockInventory(1);

            boolean result = transferService.transferOne(List.of(input), List.of(output));

            assertFalse(result);
        }

        @Test
        @DisplayName("returns false when all output slots are full with non-matching items")
        void returnsFalseWhenOutputsFull() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(1);
            output.setStack(0, new ItemData(99, 0, 64, 64)); // Full, different item

            boolean result = transferService.transferOne(List.of(input), List.of(output));

            assertFalse(result);
            assertEquals(10, input.getStack(0).get().getCount()); // Unchanged
        }

        @Test
        @DisplayName("returns false when matching stacks are full")
        void returnsFalseWhenMatchingStacksFull() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(1);
            output.setStack(0, new ItemData(42, 0, 64, 64)); // Full matching item

            boolean result = transferService.transferOne(List.of(input), List.of(output));

            assertFalse(result);
        }
    }

    @Nested
    @DisplayName("multiple inventories")
    class MultipleInventoriesTests {

        @Test
        @DisplayName("tries multiple input inventories")
        void triesMultipleInputs() {
            MockInventory input1 = new MockInventory(1); // Empty
            MockInventory input2 = new MockInventory(1);
            input2.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(1);

            boolean result = transferService.transferOne(
                    List.of(input1, input2),
                    List.of(output));

            assertTrue(result);
            assertEquals(9, input2.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("tries multiple output inventories")
        void triesMultipleOutputs() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output1 = new MockInventory(1);
            output1.setStack(0, new ItemData(99, 0, 64, 64)); // Full, different item

            MockInventory output2 = new MockInventory(1); // Empty

            boolean result = transferService.transferOne(
                    List.of(input),
                    List.of(output1, output2));

            assertTrue(result);
            assertEquals(1, output2.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("uses first available input")
        void usesFirstAvailableInput() {
            MockInventory input1 = new MockInventory(1);
            input1.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory input2 = new MockInventory(1);
            input2.setStack(0, new ItemData(99, 0, 10, 64));

            MockInventory output = new MockInventory(1);

            transferService.transferOne(List.of(input1, input2), List.of(output));

            assertEquals(9, input1.getStack(0).get().getCount());
            assertEquals(10, input2.getStack(0).get().getCount()); // Unchanged
            assertEquals(42, output.getStack(0).get().getItemId()); // From input1
        }

        @Test
        @DisplayName("searches all outputs for merge target")
        void searchesAllOutputsForMerge() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output1 = new MockInventory(1);
            output1.setStack(0, new ItemData(99, 0, 32, 64)); // Non-matching

            MockInventory output2 = new MockInventory(1);
            output2.setStack(0, new ItemData(42, 0, 32, 64)); // Matching

            transferService.transferOne(
                    List.of(input),
                    List.of(output1, output2));

            assertEquals(32, output1.getStack(0).get().getCount()); // Unchanged
            assertEquals(33, output2.getStack(0).get().getCount()); // Merged
        }
    }

    @Nested
    @DisplayName("multiple slots")
    class MultipleSlotsTests {

        @Test
        @DisplayName("searches through all input slots")
        void searchesAllInputSlots() {
            MockInventory input = new MockInventory(3);
            // Slots 0 and 1 empty
            input.setStack(2, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(1);

            boolean result = transferService.transferOne(List.of(input), List.of(output));

            assertTrue(result);
            assertEquals(9, input.getStack(2).get().getCount());
        }

        @Test
        @DisplayName("uses first available input slot")
        void usesFirstAvailableInputSlot() {
            MockInventory input = new MockInventory(3);
            input.setStack(0, new ItemData(42, 0, 10, 64));
            input.setStack(1, new ItemData(99, 0, 10, 64));
            input.setStack(2, new ItemData(88, 0, 10, 64));

            MockInventory output = new MockInventory(1);

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(9, input.getStack(0).get().getCount()); // Decremented
            assertEquals(10, input.getStack(1).get().getCount()); // Unchanged
            assertEquals(10, input.getStack(2).get().getCount()); // Unchanged
        }

        @Test
        @DisplayName("searches all output slots for merge")
        void searchesAllOutputSlotsForMerge() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(3);
            output.setStack(0, new ItemData(99, 0, 32, 64)); // Non-matching
            output.setStack(1, new ItemData(42, 0, 32, 64)); // Matching
            // Slot 2 empty

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(32, output.getStack(0).get().getCount()); // Unchanged
            assertEquals(33, output.getStack(1).get().getCount()); // Merged
            assertTrue(output.getStack(2).isEmpty()); // Still empty
        }

        @Test
        @DisplayName("uses first empty output slot when no merge target")
        void usesFirstEmptyOutputSlot() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(3);
            output.setStack(0, new ItemData(99, 0, 32, 64)); // Non-matching
            // Slots 1 and 2 empty

            transferService.transferOne(List.of(input), List.of(output));

            assertTrue(output.getStack(1).isPresent());
            assertTrue(output.getStack(2).isEmpty());
        }
    }

    @Nested
    @DisplayName("repeated transfers")
    class RepeatedTransferTests {

        @Test
        @DisplayName("multiple transfers move items correctly")
        void multipleTransfersWork() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            MockInventory output = new MockInventory(1);

            // Transfer 5 items one at a time
            for (int i = 0; i < 5; i++) {
                assertTrue(transferService.transferOne(List.of(input), List.of(output)));
            }

            assertEquals(5, input.getStack(0).get().getCount());
            assertEquals(5, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("can empty entire stack")
        void canEmptyEntireStack() {
            MockInventory input = new MockInventory(1);
            input.setStack(0, new ItemData(42, 0, 5, 64));

            MockInventory output = new MockInventory(1);

            // Transfer all 5 items
            for (int i = 0; i < 5; i++) {
                assertTrue(transferService.transferOne(List.of(input), List.of(output)));
            }

            // 6th transfer should fail
            assertFalse(transferService.transferOne(List.of(input), List.of(output)));

            assertTrue(input.getStack(0).isEmpty());
            assertEquals(5, output.getStack(0).get().getCount());
        }
    }

    /**
     * Tests using CopyingMockInventory to verify changes are persisted correctly.
     *
     * These tests catch bugs where ItemData is modified but not written back to
     * the inventory - the exact bug we fixed by making ItemData immutable.
     */
    @Nested
    @DisplayName("persistence with copying inventory")
    class PersistenceTests {

        @Test
        @DisplayName("persists merge into existing stack")
        void persistsMergeIntoExistingStack() {
            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);
            output.setStack(0, new ItemData(42, 0, 5, 64));

            transferService.transferOne(List.of(input), List.of(output));

            // Verify changes were actually persisted, not just in-memory
            assertEquals(9, input.getStack(0).get().getCount());
            assertEquals(6, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("persists transfer to empty slot")
        void persistsTransferToEmptySlot() {
            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);

            transferService.transferOne(List.of(input), List.of(output));

            assertEquals(9, input.getStack(0).get().getCount());
            assertEquals(1, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("multiple transfers accumulate correctly")
        void multipleTransfersAccumulate() {
            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);
            output.setStack(0, new ItemData(42, 0, 5, 64));

            // Transfer 3 items
            for (int i = 0; i < 3; i++) {
                assertTrue(transferService.transferOne(List.of(input), List.of(output)));
            }

            assertEquals(7, input.getStack(0).get().getCount());
            assertEquals(8, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("clears source slot when emptied")
        void clearsSourceWhenEmptied() {
            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(42, 0, 1, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);

            transferService.transferOne(List.of(input), List.of(output));

            assertTrue(input.getStack(0).isEmpty());
            assertEquals(1, output.getStack(0).get().getCount());
        }

        @Test
        @DisplayName("repeated reads return consistent state")
        void repeatedReadsReturnConsistentState() {
            CopyingMockInventory input = new CopyingMockInventory(1);
            input.setStack(0, new ItemData(42, 0, 10, 64));

            CopyingMockInventory output = new CopyingMockInventory(1);

            transferService.transferOne(List.of(input), List.of(output));

            // Read multiple times - should get consistent results
            assertEquals(9, input.getStack(0).get().getCount());
            assertEquals(9, input.getStack(0).get().getCount());
            assertEquals(1, output.getStack(0).get().getCount());
            assertEquals(1, output.getStack(0).get().getCount());
        }
    }
}
