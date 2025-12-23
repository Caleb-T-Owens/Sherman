package je.cto.ctech.transport.impl;

import static org.junit.jupiter.api.Assertions.*;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import je.cto.ctech.transport.BlockChecker;
import je.cto.ctech.transport.BlockPos;
import je.cto.ctech.transport.Inventory;
import je.cto.ctech.transport.PipeNetworkTraverser;

@DisplayName("BfsPipeNetworkTraverser")
class BfsPipeNetworkTraverserTest {

    private PipeNetworkTraverser traverser;

    @BeforeEach
    void setUp() {
        traverser = new BfsPipeNetworkTraverser();
    }

    /**
     * Creates a BlockChecker that recognizes pipes at the given positions.
     */
    private BlockChecker checkerWithPipes(Set<BlockPos> pipePositions) {
        return new BlockChecker() {
            @Override
            public boolean isPipe(BlockPos pos) {
                return pipePositions.contains(pos);
            }

            @Override
            public Optional<Inventory> getInventory(BlockPos pos) {
                return Optional.empty();
            }
        };
    }

    @Nested
    @DisplayName("basic traversal")
    class BasicTraversalTests {

        @Test
        @DisplayName("returns empty set when no adjacent pipes")
        void returnsEmptyWhenNoPipes() {
            BlockChecker checker = checkerWithPipes(Set.of());
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertTrue(result.isEmpty());
        }

        @Test
        @DisplayName("finds single adjacent pipe")
        void findsSingleAdjacentPipe() {
            BlockPos pipe = new BlockPos(1, 0, 0);
            BlockChecker checker = checkerWithPipes(Set.of(pipe));
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(1, result.size());
            assertTrue(result.contains(pipe));
        }

        @Test
        @DisplayName("finds pipes in all six directions")
        void findsPipesInAllDirections() {
            Set<BlockPos> pipes = Set.of(
                new BlockPos(0, 1, 0),   // Up
                new BlockPos(0, -1, 0),  // Down
                new BlockPos(1, 0, 0),   // East
                new BlockPos(-1, 0, 0),  // West
                new BlockPos(0, 0, 1),   // South
                new BlockPos(0, 0, -1)   // North
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(6, result.size());
            assertTrue(result.containsAll(pipes));
        }

        @Test
        @DisplayName("does not include starting position")
        void doesNotIncludeStartPosition() {
            // Even if start position is somehow a pipe, it should not be included
            BlockPos start = new BlockPos(0, 0, 0);
            BlockPos pipe = new BlockPos(1, 0, 0);
            Set<BlockPos> pipes = new HashSet<>();
            pipes.add(start);
            pipes.add(pipe);
            BlockChecker checker = checkerWithPipes(pipes);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertFalse(result.contains(start));
            assertTrue(result.contains(pipe));
        }
    }

    @Nested
    @DisplayName("linear chains")
    class LinearChainTests {

