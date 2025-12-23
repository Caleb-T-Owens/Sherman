package je.cto.ctech.blockentity;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.Set;

import je.cto.ctech.CTech;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.entity.ChestBlockEntity;
import net.minecraft.item.ItemStack;

public class BasicExtractorBlockEntity extends BlockEntity {
    private int counter = 0;

    // Helper class to store positions
    private static class BlockPos {
        int x, y, z;

        BlockPos(int x, int y, int z) {
            this.x = x;
            this.y = y;
            this.z = z;
        }

        @Override
        public boolean equals(Object obj) {
            if (!(obj instanceof BlockPos))
                return false;
            BlockPos other = (BlockPos) obj;
            return x == other.x && y == other.y && z == other.z;
        }

        @Override
        public int hashCode() {
            int hash = 7;
            hash = hash * 31 + x;
            hash = hash * 31 + y;
            hash = hash * 31 + z;
            return hash;
        }
    }

    @Override
    public void tick() {
        ++counter;
        if (counter < 10) {
            return;
        }
        counter = 0;

        // Step 1: Find input chests (directly adjacent to extractor)
        List<ChestBlockEntity> inputChests = findAdjacentChests();

        // Step 2: Traverse the entire connected pipe network starting from this
        // extractor
        Set<BlockPos> pipeNetwork = traversePipeNetwork();

        // Step 3: Find output chests (adjacent to any pipe in network, excluding
        // inputs)
        List<ChestBlockEntity> outputChests = findChestsAdjacentToPipes(pipeNetwork, inputChests);

        // Step 4: Transfer one item
        transferOneItem(inputChests, outputChests);
    }

    /**
     * Find all chests directly adjacent to this extractor
     */
    private List<ChestBlockEntity> findAdjacentChests() {
        List<ChestBlockEntity> chests = new ArrayList<>();

        // Check all 6 directions
        int[][] offsets = {
                { 0, 1, 0 }, // Up
                { 0, -1, 0 }, // Down
                { 1, 0, 0 }, // East
                { -1, 0, 0 }, // West
                { 0, 0, 1 }, // South
                { 0, 0, -1 } // North
        };

        for (int[] offset : offsets) {
            BlockEntity entity = world.getBlockEntity(x + offset[0], y + offset[1], z + offset[2]);
            if (entity instanceof ChestBlockEntity) {
                chests.add((ChestBlockEntity) entity);
            }
        }

        return chests;
    }

    /**
     * Traverse the entire connected pipe network using BFS (Breadth-First Search).
     * Starts from this extractor's position and explores all connected pipes.
     * Prevents infinite loops by tracking visited pipes.
     */
    private Set<BlockPos> traversePipeNetwork() {
        Set<BlockPos> pipeNetwork = new HashSet<>();
        Queue<BlockPos> queue = new LinkedList<>();

        int[][] offsets = {
                { 0, 1, 0 }, // Up
                { 0, -1, 0 }, // Down
                { 1, 0, 0 }, // East
                { -1, 0, 0 }, // West
                { 0, 0, 1 }, // South
                { 0, 0, -1 } // North
        };

        // Find adjacent pipes as starting points
        for (int[] offset : offsets) {
            int px = this.x + offset[0];
            int py = this.y + offset[1];
            int pz = this.z + offset[2];

            int blockId = world.getBlockId(px, py, pz);
            if (blockId == CTech.basicItemPipeBlock.id) {
                BlockPos pipePos = new BlockPos(px, py, pz);
                pipeNetwork.add(pipePos);
                queue.add(pipePos);
            }
        }

        // BFS traversal from starting pipes
        while (!queue.isEmpty()) {
            BlockPos currentPipe = queue.poll();

            // Check all 6 adjacent positions
            for (int[] offset : offsets) {
                int nx = currentPipe.x + offset[0];
                int ny = currentPipe.y + offset[1];
                int nz = currentPipe.z + offset[2];

                BlockPos neighborPos = new BlockPos(nx, ny, nz);

                // If not visited and is a pipe, add to network
                if (!pipeNetwork.contains(neighborPos)) {
                    int blockId = world.getBlockId(nx, ny, nz);
                    if (blockId == CTech.basicItemPipeBlock.id) {
                        pipeNetwork.add(neighborPos);
                        queue.add(neighborPos);
                    }
                }
            }
        }

        return pipeNetwork;
    }

