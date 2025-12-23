package je.cto.ctech.transport;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

@DisplayName("ItemData")
class ItemDataTest {

    @Nested
    @DisplayName("construction")
    class ConstructionTests {

        @Test
        @DisplayName("stores all values correctly")
        void storesAllValues() {
            ItemData item = new ItemData(42, 5, 32, 64);

            assertEquals(42, item.getItemId());
            assertEquals(5, item.getDamage());
            assertEquals(32, item.getCount());
            assertEquals(64, item.getMaxCount());
        }

        @Test
        @DisplayName("throws on negative count")
        void throwsOnNegativeCount() {
            assertThrows(IllegalArgumentException.class, () ->
                new ItemData(1, 0, -1, 64)
            );
        }

        @Test
        @DisplayName("throws on zero max count")
        void throwsOnZeroMaxCount() {
            assertThrows(IllegalArgumentException.class, () ->
                new ItemData(1, 0, 10, 0)
            );
        }

        @Test
        @DisplayName("throws on negative max count")
        void throwsOnNegativeMaxCount() {
            assertThrows(IllegalArgumentException.class, () ->
                new ItemData(1, 0, 10, -1)
            );
        }

        @Test
        @DisplayName("allows zero count")
        void allowsZeroCount() {
            ItemData item = new ItemData(1, 0, 0, 64);
            assertEquals(0, item.getCount());
        }
    }

    @Nested
    @DisplayName("isEmpty()")
    class IsEmptyTests {

        @Test
        @DisplayName("returns true for zero count")
        void trueForZeroCount() {
            ItemData item = new ItemData(1, 0, 0, 64);
            assertTrue(item.isEmpty());
        }

        @Test
        @DisplayName("returns false for positive count")
        void falseForPositiveCount() {
            ItemData item = new ItemData(1, 0, 1, 64);
            assertFalse(item.isEmpty());
        }
    }

    @Nested
    @DisplayName("isFull()")
    class IsFullTests {

        @Test
        @DisplayName("returns true when count equals max")
        void trueWhenFull() {
            ItemData item = new ItemData(1, 0, 64, 64);
            assertTrue(item.isFull());
        }

        @Test
        @DisplayName("returns false when count less than max")
        void falseWhenNotFull() {
            ItemData item = new ItemData(1, 0, 32, 64);
            assertFalse(item.isFull());
        }
    }

    @Nested
    @DisplayName("getAvailableSpace()")
    class AvailableSpaceTests {

        @Test
        @DisplayName("returns difference between max and current count")
        void returnsCorrectSpace() {
            ItemData item = new ItemData(1, 0, 20, 64);
            assertEquals(44, item.getAvailableSpace());
        }

        @Test
        @DisplayName("returns zero when full")
        void returnsZeroWhenFull() {
            ItemData item = new ItemData(1, 0, 64, 64);
            assertEquals(0, item.getAvailableSpace());
        }

        @Test
        @DisplayName("returns max when empty")
        void returnsMaxWhenEmpty() {
            ItemData item = new ItemData(1, 0, 0, 64);
            assertEquals(64, item.getAvailableSpace());
        }
    }

    @Nested
    @DisplayName("canMergeWith()")
    class CanMergeWithTests {

        @Test
        @DisplayName("returns true for same item type and damage")
        void trueForMatchingItems() {
            ItemData item1 = new ItemData(42, 5, 10, 64);
            ItemData item2 = new ItemData(42, 5, 20, 64);

            assertTrue(item1.canMergeWith(item2));
        }

        @Test
        @DisplayName("returns false for different item IDs")
        void falseForDifferentIds() {
            ItemData item1 = new ItemData(42, 0, 10, 64);
            ItemData item2 = new ItemData(43, 0, 10, 64);

            assertFalse(item1.canMergeWith(item2));
        }

        @Test
        @DisplayName("returns false for different damage values")
        void falseForDifferentDamage() {
            ItemData item1 = new ItemData(42, 5, 10, 64);
            ItemData item2 = new ItemData(42, 6, 10, 64);

            assertFalse(item1.canMergeWith(item2));
        }

        @Test
        @DisplayName("returns false for null")
        void falseForNull() {
            ItemData item = new ItemData(42, 0, 10, 64);

            assertFalse(item.canMergeWith(null));
        }

        @Test
        @DisplayName("ignores count differences")
        void ignoresCountDifferences() {
            ItemData item1 = new ItemData(42, 0, 1, 64);
            ItemData item2 = new ItemData(42, 0, 64, 64);

            assertTrue(item1.canMergeWith(item2));
        }

        @Test
        @DisplayName("ignores max count differences")
        void ignoresMaxCountDifferences() {
            ItemData item1 = new ItemData(42, 0, 10, 64);
            ItemData item2 = new ItemData(42, 0, 10, 16);

            assertTrue(item1.canMergeWith(item2));
        }
    }

    @Nested
    @DisplayName("withIncrementedCount()")
    class WithIncrementedCountTests {

