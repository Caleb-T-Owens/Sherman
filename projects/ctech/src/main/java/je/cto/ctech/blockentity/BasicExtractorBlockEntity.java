package je.cto.ctech.blockentity;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import je.cto.ctech.transport.BlockChecker;
import je.cto.ctech.transport.BlockPos;
import je.cto.ctech.transport.Inventory;
import je.cto.ctech.transport.ItemTransferService;
import je.cto.ctech.transport.PipeNetworkTraverser;
import je.cto.ctech.transport.impl.BfsPipeNetworkTraverser;
import je.cto.ctech.transport.impl.DefaultItemTransferService;
import je.cto.ctech.transport.impl.MinecraftBlockChecker;
import net.minecraft.block.entity.BlockEntity;

/**
 * Block entity for the Basic Extractor.
 *
 * The extractor transfers items from adjacent input chests to output chests
 * connected via a pipe network. It uses dependency injection for the core
 * algorithms, allowing them to be tested independently.
 */
public class BasicExtractorBlockEntity extends BlockEntity {

    private static final int TICK_INTERVAL = 10;

    /**
     * Direction offsets for the 6 adjacent blocks.
     */
    private static final int[][] DIRECTION_OFFSETS = {
        { 0,  1,  0},  // Up
        { 0, -1,  0},  // Down
        { 1,  0,  0},  // East
        {-1,  0,  0},  // West
        { 0,  0,  1},  // South
        { 0,  0, -1}   // North
    };

    private final PipeNetworkTraverser networkTraverser;
    private final ItemTransferService transferService;

    private int tickCounter = 0;

    /**
     * Default constructor used by Minecraft.
     * Creates the block entity with default service implementations.
     */
    public BasicExtractorBlockEntity() {
        this(new BfsPipeNetworkTraverser(), new DefaultItemTransferService());
    }

    /**
     * Constructor for dependency injection (used in tests).
     *
     * @param networkTraverser the pipe network traversal implementation
     * @param transferService the item transfer service implementation
     */
    BasicExtractorBlockEntity(PipeNetworkTraverser networkTraverser, ItemTransferService transferService) {
        this.networkTraverser = networkTraverser;
        this.transferService = transferService;
    }

    @Override
    public void tick() {
        if (++tickCounter < TICK_INTERVAL) {
            return;
        }
        tickCounter = 0;

        BlockChecker blockChecker = createBlockChecker();
        BlockPos myPosition = new BlockPos(x, y, z);

        // Step 1: Find input chests (directly adjacent to extractor)
        List<Inventory> inputChests = findAdjacentInventories(blockChecker);

        // Step 2: Traverse the connected pipe network
        Set<BlockPos> pipeNetwork = networkTraverser.traverse(myPosition, blockChecker);

        // Step 3: Find output chests (adjacent to pipes, excluding inputs)
        List<Inventory> outputChests = findOutputInventories(pipeNetwork, inputChests, blockChecker);

        // Step 4: Transfer one item
        transferService.transferOne(inputChests, outputChests);
    }

    /**
     * Creates the block checker for this tick.
     * Protected to allow overriding in tests.
     */
    protected BlockChecker createBlockChecker() {
        return new MinecraftBlockChecker(world);
    }

    /**
     * Finds all inventories directly adjacent to this extractor.
     */
    private List<Inventory> findAdjacentInventories(BlockChecker blockChecker) {
        List<Inventory> inventories = new ArrayList<>();

        for (int[] offset : DIRECTION_OFFSETS) {
            BlockPos neighborPos = new BlockPos(x + offset[0], y + offset[1], z + offset[2]);
            Optional<Inventory> inventory = blockChecker.getInventory(neighborPos);
            inventory.ifPresent(inventories::add);
        }

        return inventories;
    }

    /**
     * Finds all inventories adjacent to pipes in the network, excluding input inventories.
     */
    private List<Inventory> findOutputInventories(
            Set<BlockPos> pipeNetwork,
            List<Inventory> inputInventories,
            BlockChecker blockChecker) {

        // Use a set to track already-added inventories (by identity)
        Set<Inventory> addedInventories = new HashSet<>(inputInventories);
        List<Inventory> outputInventories = new ArrayList<>();

        for (BlockPos pipePos : pipeNetwork) {
            for (int[] offset : DIRECTION_OFFSETS) {
                BlockPos neighborPos = pipePos.offset(offset[0], offset[1], offset[2]);
                Optional<Inventory> inventory = blockChecker.getInventory(neighborPos);

                if (inventory.isPresent() && !addedInventories.contains(inventory.get())) {
                    addedInventories.add(inventory.get());
                    outputInventories.add(inventory.get());
                }
            }
        }

        return outputInventories;
    }
}
