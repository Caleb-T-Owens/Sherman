package je.cto.ctech.machine;

/**
 * Interface for looking up the maximum stack size for an item.
 * This allows the processing logic to remain pure and testable.
 */
public interface StackSizeLookup {

    /**
     * Returns the maximum stack size for the given item ID.
     *
     * @param itemId the item ID
     * @return the maximum stack size
     */
    int getMaxStackSize(int itemId);
}
