/**
 * Column-allocation layout for git-log style commit graphs, in the spirit of
 * Sapling's renderdag. Nodes are given newest-first; every parent must appear
 * after all of its children.
 *
 * Each active column is "waiting for" a node id. When a node is reached, all
 * columns waiting for it collapse into the leftmost one (drawn as a link row
 * above the node), and its parents fan back out (drawn as a link row below).
 */

export interface GraphNode {
  id: string;
  /** Parent ids, in order. Parents not present in the node list leave a dangling line. */
  parents?: string[];
  /** KaTeX expression rendered beside the node's row. */
  label?: string;
}

export type Segment = "N" | "S" | "E" | "W";

export interface Cell {
  segments: Segment[];
  node?: boolean;
  /** A horizontal link passing over an unrelated lane — drawn as a hop, not a junction. */
  cross?: boolean;
}

export interface NodeRow {
  kind: "node";
  cells: Cell[];
  node: GraphNode;
}

export interface LinkRow {
  kind: "link";
  cells: Cell[];
}

export type Row = NodeRow | LinkRow;

export interface Layout {
  rows: Row[];
  columnCount: number;
}

function emptyCells(count: number): Cell[] {
  return Array.from({ length: count }, () => ({ segments: [] }));
}

function add(cell: Cell, ...segments: Segment[]) {
  for (const s of segments) {
    if (!cell.segments.includes(s)) cell.segments.push(s);
  }
}

export function layoutGraph(nodes: GraphNode[]): Layout {
  // columns[i] is the node id that column is waiting for, or null if free.
  const columns: (string | null)[] = [];
  const rows: Row[] = [];
  const seen = new Set<string>();

  const allocate = (target: string): number => {
    const free = columns.indexOf(null);
    if (free !== -1) {
      columns[free] = target;
      return free;
    }
    columns.push(target);
    return columns.length - 1;
  };

  for (const node of nodes) {
    if (seen.has(node.id)) {
      throw new Error(`CommitGraph: duplicate node id "${node.id}"`);
    }
    seen.add(node.id);
    const parents = node.parents ?? [];
    for (const p of parents) {
      if (seen.has(p)) {
        throw new Error(
          `CommitGraph: node "${node.id}" lists parent "${p}", but "${p}" appears above it. ` +
            `Nodes must be ordered newest-first (children before parents).`,
        );
      }
    }

    const waiting = columns.flatMap((t, i) => (t === node.id ? [i] : []));
    const hadAbove = waiting.length > 0;
    const nodeCol = hadAbove ? waiting[0] : allocate(node.id);

    // Link row above the node: columns waiting for this node collapse into nodeCol.
    const merging = waiting.slice(1);
    if (merging.length > 0) {
      const cells = emptyCells(columns.length);
      const rightmost = Math.max(...merging);
      add(cells[nodeCol], "N", "S", "E");
      for (let i = 0; i < columns.length; i++) {
        if (i === nodeCol) continue;
        if (merging.includes(i)) {
          add(cells[i], "N", "W");
          if (i < rightmost) add(cells[i], "E");
        } else if (i > nodeCol && i < rightmost) {
          add(cells[i], "E", "W");
          if (columns[i] !== null) {
            add(cells[i], "N", "S");
            cells[i].cross = true;
          }
        } else if (columns[i] !== null) {
          add(cells[i], "N", "S");
        }
      }
      for (const i of merging) columns[i] = null;
      rows.push({ kind: "link", cells });
    }

    // The node's own row: a dot at nodeCol, pass-through lines elsewhere.
    {
      const cells = emptyCells(columns.length);
      cells[nodeCol].node = true;
      if (hadAbove) add(cells[nodeCol], "N");
      if (parents.length > 0) add(cells[nodeCol], "S");
      for (let i = 0; i < columns.length; i++) {
        if (i !== nodeCol && columns[i] !== null) add(cells[i], "N", "S");
      }
      rows.push({ kind: "node", cells, node });
    }

    // Reassign columns to parents; extra parents fan out in a link row below.
    columns[nodeCol] = parents[0] ?? null;
    const newCols = parents.slice(1).map(allocate);
    if (newCols.length > 0) {
      const cells = emptyCells(columns.length);
      const leftmost = Math.min(nodeCol, ...newCols);
      const rightmost = Math.max(nodeCol, ...newCols);
      add(cells[nodeCol], "N", "S");
      if (newCols.some((c) => c > nodeCol)) add(cells[nodeCol], "E");
      if (newCols.some((c) => c < nodeCol)) add(cells[nodeCol], "W");
      for (let i = 0; i < columns.length; i++) {
        if (i === nodeCol) continue;
        if (newCols.includes(i)) {
          add(cells[i], "S", i > nodeCol ? "W" : "E");
          if (i > leftmost && i < rightmost) add(cells[i], i > nodeCol ? "E" : "W");
        } else if (i > leftmost && i < rightmost) {
          add(cells[i], "E", "W");
          if (columns[i] !== null) {
            add(cells[i], "N", "S");
            cells[i].cross = true;
          }
        } else if (columns[i] !== null) {
          add(cells[i], "N", "S");
        }
      }
      rows.push({ kind: "link", cells });
    }
  }

  const columnCount = Math.max(0, ...rows.map((r) => r.cells.length));
  for (const row of rows) {
    while (row.cells.length < columnCount) row.cells.push({ segments: [] });
  }

  return { rows, columnCount };
}

/** Debug rendering of a layout as box-drawing text. */
export function layoutToText(layout: Layout): string {
  const GLYPHS: Record<string, string> = {
    "": " ",
    NS: "│",
    EW: "─",
    NW: "╯",
    NE: "╰",
    SW: "╮",
    ES: "╭",
    NES: "├",
    NSW: "┤",
    NEW: "┴",
    ESW: "┬",
    NESW: "┼",
    N: "╵",
    S: "╷",
    E: "╶",
    W: "╴",
  };
  const order: Segment[] = ["N", "E", "S", "W"];
  return layout.rows
    .map((row) => {
      const cells = row.cells
        .map((cell) => {
          if (cell.node) return "●";
          const key = order.filter((s) => cell.segments.includes(s)).join("");
          return GLYPHS[key] ?? "?";
        })
        .join("");
      const label = row.kind === "node" ? `  ${row.node.label ?? row.node.id}` : "";
      return cells + label;
    })
    .join("\n");
}
