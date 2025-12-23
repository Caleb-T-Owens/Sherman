package je.cto.ctech.transport;

import java.util.Optional;

/**
 * Interface for querying block information in the world.
 *
 * This abstraction allows pipe network traversal to be tested without
 * requiring a Minecraft world instance.
 */
public interface BlockChecker {

    /**
     * Checks if the block at the given position is a pipe.
     *
     * @param pos the position to check
     * @return true if the block is a pipe, false otherwise
     */
    boolean isPipe(BlockPos pos);

    /**
     * Gets the inventory at the given position, if one exists.
     *
     * @param pos the position to check
     * @return Optional containing the inventory, or empty if no inventory exists
     */
    Optional<Inventory> getInventory(BlockPos pos);
}