        @Test
        @DisplayName("traverses linear pipe chain")
        void traversesLinearChain() {
            // Start -> Pipe1 -> Pipe2 -> Pipe3
            Set<BlockPos> pipes = Set.of(
                new BlockPos(1, 0, 0),
                new BlockPos(2, 0, 0),
                new BlockPos(3, 0, 0)
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(3, result.size());
            assertTrue(result.containsAll(pipes));
        }

        @Test
        @DisplayName("traverses long vertical chain")
        void traversesVerticalChain() {
            Set<BlockPos> pipes = Set.of(
                new BlockPos(0, 1, 0),
                new BlockPos(0, 2, 0),
                new BlockPos(0, 3, 0),
                new BlockPos(0, 4, 0),
                new BlockPos(0, 5, 0)
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(5, result.size());
            assertTrue(result.containsAll(pipes));
        }

        @Test
        @DisplayName("handles diagonal chain (step pattern)")
        void handlesDiagonalChain() {
            // Diagonal in steps: each pipe connects to next
            Set<BlockPos> pipes = Set.of(
                new BlockPos(1, 0, 0),
                new BlockPos(1, 1, 0),
                new BlockPos(2, 1, 0),
                new BlockPos(2, 2, 0)
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(4, result.size());
            assertTrue(result.containsAll(pipes));
        }
    }

    @Nested
    @DisplayName("branching networks")
    class BranchingNetworkTests {

        @Test
        @DisplayName("traverses T-junction")
        void traversesTJunction() {
            //       Pipe3
            //         |
            // Pipe1-Pipe2-Pipe4
            Set<BlockPos> pipes = Set.of(
                new BlockPos(1, 0, 0),  // Pipe1 (adjacent to start)
                new BlockPos(2, 0, 0),  // Pipe2 (center of T)
                new BlockPos(2, 1, 0),  // Pipe3 (up from center)
                new BlockPos(3, 0, 0)   // Pipe4 (right from center)
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(4, result.size());
            assertTrue(result.containsAll(pipes));
        }

        @Test
        @DisplayName("traverses cross junction")
        void traversesCrossJunction() {
            //       Pipe2
            //         |
            // Pipe1-Center-Pipe3
            //         |
            //       Pipe4
            BlockPos center = new BlockPos(1, 0, 0);
            Set<BlockPos> pipes = Set.of(
                center,
                new BlockPos(1, 1, 0),   // Up
                new BlockPos(1, -1, 0),  // Down
                new BlockPos(2, 0, 0),   // Right
                new BlockPos(1, 0, 1)    // Forward
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(5, result.size());
            assertTrue(result.containsAll(pipes));
        }

        @Test
        @DisplayName("traverses multiple branches from start")
        void traversesMultipleBranches() {
            // Start has pipes in multiple directions, each with extensions
            Set<BlockPos> pipes = Set.of(
                // Branch 1: East
                new BlockPos(1, 0, 0),
                new BlockPos(2, 0, 0),
                // Branch 2: Up
                new BlockPos(0, 1, 0),
                new BlockPos(0, 2, 0),
                // Branch 3: South
                new BlockPos(0, 0, 1),
                new BlockPos(0, 0, 2)
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(6, result.size());
            assertTrue(result.containsAll(pipes));
        }
    }

    @Nested
    @DisplayName("circular networks")
    class CircularNetworkTests {

        @Test
        @DisplayName("handles simple loop without infinite loop")
        void handlesSimpleLoop() {
            // Square loop
            // Start-P1-P2
            //       |  |
            //      P4-P3
            Set<BlockPos> pipes = Set.of(
                new BlockPos(1, 0, 0),  // P1
                new BlockPos(2, 0, 0),  // P2
                new BlockPos(2, 0, 1),  // P3
                new BlockPos(1, 0, 1)   // P4
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(4, result.size());
            assertTrue(result.containsAll(pipes));
        }

        @Test
        @DisplayName("handles figure-8 loop")
        void handlesFigure8Loop() {
            // Two connected loops
            Set<BlockPos> pipes = Set.of(
                // First loop
                new BlockPos(1, 0, 0),
                new BlockPos(2, 0, 0),
                new BlockPos(2, 1, 0),
                new BlockPos(1, 1, 0),
                // Second loop (shares edge with first)
                new BlockPos(3, 0, 0),
                new BlockPos(3, 1, 0)
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(6, result.size());
            assertTrue(result.containsAll(pipes));
        }

        @Test
        @DisplayName("handles 3D cube structure")
        void handles3DCube() {
            // 2x2x2 cube of pipes
            Set<BlockPos> pipes = new HashSet<>();
            for (int x = 1; x <= 2; x++) {
                for (int y = 0; y <= 1; y++) {
                    for (int z = 0; z <= 1; z++) {
                        pipes.add(new BlockPos(x, y, z));
                    }
                }
            }
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(8, result.size());
            assertTrue(result.containsAll(pipes));
        }
    }

    @Nested
    @DisplayName("disconnected networks")
    class DisconnectedNetworkTests {

        @Test
        @DisplayName("does not find disconnected pipes")
        void doesNotFindDisconnectedPipes() {
            // Pipe near start + disconnected pipe far away
            Set<BlockPos> pipes = Set.of(
                new BlockPos(1, 0, 0),   // Connected
                new BlockPos(100, 0, 0)  // Disconnected (gap)
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(1, result.size());
            assertTrue(result.contains(new BlockPos(1, 0, 0)));
            assertFalse(result.contains(new BlockPos(100, 0, 0)));
        }

        @Test
        @DisplayName("does not find diagonally adjacent pipes")
        void doesNotFindDiagonalPipes() {
            // Diagonal is not adjacent in Minecraft (no face touching)
            Set<BlockPos> pipes = Set.of(
                new BlockPos(1, 1, 0),  // Diagonal
                new BlockPos(1, 1, 1)   // 3D diagonal
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertTrue(result.isEmpty());
        }
    }

    @Nested
    @DisplayName("edge cases")
    class EdgeCaseTests {

        @Test
        @DisplayName("throws on null start position")
        void throwsOnNullStart() {
            BlockChecker checker = checkerWithPipes(Set.of());

            assertThrows(IllegalArgumentException.class, () ->
                traverser.traverse(null, checker)
            );
        }

        @Test
        @DisplayName("throws on null block checker")
        void throwsOnNullChecker() {
            BlockPos start = new BlockPos(0, 0, 0);

            assertThrows(IllegalArgumentException.class, () ->
                traverser.traverse(start, null)
            );
        }

        @Test
        @DisplayName("returns unmodifiable set")
        void returnsUnmodifiableSet() {
            BlockPos pipe = new BlockPos(1, 0, 0);
            BlockChecker checker = checkerWithPipes(Set.of(pipe));
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertThrows(UnsupportedOperationException.class, () ->
                result.add(new BlockPos(99, 99, 99))
            );
        }

        @Test
        @DisplayName("handles negative coordinates")
        void handlesNegativeCoordinates() {
            Set<BlockPos> pipes = Set.of(
                new BlockPos(-1, 0, 0),
                new BlockPos(-2, 0, 0),
                new BlockPos(-2, -1, 0)
            );
            BlockChecker checker = checkerWithPipes(pipes);
            BlockPos start = new BlockPos(0, 0, 0);

            Set<BlockPos> result = traverser.traverse(start, checker);

            assertEquals(3, result.size());
            assertTrue(result.containsAll(pipes));
        }
    }
}
