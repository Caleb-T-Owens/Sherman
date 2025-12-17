package je.cto.ctech.block;

import net.minecraft.block.material.Material;
import net.modificationstation.stationapi.api.template.block.TemplateBlock;
import net.modificationstation.stationapi.api.util.Identifier;

public class DebugBlock extends TemplateBlock {
    public DebugBlock(Identifier id) {
        super(id, Material.METAL);
    }
}