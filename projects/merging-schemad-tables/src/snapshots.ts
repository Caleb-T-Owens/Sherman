/**
 * Represents the state of the database at a given point in time.
 */
export type Snapshot = {
  headId: string;
  tables: Record<string, SnapshotTable>;
};

type SnapshotTable =
  | {
      type: 'present';
      updatedAt: number;
      rows: Record<string, SnapshotTableRow>;
    }
  | {
      type: 'dropped';
      updatedAt: number;
    };

export type SnapshotTableRow = {
  id: string;
  updatedAt: number;
} & (
  | {
      type: 'present';
      data: Record<string, SnapshotTableRowColumn>;
    }
  | { type: 'dropped' }
);

type SnapshotTableRowColumn =
  | {
      type: 'present';
      value: unknown;
      updatedAt: number;
    }
  | {
      type: 'dropped';
      updatedAt: number;
    };

function mergeSnapshotTableRowColumns(
  theirs: SnapshotTableRowColumn | undefined,
  ours: SnapshotTableRowColumn | undefined
): SnapshotTableRowColumn | undefined {
  if (!theirs && !ours) {
    return undefined;
  }

  if (!theirs) {
    return ours;
  }

  if (!ours) {
    return theirs;
  }

  if (theirs.updatedAt > ours.updatedAt) {
    return theirs;
  }

  return ours;
}

function mergeSnapshotTableRows(
  theirs: SnapshotTableRow | undefined,
  ours: SnapshotTableRow | undefined
): SnapshotTableRow | undefined {
  if (!theirs && !ours) {
    return undefined;
  }

  if (!theirs) {
    return ours;
  }

  if (!ours) {
    return theirs;
  }

  // Resolve dropped statuses
  if (theirs.type === 'dropped' || ours.type === 'dropped') {
    if (theirs.updatedAt > ours.updatedAt) {
      return theirs;
    }

    return ours;
  }

  const result = theirs;

  const allKeys = new Set([
    ...Object.keys(theirs.data),
    ...Object.keys(ours.data)
  ]);

  for (const key of allKeys) {
    const theirValue = theirs.data[key];
    const ourValue = ours.data[key];

    const mergedValue = mergeSnapshotTableRowColumns(theirValue, ourValue);

    if (mergedValue) {
      result.data[key] = mergedValue;
    }
  }

  return result;
}

function mergeSnapshotTables(
  theirs?: SnapshotTable,
  ours?: SnapshotTable
): SnapshotTable | undefined {
  if (!ours) {
    return theirs;
  }

  if (!theirs) {
    return ours;
  }

  // Resolve dropped statuses
  if (theirs.type === 'dropped' || ours.type === 'dropped') {
    if (theirs.updatedAt > ours.updatedAt) {
      return theirs;
    }

    return ours;
  }

  const result: SnapshotTable = {
    type: 'present',
    updatedAt: Math.max(theirs.updatedAt, ours.updatedAt),
    rows: {}
  };

  const allRowIds = new Set([
    ...Object.keys(theirs.rows),
    ...Object.keys(ours.rows)
  ]);

  for (const rowId of allRowIds) {
    const theirsRow = theirs.rows[rowId];
    const oursRow = ours.rows[rowId];

    const mergedRow = mergeSnapshotTableRows(theirsRow, oursRow);

    if (mergedRow) {
      result.rows[rowId] = mergedRow;
    }
  }

  return result;
}

export function mergeSnapshots(theirs: Snapshot, ours: Snapshot): Snapshot {
  const result: Snapshot = {
    tables: {}
  };

  for (const tableId in theirs.tables) {
    const theirsTable = theirs.tables[tableId];
    const oursTable = ours.tables[tableId];

    const mergedTable = mergeSnapshotTables(theirsTable, oursTable);

    if (mergedTable) {
      result.tables[tableId] = mergedTable;
    }
  }

  return result;
}
