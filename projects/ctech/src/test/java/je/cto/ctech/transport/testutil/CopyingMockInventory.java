package je.cto.ctech.transport.testutil;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import je.cto.ctech.transport.Inventory;
import je.cto.ctech.transport.ItemData;

/**
 * Mock inventory that returns copies from getStack(), mimicking ChestInventoryAdapter.
 *
 * This inventory behaves like the real Minecraft adapter: each getStack() call
 * returns a new ItemData instance. This helps catch bugs where code modifies
 * an ItemData but forgets to write it back with setStack().
 *
 * Use this in tests that verify the transfer service correctly persists changes.
 */
public class CopyingMockInventory implements Inventory {

    private final int size;
    private final Map<Integer, StoredItem> slots;
    private int markDirtyCount = 0;

    public CopyingMockInventory(int size) {
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
        StoredItem stored = slots.get(slot);
        if (stored == null) {
            return Optional.empty();
        }
        // Return a COPY, just like ChestInventoryAdapter does
        return Optional.of(new ItemData(
            stored.itemId,
            stored.damage,
            stored.count,
            stored.maxCount
        ));
    }

    @Override
    public void setStack(int slot, ItemData item) {
        validateSlot(slot);
        if (item == null || item.isEmpty()) {
            slots.remove(slot);
        } else {
            // Store the values, not the reference
            slots.put(slot, new StoredItem(
                item.getItemId(),
                item.getDamage(),
                item.getCount(),
                item.getMaxCount()
            ));
        }
    }

    @Override
    public void markDirty() {
        markDirtyCount++;
    }

    /**
     * Returns how many times markDirty() was called.
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

    private void validateSlot(int slot) {
        if (slot < 0 || slot >= size) {
            throw new IndexOutOfBoundsException(
                "Slot " + slot + " out of range [0, " + size + ")"
            );
        }
    }

    /**
     * Internal storage that doesn't use ItemData to ensure we're truly copying.
     */
    private static final class StoredItem {
        final int itemId;
        final int damage;
        final int count;
        final int maxCount;

        StoredItem(int itemId, int damage, int count, int maxCount) {
            this.itemId = itemId;
            this.damage = damage;
            this.count = count;
            this.maxCount = maxCount;
        }
    }
}
