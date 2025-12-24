package je.cto.ctech.machine;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

@DisplayName("MachineItem")
class MachineItemTest {

    @Nested
    @DisplayName("construction")
    class ConstructionTests {

        @Test
        @DisplayName("creates item without damage matching (any damage)")
        void createsWithoutDamageMatching() {
            MachineItem item = new MachineItem(42, 5);

            assertEquals(42, item.getItemId());
            assertEquals(5, item.getCount());
            assertTrue(item.matchesAnyDamage());
            assertEquals(0, item.getDamage());
        }

        @Test
        @DisplayName("creates item with specific damage")
        void createsWithDamage() {
            MachineItem item = new MachineItem(42, 10, 5);

            assertEquals(42, item.getItemId());
            assertEquals(10, item.getDamage());
            assertEquals(5, item.getCount());
            assertFalse(item.matchesAnyDamage());
        }

        @Test
        @DisplayName("throws on zero count")
        void throwsOnZeroCount() {
            assertThrows(IllegalArgumentException.class, () ->
                new MachineItem(42, 0)
            );
        }

        @Test
        @DisplayName("throws on negative count")
        void throwsOnNegativeCount() {
            assertThrows(IllegalArgumentException.class, () ->
                new MachineItem(42, -1)
            );
        }
    }

    @Nested
    @DisplayName("matches()")
    class MatchesTests {

        @Test
        @DisplayName("matches same item id when matching any damage")
        void matchesSameItemIdWithAnyDamage() {
            MachineItem item = new MachineItem(42, 1);

            assertTrue(item.matches(42, 0));
            assertTrue(item.matches(42, 10));
            assertTrue(item.matches(42, 99));
        }

        @Test
        @DisplayName("does not match different item id")
        void doesNotMatchDifferentItemId() {
            MachineItem item = new MachineItem(42, 1);

            assertFalse(item.matches(43, 0));
            assertFalse(item.matches(1, 0));
        }

        @Test
        @DisplayName("matches exact damage when not matching any damage")
        void matchesExactDamage() {
            MachineItem item = new MachineItem(42, 10, 1);

            assertTrue(item.matches(42, 10));
        }

        @Test
        @DisplayName("does not match different damage when not matching any damage")
        void doesNotMatchDifferentDamage() {
            MachineItem item = new MachineItem(42, 10, 1);

            assertFalse(item.matches(42, 0));
            assertFalse(item.matches(42, 11));
        }
    }

    @Nested
    @DisplayName("equals() and hashCode()")
    class EqualsHashCodeTests {

        @Test
        @DisplayName("equal items are equal")
        void equalItemsAreEqual() {
            MachineItem a = new MachineItem(42, 10, 5);
            MachineItem b = new MachineItem(42, 10, 5);

            assertEquals(a, b);
            assertEquals(a.hashCode(), b.hashCode());
        }

        @Test
        @DisplayName("different counts are not equal")
        void differentCountsNotEqual() {
            MachineItem a = new MachineItem(42, 5);
            MachineItem b = new MachineItem(42, 6);

            assertNotEquals(a, b);
        }

        @Test
        @DisplayName("different damage matching modes are not equal")
        void differentDamageModesNotEqual() {
            MachineItem a = new MachineItem(42, 5);      // matches any damage
            MachineItem b = new MachineItem(42, 0, 5);   // matches only damage 0

            assertNotEquals(a, b);
        }
    }
}
