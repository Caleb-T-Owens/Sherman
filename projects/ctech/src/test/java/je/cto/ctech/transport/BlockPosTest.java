package je.cto.ctech.transport;

import static org.junit.jupiter.api.Assertions.*;

import java.util.HashSet;
import java.util.Set;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

@DisplayName("BlockPos")
class BlockPosTest {

    @Nested
    @DisplayName("construction and getters")
    class ConstructionTests {

        @Test
        @DisplayName("stores coordinates correctly")
        void storesCoordinates() {
            BlockPos pos = new BlockPos(1, 2, 3);

            assertEquals(1, pos.getX());
            assertEquals(2, pos.getY());
            assertEquals(3, pos.getZ());
        }

        @Test
        @DisplayName("handles negative coordinates")
        void handlesNegativeCoordinates() {
            BlockPos pos = new BlockPos(-10, -20, -30);

            assertEquals(-10, pos.getX());
            assertEquals(-20, pos.getY());
            assertEquals(-30, pos.getZ());
        }

        @Test
        @DisplayName("handles zero coordinates")
        void handlesZeroCoordinates() {
            BlockPos pos = new BlockPos(0, 0, 0);

            assertEquals(0, pos.getX());
            assertEquals(0, pos.getY());
            assertEquals(0, pos.getZ());
        }
    }

    @Nested
    @DisplayName("offset()")
    class OffsetTests {

        @Test
        @DisplayName("returns new BlockPos with offset applied")
        void returnsOffsetPosition() {
            BlockPos original = new BlockPos(5, 10, 15);

            BlockPos result = original.offset(1, 2, 3);

            assertEquals(6, result.getX());
            assertEquals(12, result.getY());
            assertEquals(18, result.getZ());
        }

        @Test
        @DisplayName("does not modify original position")
        void doesNotModifyOriginal() {
            BlockPos original = new BlockPos(5, 10, 15);

            original.offset(1, 2, 3);

            assertEquals(5, original.getX());
            assertEquals(10, original.getY());
            assertEquals(15, original.getZ());
        }

        @Test
        @DisplayName("handles negative offsets")
        void handlesNegativeOffsets() {
            BlockPos original = new BlockPos(5, 10, 15);

            BlockPos result = original.offset(-3, -5, -7);

            assertEquals(2, result.getX());
            assertEquals(5, result.getY());
            assertEquals(8, result.getZ());
        }

        @Test
        @DisplayName("handles zero offset")
        void handlesZeroOffset() {
            BlockPos original = new BlockPos(5, 10, 15);

            BlockPos result = original.offset(0, 0, 0);

            assertEquals(original, result);
        }
    }

    @Nested
    @DisplayName("equals()")
    class EqualsTests {

        @Test
        @DisplayName("equal positions are equal")
        void equalPositionsAreEqual() {
            BlockPos pos1 = new BlockPos(1, 2, 3);
            BlockPos pos2 = new BlockPos(1, 2, 3);

            assertEquals(pos1, pos2);
        }

        @Test
        @DisplayName("different X makes not equal")
        void differentXNotEqual() {
            BlockPos pos1 = new BlockPos(1, 2, 3);
            BlockPos pos2 = new BlockPos(9, 2, 3);

            assertNotEquals(pos1, pos2);
        }

        @Test
        @DisplayName("different Y makes not equal")
        void differentYNotEqual() {
            BlockPos pos1 = new BlockPos(1, 2, 3);
            BlockPos pos2 = new BlockPos(1, 9, 3);

            assertNotEquals(pos1, pos2);
        }

        @Test
        @DisplayName("different Z makes not equal")
        void differentZNotEqual() {
            BlockPos pos1 = new BlockPos(1, 2, 3);
            BlockPos pos2 = new BlockPos(1, 2, 9);

            assertNotEquals(pos1, pos2);
        }

        @Test
        @DisplayName("not equal to null")
        void notEqualToNull() {
            BlockPos pos = new BlockPos(1, 2, 3);

            assertNotEquals(null, pos);
        }

        @Test
        @DisplayName("not equal to different type")
        void notEqualToDifferentType() {
            BlockPos pos = new BlockPos(1, 2, 3);

            assertNotEquals("not a BlockPos", pos);
        }

        @Test
        @DisplayName("reflexive equality")
        void reflexiveEquality() {
            BlockPos pos = new BlockPos(1, 2, 3);

            assertEquals(pos, pos);
        }
    }

    @Nested
    @DisplayName("hashCode()")
    class HashCodeTests {

        @Test
        @DisplayName("equal objects have equal hash codes")
        void equalObjectsEqualHashCodes() {
            BlockPos pos1 = new BlockPos(1, 2, 3);
            BlockPos pos2 = new BlockPos(1, 2, 3);

            assertEquals(pos1.hashCode(), pos2.hashCode());
        }

        @Test
        @DisplayName("works correctly in HashSet")
        void worksInHashSet() {
            Set<BlockPos> set = new HashSet<>();
            set.add(new BlockPos(1, 2, 3));
            set.add(new BlockPos(1, 2, 3)); // Duplicate
            set.add(new BlockPos(4, 5, 6));

            assertEquals(2, set.size());
            assertTrue(set.contains(new BlockPos(1, 2, 3)));
            assertTrue(set.contains(new BlockPos(4, 5, 6)));
        }

        @Test
        @DisplayName("different positions likely have different hash codes")
        void differentPositionsDifferentHashCodes() {
            BlockPos pos1 = new BlockPos(1, 2, 3);
            BlockPos pos2 = new BlockPos(3, 2, 1);

            // Not guaranteed, but should be different for good hash function
            assertNotEquals(pos1.hashCode(), pos2.hashCode());
        }
    }

    @Nested
    @DisplayName("toString()")
    class ToStringTests {

        @Test
        @DisplayName("includes all coordinates")
        void includesAllCoordinates() {
            BlockPos pos = new BlockPos(1, 2, 3);

            String str = pos.toString();

            assertTrue(str.contains("1"));
            assertTrue(str.contains("2"));
            assertTrue(str.contains("3"));
        }
    }
}
