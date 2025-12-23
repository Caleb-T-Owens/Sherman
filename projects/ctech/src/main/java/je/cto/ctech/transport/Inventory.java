package je.cto.ctech.transport;

import java.util.Optional;

/**
 * Abstract interface for inventory operations.
 *
 * This interface decouples item transfer logic from Minecraft's ChestBlockEntity,
 * allowing the transfer algorithms to be tested in isolation.
 */
public interface Inventory {

    /**
     * Returns the number of slots in this inventory.
     */
    int size();

    /**
     * Gets the item data at the specified slot.
     *
     * @param slot the slot index (0-based)
     * @return Optional containing the item data, or empty if the slot is empty
     * @throws IndexOutOfBoundsException if slot is out of range
     */
    Optional<ItemData> getStack(int slot);

    /**
     * Sets the item data at the specified slot.
     *
     * @param slot the slot index (0-based)
     * @param item the item data to set, or null to clear the slot
     * @throws IndexOutOfBoundsException if slot is out of range
     */
    void setStack(int slot, ItemData item);

    /**
     * Clears the specified slot.
     *
     * @param slot the slot index (0-based)
     */
    default void clearSlot(int slot) {
        setStack(slot, null);
    }

    /**
     * Marks this inventory as modified, triggering any necessary persistence.
     */
    void markDirty();

    /**
     * Finds the first slot containing an item that matches the predicate.
     *
     * @return Optional containing the slot index, or empty if no matching slot found
     */
    default Optional<Integer> findFirstOccupiedSlot() {
        for (int i = 0; i < size(); i++) {
            if (getStack(i).isPresent()) {
                return Optional.of(i);
            }
        }
        return Optional.empty();
    }

    /**
     * Finds the first empty slot.
     *
     * @return Optional containing the slot index, or empty if no empty slot found
     */
    default Optional<Integer> findFirstEmptySlot() {
        for (int i = 0; i < size(); i++) {
            if (getStack(i).isEmpty()) {
                return Optional.of(i);
            }
        }
        return Optional.empty();
    }
}
