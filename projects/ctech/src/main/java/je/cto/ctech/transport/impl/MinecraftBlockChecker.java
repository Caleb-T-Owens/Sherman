package je.cto.ctech.transport.impl;

import java.util.Objects;
import java.util.Optional;

import je.cto.ctech.CTech;
import je.cto.ctech.transport.BlockChecker;
import je.cto.ctech.transport.BlockPos;
import je.cto.ctech.transport.Inventory;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.entity.ChestBlockEntity;
import net.minecraft.world.World;

/**
 * Minecraft-specific implementation of BlockChecker.
 *
 * This bridges the abstract BlockChecker interface to Minecraft's World class,
 * allowing pipe network traversal and inventory discovery to work with real game data.
 */
public final class MinecraftBlockChecker implements BlockChecker {

    private final World world;
    private final int pipeBlockId;

    /**
     * Creates a BlockChecker for the given world.
     *
     * @param world the Minecraft world to query
     */
    public MinecraftBlockChecker(World world) {
        this.world = Objects.requireNonNull(world, "World cannot be null");
        this.pipeBlockId = CTech.basicItemPipeBlock.id;
    }

    /**
     * Creates a BlockChecker with a custom pipe block ID (useful for testing).
     *
     * @param world the Minecraft world to query
     * @param pipeBlockId the block ID to recognize as a pipe
     */
    public MinecraftBlockChecker(World world, int pipeBlockId) {
        this.world = Objects.requireNonNull(world, "World cannot be null");
        this.pipeBlockId = pipeBlockId;
    }

    @Override
    public boolean isPipe(BlockPos pos) {
        if (pos == null) {
            return false;
        }
        int blockId = world.getBlockId(pos.getX(), pos.getY(), pos.getZ());
        return blockId == pipeBlockId;
    }

    @Override
    public Optional<Inventory> getInventory(BlockPos pos) {
        if (pos == null) {
            return Optional.empty();
        }

        BlockEntity entity = world.getBlockEntity(pos.getX(), pos.getY(), pos.getZ());
        if (entity instanceof ChestBlockEntity) {
            return Optional.of(new ChestInventoryAdapter((ChestBlockEntity) entity));
        }

        return Optional.empty();
    }
}
