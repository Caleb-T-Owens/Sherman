import type { RSSFeedItem } from "@astrojs/rss";

export const recent: RSSFeedItem[] = [
  {
    title: "Projects",
    description:
      "Added a projects page which goes over some of the things I've been working on outside of my job.",
    pubDate: new Date("Mon Oct 27 2025"),
    link: "/projects",
  },
];
