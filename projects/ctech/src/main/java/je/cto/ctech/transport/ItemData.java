package je.cto.ctech.transport;

import java.util.Objects;

/**
 * Immutable representation of item data for transfer operations.
 *
 * This class is fully immutable - all "modification" methods return new instances.
 * This design prevents bugs where changes to ItemData copies are not persisted
 * back to the inventory.
 */
public final class ItemData {
    private final int itemId;
    private final int damage;
    private final int maxCount;
    private final int count;

    public ItemData(int itemId, int damage, int count, int maxCount) {
        if (count < 0) {
            throw new IllegalArgumentException("Count cannot be negative: " + count);
        }
        if (maxCount <= 0) {
            throw new IllegalArgumentException("Max count must be positive: " + maxCount);
        }
        this.itemId = itemId;
        this.damage = damage;
        this.count = count;
        this.maxCount = maxCount;
    }

    public int getItemId() {
        return itemId;
    }

    public int getDamage() {
        return damage;
    }

    public int getCount() {
        return count;
    }

    public int getMaxCount() {
        return maxCount;
    }

    /**
     * Returns the available space in this stack.
     */
    public int getAvailableSpace() {
        return maxCount - count;
    }

    /**
     * Returns true if this stack is full.
     */
    public boolean isFull() {
        return count >= maxCount;
    }

    /**
     * Returns true if this stack is empty.
     */
    public boolean isEmpty() {
        return count <= 0;
    }

    /**
     * Checks if this item can be merged with another item.
     * Items can merge if they have the same item ID and damage value.
     */
    public boolean canMergeWith(ItemData other) {
        if (other == null) return false;
        return this.itemId == other.itemId && this.damage == other.damage;
    }

    /**
     * Returns a new ItemData with count incremented by one.
     *
     * @return new ItemData with incremented count
     * @throws IllegalStateException if already at max count
     */
    public ItemData withIncrementedCount() {
        if (count >= maxCount) {
            throw new IllegalStateException("Cannot increment: already at max count " + maxCount);
        }
        return new ItemData(itemId, damage, count + 1, maxCount);
    }

    /**
     * Returns a new ItemData with count decremented by one.
     *
     * @return new ItemData with decremented count
     * @throws IllegalStateException if already at zero
     */
    public ItemData withDecrementedCount() {
        if (count <= 0) {
            throw new IllegalStateException("Cannot decrement: count is already 0");
        }
        return new ItemData(itemId, damage, count - 1, maxCount);
    }

    /**
     * Creates a new ItemData with count of 1, copying the item type from this instance.
     */
    public ItemData copyWithSingleItem() {
        return new ItemData(itemId, damage, 1, maxCount);
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof ItemData)) return false;
        ItemData other = (ItemData) obj;
        return itemId == other.itemId
            && damage == other.damage
            && count == other.count
            && maxCount == other.maxCount;
    }

    @Override
    public int hashCode() {
        return Objects.hash(itemId, damage, count, maxCount);
    }

    @Override
    public String toString() {
        return String.format("ItemData(id=%d, damage=%d, count=%d/%d)",
            itemId, damage, count, maxCount);
    }
}
