import rss from "@astrojs/rss";
import { recent } from "../recent";

export function GET(context: any) {
  return rss({
    title: "Caleb's feed",
    description: "The latest pages and updates from cto.je",
    site: context.site,
    items: recent,
    customData: `<language>en-gb</language>`,
  });
}
