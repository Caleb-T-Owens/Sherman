import { parseJsonString, pwd, readFile } from "@/fileUtils";
import {
  requirementsSchema,
  shermanFileSchema,
  unitSchema,
  type Unit,
} from "@/schemas";
import { env, Glob } from "bun";

let currentWorkingDirectory = env.SHERMAN_DIRECTORY;
if (!currentWorkingDirectory) {
  currentWorkingDirectory = await pwd();
}

// Read environment variables
const profile = env.SHERMAN_PROFILE;
if (!profile) {
  throw new Error("SHERMAN_PROFILE must be set");
}

const platform = env.SHERMAN_PLATFORM;
if (!platform) {
  throw new Error("SHERMAN_PLATFORM must be set");
}

// Load sherman file
const shermanFilePath = `${currentWorkingDirectory}/sherman.json`;

const shermanFileString = await readFile(shermanFilePath);
if (!shermanFileString) {
  throw new Error(`sherman.json not found in ${currentWorkingDirectory}.`);
}
const shermanFile = parseJsonString(shermanFileString, shermanFileSchema);

// Find platform
const availablePlatforms = Object.keys(shermanFile.platforms);
if (!availablePlatforms.includes(platform)) {
  throw new Error(
    `Selected platform ${platform} is not an available platform. Please provide one of ${availablePlatforms}`
  );
}
const selectedPlatform = shermanFile.platforms[platform];

// Find profile
const availableProfiles = Object.keys(selectedPlatform.profiles);
if (!availableProfiles.includes(profile)) {
  throw new Error(
    `Selected profile ${profile} is not an available profile. Please provide one of ${availableProfiles}`
  );
}
const selectedProfile = selectedPlatform.profiles[profile];

type UnitWithContainingPath = Unit & { containingPath: string };

// Find the units
const units = [];
for (const entry of selectedPlatform.entries) {
  for await (const path of new Glob(
    currentWorkingDirectory + "/" + entry
  ).scan()) {
    const unitString = await readFile(path);
    if (!unitString) {
      continue;
    }
    const unit = await parseJsonString(unitString, unitSchema);
    const unitWithPath: UnitWithContainingPath = {
      ...unit,
      containingPath: path.split("/").slice(0, -1).join("/"),
    };
    units.push(unitWithPath);
  }
}

console.log(units);

const requiresPath = currentWorkingDirectory + "/" + selectedProfile.requires;
const requiresFileString = await readFile(requiresPath);
if (!requiresFileString) {
  throw new Error(`Failed to load requires path at ${requiresPath}`);
}
const requirements = parseJsonString(requiresFileString, requirementsSchema);

console.log(requirements);

interface GraphEntry<T> {
  dependencies: string[];
  key: string;
  value: T;
}

type Graph<T> = Map<string, GraphEntry<T>>;

function buildGraph<T>(
  initialMap: Record<string, T>,
  getDependencies: (subject: T) => string[]
) {
  const graph = new Map<string, GraphEntry<T>>();

  for (const [key, value] of Object.entries(initialMap)) {
    const dependencies = getDependencies(value);
    graph.set(key, {
      dependencies,
      key,
      value,
    });
  }

  return graph;
}

const layersGraph = buildGraph(
  shermanFile.layers,
  (subject) => subject.dependencies || []
);

console.log(layersGraph);

type GraphEntryWithDepth<T> = GraphEntry<T> & { depth: number };
type GraphWithDepth<T> = Map<string, GraphEntryWithDepth<T>>;

function findDepths<T>(
  startingEntries: readonly string[],
  graph: Graph<T>
): GraphWithDepth<T> {
  const graphWithDepths: GraphWithDepth<T> = new Map();

  let currentDepth = 0;
  let currentEntries = new Set(startingEntries);
  let nextEntries = new Set<string>();

  while (currentEntries.size > 0 && currentDepth < 1000) {
    for (const key of currentEntries) {
      const graphEntry = graph.get(key);
      if (!graphEntry) {
        throw new Error(`Failed to get graph entry ${key} out of graph`);
      }

      let depthEntry = graphWithDepths.get(key);
      if (!depthEntry) {
        depthEntry = {
          ...graphEntry,
          depth: currentDepth,
        };
      } else {
        depthEntry.depth = currentDepth;
      }
      graphWithDepths.set(key, depthEntry);

      for (const dependency of graphEntry.dependencies) {
        nextEntries.add(dependency);
      }
    }

    ++currentDepth;
    currentEntries = nextEntries;
    nextEntries = new Set();
  }

  return graphWithDepths;
}

const layersGraphWithDephts = findDepths(["four"], layersGraph);
console.log(layersGraphWithDephts);
