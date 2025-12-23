package je.cto.ctech.transport.testutil;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import je.cto.ctech.transport.Inventory;
import je.cto.ctech.transport.ItemData;

/**
 * Mock implementation of Inventory for testing purposes.
 */
public class MockInventory implements Inventory {

    private final int size;
    private final Map<Integer, ItemData> slots;
    private int markDirtyCount = 0;

    public MockInventory(int size) {
        if (size <= 0) {
            throw new IllegalArgumentException("Size must be positive");
        }
        this.size = size;
        this.slots = new HashMap<>();
    }

    @Override
    public int size() {
        return size;
    }

    @Override
    public Optional<ItemData> getStack(int slot) {
        validateSlot(slot);
        return Optional.ofNullable(slots.get(slot));
    }

    @Override
    public void setStack(int slot, ItemData item) {
        validateSlot(slot);
        if (item == null || item.isEmpty()) {
            slots.remove(slot);
        } else {
            slots.put(slot, item);
        }
    }

    @Override
    public void markDirty() {
        markDirtyCount++;
    }

    /**
     * Returns how many times markDirty() was called.
     * Useful for verifying that inventories are properly marked as modified.
     */
    public int getMarkDirtyCount() {
        return markDirtyCount;
    }

    /**
     * Resets the markDirty counter.
     */
    public void resetMarkDirtyCount() {
        markDirtyCount = 0;
    }

    /**
     * Returns true if any slot contains an item.
     */
    public boolean hasAnyItems() {
        return !slots.isEmpty();
    }

    /**
     * Returns the total count of all items across all slots.
     */
    public int getTotalItemCount() {
        return slots.values().stream()
            .mapToInt(ItemData::getCount)
            .sum();
    }

    private void validateSlot(int slot) {
        if (slot < 0 || slot >= size) {
            throw new IndexOutOfBoundsException(
                "Slot " + slot + " out of range [0, " + size + ")"
            );
        }
    }
}