    /**
     * Find all chests adjacent to any pipe in the network, excluding input chests.
     * This searches the entire connected pipe network for output destinations.
     */
    private List<ChestBlockEntity> findChestsAdjacentToPipes(Set<BlockPos> pipeNetwork,
            List<ChestBlockEntity> inputChests) {
        List<ChestBlockEntity> outputChests = new ArrayList<>();

        int[][] offsets = {
                { 0, 1, 0 }, // Up
                { 0, -1, 0 }, // Down
                { 1, 0, 0 }, // East
                { -1, 0, 0 }, // West
                { 0, 0, 1 }, // South
                { 0, 0, -1 } // North
        };

        for (BlockPos pipe : pipeNetwork) {
            for (int[] offset : offsets) {
                BlockEntity entity = world.getBlockEntity(
                        pipe.x + offset[0],
                        pipe.y + offset[1],
                        pipe.z + offset[2]);

                if (entity instanceof ChestBlockEntity) {
                    ChestBlockEntity chest = (ChestBlockEntity) entity;

                    // Don't add if it's already an input chest or already in outputs
                    if (!inputChests.contains(chest) && !outputChests.contains(chest)) {
                        outputChests.add(chest);
                    }
                }
            }
        }

        return outputChests;
    }

    /**
     * Transfer one item from inputs to outputs.
     * Priority: merge into existing stacks first, then use empty slots.
     * Returns true if an item was transferred, false otherwise.
     */
    private boolean transferOneItem(List<ChestBlockEntity> inputs, List<ChestBlockEntity> outputs) {
        if (inputs.isEmpty() || outputs.isEmpty()) {
            return false;
        }

        // Iterate through all input chests
        for (ChestBlockEntity inputChest : inputs) {
            for (int inputSlot = 0; inputSlot < inputChest.size(); inputSlot++) {
                ItemStack sourceStack = inputChest.getStack(inputSlot);

                if (sourceStack == null || sourceStack.count <= 0) {
                    continue;
                }

                // Try to merge with existing stack first
                for (ChestBlockEntity outputChest : outputs) {
                    for (int outputSlot = 0; outputSlot < outputChest.size(); outputSlot++) {
                        ItemStack targetStack = outputChest.getStack(outputSlot);

                        if (targetStack != null && canMergeStacks(sourceStack, targetStack)) {
                            // Found a matching stack with space
                            if (targetStack.count < targetStack.getMaxCount()) {
                                // Transfer 1 item
                                targetStack.count++;
                                sourceStack.count--;

                                // Clean up source if empty
                                if (sourceStack.count <= 0) {
                                    inputChest.setStack(inputSlot, null);
                                }

                                inputChest.markDirty();
                                outputChest.markDirty();

                                return true;
                            }
                        }
                    }
                }

                // No matching stack found, try to place in empty slot
                for (ChestBlockEntity outputChest : outputs) {
                    for (int outputSlot = 0; outputSlot < outputChest.size(); outputSlot++) {
                        ItemStack targetStack = outputChest.getStack(outputSlot);

                        if (targetStack == null) {
                            // Found empty slot, create new stack with 1 item
                            ItemStack newStack = new ItemStack(
                                    sourceStack.itemId,
                                    1,
                                    sourceStack.getDamage());
                            outputChest.setStack(outputSlot, newStack);

                            // Remove 1 from source
                            sourceStack.count--;
                            if (sourceStack.count <= 0) {
                                inputChest.setStack(inputSlot, null);
                            }

                            inputChest.markDirty();
                            outputChest.markDirty();

                            return true;
                        }
                    }
                }
            }
        }

        return false;
    }

    /**
     * Check if two item stacks can be merged (same item type and damage)
     */
    private boolean canMergeStacks(ItemStack stack1, ItemStack stack2) {
        if (stack1 == null || stack2 == null) {
            return false;
        }

        return stack1.itemId == stack2.itemId && stack1.getDamage() == stack2.getDamage();
    }
}