        @Test
        @DisplayName("returns new instance with count increased by one")
        void returnsNewInstanceWithIncreasedCount() {
            ItemData original = new ItemData(1, 0, 10, 64);

            ItemData result = original.withIncrementedCount();

            assertEquals(11, result.getCount());
        }

        @Test
        @DisplayName("does not modify original")
        void doesNotModifyOriginal() {
            ItemData original = new ItemData(1, 0, 10, 64);

            original.withIncrementedCount();

            assertEquals(10, original.getCount());
        }

        @Test
        @DisplayName("throws when already full")
        void throwsWhenFull() {
            ItemData item = new ItemData(1, 0, 64, 64);

            assertThrows(IllegalStateException.class, item::withIncrementedCount);
        }

        @Test
        @DisplayName("allows incrementing to max")
        void allowsIncrementingToMax() {
            ItemData item = new ItemData(1, 0, 63, 64);

            ItemData result = item.withIncrementedCount();

            assertEquals(64, result.getCount());
            assertTrue(result.isFull());
        }

        @Test
        @DisplayName("preserves other fields")
        void preservesOtherFields() {
            ItemData original = new ItemData(42, 5, 10, 64);

            ItemData result = original.withIncrementedCount();

            assertEquals(42, result.getItemId());
            assertEquals(5, result.getDamage());
            assertEquals(64, result.getMaxCount());
        }
    }

    @Nested
    @DisplayName("withDecrementedCount()")
    class WithDecrementedCountTests {

        @Test
        @DisplayName("returns new instance with count decreased by one")
        void returnsNewInstanceWithDecreasedCount() {
            ItemData original = new ItemData(1, 0, 10, 64);

            ItemData result = original.withDecrementedCount();

            assertEquals(9, result.getCount());
        }

        @Test
        @DisplayName("does not modify original")
        void doesNotModifyOriginal() {
            ItemData original = new ItemData(1, 0, 10, 64);

            original.withDecrementedCount();

            assertEquals(10, original.getCount());
        }

        @Test
        @DisplayName("throws when already empty")
        void throwsWhenEmpty() {
            ItemData item = new ItemData(1, 0, 0, 64);

            assertThrows(IllegalStateException.class, item::withDecrementedCount);
        }

        @Test
        @DisplayName("allows decrementing to zero")
        void allowsDecrementingToZero() {
            ItemData item = new ItemData(1, 0, 1, 64);

            ItemData result = item.withDecrementedCount();

            assertEquals(0, result.getCount());
            assertTrue(result.isEmpty());
        }

        @Test
        @DisplayName("preserves other fields")
        void preservesOtherFields() {
            ItemData original = new ItemData(42, 5, 10, 64);

            ItemData result = original.withDecrementedCount();

            assertEquals(42, result.getItemId());
            assertEquals(5, result.getDamage());
            assertEquals(64, result.getMaxCount());
        }
    }

    @Nested
    @DisplayName("copyWithSingleItem()")
    class CopyWithSingleItemTests {

        @Test
        @DisplayName("creates new item with count of 1")
        void createsWithCountOne() {
            ItemData original = new ItemData(42, 5, 32, 64);

            ItemData copy = original.copyWithSingleItem();

            assertEquals(1, copy.getCount());
        }

        @Test
        @DisplayName("preserves item ID")
        void preservesItemId() {
            ItemData original = new ItemData(42, 5, 32, 64);

            ItemData copy = original.copyWithSingleItem();

            assertEquals(42, copy.getItemId());
        }

        @Test
        @DisplayName("preserves damage value")
        void preservesDamage() {
            ItemData original = new ItemData(42, 5, 32, 64);

            ItemData copy = original.copyWithSingleItem();

            assertEquals(5, copy.getDamage());
        }

        @Test
        @DisplayName("preserves max count")
        void preservesMaxCount() {
            ItemData original = new ItemData(42, 5, 32, 64);

            ItemData copy = original.copyWithSingleItem();

            assertEquals(64, copy.getMaxCount());
        }

        @Test
        @DisplayName("does not modify original")
        void doesNotModifyOriginal() {
            ItemData original = new ItemData(42, 5, 32, 64);

            original.copyWithSingleItem();

            assertEquals(32, original.getCount());
        }
    }

    @Nested
    @DisplayName("equals() and hashCode()")
    class EqualsHashCodeTests {

        @Test
        @DisplayName("equal items are equal")
        void equalItemsAreEqual() {
            ItemData item1 = new ItemData(42, 5, 32, 64);
            ItemData item2 = new ItemData(42, 5, 32, 64);

            assertEquals(item1, item2);
            assertEquals(item1.hashCode(), item2.hashCode());
        }

        @Test
        @DisplayName("different counts make not equal")
        void differentCountsNotEqual() {
            ItemData item1 = new ItemData(42, 5, 32, 64);
            ItemData item2 = new ItemData(42, 5, 33, 64);

            assertNotEquals(item1, item2);
        }
    }
}
