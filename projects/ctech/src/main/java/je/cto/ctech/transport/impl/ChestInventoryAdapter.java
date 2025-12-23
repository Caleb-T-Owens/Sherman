package je.cto.ctech.transport.impl;

import java.util.Objects;
import java.util.Optional;

import je.cto.ctech.transport.Inventory;
import je.cto.ctech.transport.ItemData;
import net.minecraft.block.entity.ChestBlockEntity;
import net.minecraft.item.ItemStack;

/**
 * Adapter that wraps a Minecraft ChestBlockEntity as an Inventory interface.
 *
 * This allows the item transfer logic to work with Minecraft chests while
 * remaining decoupled from Minecraft's implementation details.
 */
public final class ChestInventoryAdapter implements Inventory {

    private final ChestBlockEntity chest;

    public ChestInventoryAdapter(ChestBlockEntity chest) {
        this.chest = Objects.requireNonNull(chest, "Chest cannot be null");
    }

    @Override
    public int size() {
        return chest.size();
    }

    @Override
    public Optional<ItemData> getStack(int slot) {
        if (slot < 0 || slot >= size()) {
            throw new IndexOutOfBoundsException("Slot " + slot + " out of range [0, " + size() + ")");
        }

        ItemStack stack = chest.getStack(slot);
        if (stack == null || stack.count <= 0) {
            return Optional.empty();
        }

        return Optional.of(new ItemData(
            stack.itemId,
            stack.getDamage(),
            stack.count,
            stack.getMaxCount()
        ));
    }

    @Override
    public void setStack(int slot, ItemData item) {
        if (slot < 0 || slot >= size()) {
            throw new IndexOutOfBoundsException("Slot " + slot + " out of range [0, " + size() + ")");
        }

        if (item == null || item.isEmpty()) {
            chest.setStack(slot, null);
        } else {
            ItemStack stack = new ItemStack(item.getItemId(), item.getCount(), item.getDamage());
            chest.setStack(slot, stack);
        }
    }

    @Override
    public void markDirty() {
        chest.markDirty();
    }

    /**
     * Returns the underlying ChestBlockEntity.
     * Use sparingly - prefer working through the Inventory interface.
     */
    public ChestBlockEntity getChest() {
        return chest;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (!(obj instanceof ChestInventoryAdapter)) return false;
        ChestInventoryAdapter other = (ChestInventoryAdapter) obj;
        // Identity comparison for the underlying chest
        return this.chest == other.chest;
    }

    @Override
    public int hashCode() {
        return System.identityHashCode(chest);
    }
}
