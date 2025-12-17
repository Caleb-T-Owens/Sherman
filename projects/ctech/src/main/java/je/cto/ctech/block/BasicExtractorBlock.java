package je.cto.ctech.block;

import je.cto.ctech.blockentity.BasicExtractorBlockEntity;
import net.minecraft.block.entity.BlockEntity;
import net.minecraft.block.material.Material;
import net.modificationstation.stationapi.api.template.block.TemplateBlockWithEntity;
import net.modificationstation.stationapi.api.util.Identifier;

public class BasicExtractorBlock extends TemplateBlockWithEntity {
    public BasicExtractorBlock(Identifier id) {
        super(id, Material.METAL);
    }

    @Override
    protected BlockEntity createBlockEntity() {
        return new BasicExtractorBlockEntity();
    }
}