import { Snapshot } from './snapshots';

type Commit = {
  id: string;
  mutations: Record<string, TableMutation>;
} & ({ parents: [string, string] } | { parent: string });

type TableMutation = {
  updatedAt: number;
} & (
  | {
      type: 'upsertion';
      rows: Record<string, RowMutation>;
    }
  | {
      type: 'deletion';
    }
);

type RowMutation = {
  updatedAt: number;
} & (
  | {
      type: 'upsertion';
      columns: Record<string, ColumnMutation>;
    }
  | {
      type: 'deletion';
    }
);

type ColumnMutation = {
  updatedAt: number;
} & (
  | {
      type: 'upsertion';
      value: unknown;
    }
  | {
      type: 'deletion';
    }
);

type FoundRecord = {
  id: string;
  columns: Record<string, unknown>;
};

function digRecord(
  snapshot: Snapshot,
  tableName: string,
  recordId: string
): FoundRecord | undefined {
  const existingTable = snapshot.tables[tableName];
  if (!existingTable || existingTable.type === 'dropped') {
    return;
  }
  const existingRow = existingTable.rows[recordId];
  if (!existingRow || existingRow.type === 'dropped') {
    return;
  }

  type PresentRow =
    | { type: 'defined'; value: [string, unknown] }
    | { type: 'undefined' };

  const columns = Object.fromEntries(
    Object.entries(existingRow.data)
      .map(
        ([columnName, value]): PresentRow =>
          value.type === 'present'
            ? { type: 'defined', value: [columnName, value.value] }
            : { type: 'undefined' }
      )
      .filter((entry) => entry.type === 'defined')
      .map((entry) => entry.value)
  );

  return {
    id: recordId,
    columns
  };
}

function diffColumns(
  now: number,
  before: Record<string, unknown>,
  after: Record<string, unknown>
): Record<string, ColumnMutation> {
  const output: Record<string, ColumnMutation> = {};

  const beforeKeys = new Set(Object.keys(before));
  const afterKeys = new Set(Object.keys(after));
  const allKeys = new Set([...beforeKeys, ...afterKeys]);

  for (const key of allKeys) {
    if (beforeKeys.has(key) && !afterKeys.has(key)) {
      output[key] = {
        type: 'deletion',
        updatedAt: now
      };
    }

    if (before[key] !== after[key] || !beforeKeys.has(key)) {
      output[key] = {
        type: 'upsertion',
        updatedAt: now,
        value: after[key]
      };
    }
  }

  return output;
}

function diffRecord(
  now: number,
  currentSnapshot: Snapshot,
  tableName: string,
  recordId: string,
  record: Record<string, unknown>
): RowMutation {
  const existingRecord = digRecord(currentSnapshot, tableName, recordId);

  return {
    type: 'upsertion',
    updatedAt: now,
    columns: diffColumns(now, existingRecord?.columns || {}, record)
  };
}

function diffTable(
  now: number,
  currentSnapshot: Snapshot,
  tableName: string,
  records: Record<string, Record<string, unknown>>
): TableMutation {
  return {
    type: 'upsertion',
    updatedAt: now,
    rows: Object.fromEntries(
      Object.entries(records).map(([recordId, value]) => [
        recordId,
        diffRecord(now, currentSnapshot, tableName, recordId, value)
      ])
    )
  };
}

function upsertRecords(
  now: number,
  currentSnapshot: Snapshot,
  tables: Record<string, Record<string, Record<string, unknown>>>
): Commit {
  return {
    id: genId(),
    parent: currentSnapshot.headId,
    mutations: Object.fromEntries(
      Object.entries(tables).map(([tableName, value]) => [
        tableName,
        diffTable(now, currentSnapshot, tableName, value)
      ])
    )
  };
}
