import type { RSSFeedItem } from "@astrojs/rss";

export const recent: RSSFeedItem[] = [
  {
    title: "Do Three Way Merges Care About Linebreaks",
    description: "I make a case that merges are not linebreak sensitive.",
    pubDate: new Date("Nov 18 2025"),
    link: "/tech/do-3wm-care-about-linebreaks"
  },
  {
    title: "Reasonable LLM Usage - LLMs as an editor",
    description:
      "Added some brief thoughts around LLMs as as an editorial process.",
    pubDate: new Date("Nov 16 2025"),
    link: "/thoughts/reasonable-llm-usage",
  },
  {
    title: "The Anti Blog - What is a blog?",
    description: "Some musings and thoughts about blog-style websites.",
    pubDate: new Date("Oct 28 2025"),
    link: "/thoughts/the-anti-blog",
  },
  {
    title: "Projects",
    description:
      "Added a projects page which goes over some of the things I've been working on outside of my job.",
    pubDate: new Date("Oct 27 2025"),
    link: "/projects",
  },
];
