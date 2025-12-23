package je.cto.ctech.transport;

import java.util.Set;

/**
 * Interface for traversing connected pipe networks.
 *
 * Implementations should find all pipes connected to a starting position,
 * handling cycles and branches in the network.
 */
public interface PipeNetworkTraverser {

    /**
     * Traverses the pipe network starting from the given position.
     *
     * The starting position itself is NOT included in the result (it's typically
     * the extractor block, not a pipe). Only connected pipe blocks are returned.
     *
     * @param start the starting position (typically the extractor location)
     * @param blockChecker used to determine if a position contains a pipe
     * @return an unmodifiable set of all pipe positions in the connected network
     */
    Set<BlockPos> traverse(BlockPos start, BlockChecker blockChecker);
}
