package je.cto.ctech.transport.impl;

import java.util.List;
import java.util.Optional;

import je.cto.ctech.transport.Inventory;
import je.cto.ctech.transport.ItemData;
import je.cto.ctech.transport.ItemTransferService;

/**
 * Default implementation of item transfer logic.
 *
 * Transfers one item at a time, prioritizing stack merging over using empty slots.
 * This ensures efficient use of inventory space.
 */
public final class DefaultItemTransferService implements ItemTransferService {

    @Override
    public boolean transferOne(List<Inventory> inputs, List<Inventory> outputs) {
        if (inputs == null || outputs == null || inputs.isEmpty() || outputs.isEmpty()) {
            return false;
        }

        // Try each input inventory
        for (Inventory input : inputs) {
            Optional<Boolean> result = tryTransferFromInventory(input, outputs);
            if (result.isPresent()) {
                return true;
            }
        }

        return false;
    }

    /**
     * Attempts to transfer one item from the given input inventory to any output.
     */
    private Optional<Boolean> tryTransferFromInventory(Inventory input, List<Inventory> outputs) {
        for (int inputSlot = 0; inputSlot < input.size(); inputSlot++) {
            Optional<ItemData> optionalItem = input.getStack(inputSlot);
            if (optionalItem.isEmpty()) {
                continue;
            }

            ItemData sourceItem = optionalItem.get();
            if (sourceItem.isEmpty()) {
                continue;
            }

            // Try to merge with existing stack first
            if (tryMergeIntoExistingStack(input, inputSlot, sourceItem, outputs)) {
                return Optional.of(true);
            }

            // Try to place in empty slot
            if (tryPlaceInEmptySlot(input, inputSlot, sourceItem, outputs)) {
                return Optional.of(true);
            }
        }

        return Optional.empty();
    }

    /**
     * Tries to merge one item into an existing stack of the same type.
     * Returns true if transfer succeeded.
     */
    private boolean tryMergeIntoExistingStack(
            Inventory input, int inputSlot, ItemData source, List<Inventory> outputs) {
        for (Inventory output : outputs) {
            for (int outputSlot = 0; outputSlot < output.size(); outputSlot++) {
                Optional<ItemData> optionalTarget = output.getStack(outputSlot);
                if (optionalTarget.isEmpty()) {
                    continue;
                }

                ItemData target = optionalTarget.get();
                if (source.canMergeWith(target) && !target.isFull()) {
                    // Transfer one item - immutable operations return new instances
                    ItemData newTarget = target.withIncrementedCount();
                    ItemData newSource = source.withDecrementedCount();

                    // Write both changes back to inventories
                    output.setStack(outputSlot, newTarget);
                    output.markDirty();

                    updateSourceSlot(input, inputSlot, newSource);
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Tries to place one item in an empty slot.
     * Returns true if transfer succeeded.
     */
    private boolean tryPlaceInEmptySlot(
            Inventory input, int inputSlot, ItemData source, List<Inventory> outputs) {
        for (Inventory output : outputs) {
            for (int outputSlot = 0; outputSlot < output.size(); outputSlot++) {
                Optional<ItemData> existing = output.getStack(outputSlot);
                if (existing.isEmpty()) {
                    // Create new stack with one item
                    ItemData newStack = source.copyWithSingleItem();
                    ItemData newSource = source.withDecrementedCount();

                    output.setStack(outputSlot, newStack);
                    output.markDirty();

                    updateSourceSlot(input, inputSlot, newSource);
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * Updates the source slot after transfer, clearing if empty.
     */
    private void updateSourceSlot(Inventory input, int slot, ItemData newSource) {
        if (newSource.isEmpty()) {
            input.clearSlot(slot);
        } else {
            input.setStack(slot, newSource);
        }
        input.markDirty();
    }
}
