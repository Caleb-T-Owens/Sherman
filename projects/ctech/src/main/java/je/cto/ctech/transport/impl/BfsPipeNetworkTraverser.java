package je.cto.ctech.transport.impl;

import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.Queue;
import java.util.Set;

import je.cto.ctech.transport.BlockChecker;
import je.cto.ctech.transport.BlockPos;
import je.cto.ctech.transport.PipeNetworkTraverser;

/**
 * Breadth-First Search implementation of pipe network traversal.
 *
 * This implementation explores the pipe network layer by layer, starting from
 * pipes adjacent to the starting position. It handles:
 * - Linear pipe chains
 * - Branching networks
 * - Circular/looping networks (via visited set)
 * - Disconnected regions (only connected pipes are found)
 */
public final class BfsPipeNetworkTraverser implements PipeNetworkTraverser {

    /**
     * Direction offsets for the 6 adjacent blocks (up, down, north, south, east, west).
     */
    private static final int[][] DIRECTION_OFFSETS = {
        { 0,  1,  0},  // Up
        { 0, -1,  0},  // Down
        { 1,  0,  0},  // East (+X)
        {-1,  0,  0},  // West (-X)
        { 0,  0,  1},  // South (+Z)
        { 0,  0, -1}   // North (-Z)
    };

    @Override
    public Set<BlockPos> traverse(BlockPos start, BlockChecker blockChecker) {
        if (start == null || blockChecker == null) {
            throw new IllegalArgumentException("Start position and block checker must not be null");
        }

        Set<BlockPos> pipeNetwork = new HashSet<>();
        Queue<BlockPos> toExplore = new LinkedList<>();

        // Find pipes adjacent to start position and add them as starting points
        for (int[] offset : DIRECTION_OFFSETS) {
            BlockPos neighbor = start.offset(offset[0], offset[1], offset[2]);
            if (blockChecker.isPipe(neighbor)) {
                pipeNetwork.add(neighbor);
                toExplore.add(neighbor);
            }
        }

        // BFS: explore all connected pipes
        while (!toExplore.isEmpty()) {
            BlockPos current = toExplore.poll();

            for (int[] offset : DIRECTION_OFFSETS) {
                BlockPos neighbor = current.offset(offset[0], offset[1], offset[2]);

                // Skip the start position - we only want connected pipes, not the origin
                if (neighbor.equals(start)) {
                    continue;
                }

                // Only process unvisited pipes
                if (!pipeNetwork.contains(neighbor) && blockChecker.isPipe(neighbor)) {
                    pipeNetwork.add(neighbor);
                    toExplore.add(neighbor);
                }
            }
        }

        return Collections.unmodifiableSet(pipeNetwork);
    }
}
