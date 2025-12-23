package je.cto.ctech.transport;

import java.util.List;

/**
 * Service interface for transferring items between inventories.
 */
public interface ItemTransferService {

    /**
     * Transfers a single item from input inventories to output inventories.
     *
     * The transfer follows these priorities:
     * 1. Merge into existing stacks of the same item type (if space available)
     * 2. Place in empty slots (if no matching stacks found)
     *
     * @param inputs list of input inventories to pull items from
     * @param outputs list of output inventories to push items to
     * @return true if an item was successfully transferred, false otherwise
     */
    boolean transferOne(List<Inventory> inputs, List<Inventory> outputs);
}
