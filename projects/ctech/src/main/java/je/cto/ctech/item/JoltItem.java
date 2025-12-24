package je.cto.ctech.item;

import net.modificationstation.stationapi.api.template.item.TemplateItem;
import net.modificationstation.stationapi.api.util.Identifier;

public class JoltItem extends TemplateItem {
    private final int amperage;

    public JoltItem(Identifier identifier, int amperage) {
        super(identifier);
        this.amperage = amperage;
    }

    public int getAmperage() {
        return amperage;
    }
}
