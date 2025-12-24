package je.cto.ctech.blockentity;

import java.util.List;
import java.util.Optional;

import je.cto.ctech.machine.DefaultMachineProcessingService;
import je.cto.ctech.machine.MachineProcessingService;
import je.cto.ctech.machine.MachineRecipe;
import je.cto.ctech.machine.MinecraftStackSizeLookup;
import je.cto.ctech.transport.Inventory;
import je.cto.ctech.transport.impl.ChestInventoryAdapter;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.entity.ChestBlockEntity;

/**
 * Abstract base class for machine block entities.
 *
 * Machines process recipes using input from a chest above and output to a chest below.
 * Subclasses only need to define their recipe list.
 */
public abstract class AbstractMachineBlockEntity extends BlockEntity {

    private static final int TICK_INTERVAL = 10;

    private final MachineProcessingService processingService;
    private int tickCounter = 0;

    /**
     * Default constructor used by Minecraft.
     */
    public AbstractMachineBlockEntity() {
        this(new DefaultMachineProcessingService(new MinecraftStackSizeLookup()));
    }

    /**
     * Constructor for dependency injection (used in tests).
     */
    protected AbstractMachineBlockEntity(MachineProcessingService processingService) {
        this.processingService = processingService;
    }

    /**
     * Returns the list of recipes this machine can process.
     * Subclasses must implement this to define their recipes.
     */
    protected abstract List<MachineRecipe> getRecipes();

    @Override
    public void tick() {
        if (++tickCounter < TICK_INTERVAL) {
            return;
        }
        tickCounter = 0;

        Optional<Inventory> inputOpt = getInputInventory();
        Optional<Inventory> outputOpt = getOutputInventory();

        if (inputOpt.isEmpty() || outputOpt.isEmpty()) {
            return;
        }

        processingService.tryProcess(getRecipes(), inputOpt.get(), outputOpt.get());
    }

    /**
     * Gets the input inventory (chest above this block).
     */
    private Optional<Inventory> getInputInventory() {
        BlockEntity above = world.getBlockEntity(x, y + 1, z);
        if (above instanceof ChestBlockEntity) {
            return Optional.of(new ChestInventoryAdapter((ChestBlockEntity) above));
        }
        return Optional.empty();
    }

    /**
     * Gets the output inventory (chest below this block).
     */
    private Optional<Inventory> getOutputInventory() {
        BlockEntity below = world.getBlockEntity(x, y - 1, z);
        if (below instanceof ChestBlockEntity) {
            return Optional.of(new ChestInventoryAdapter((ChestBlockEntity) below));
        }
        return Optional.empty();
    }
}
