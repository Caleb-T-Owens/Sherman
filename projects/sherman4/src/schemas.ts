import { z } from "zod";

export const shermanFileSchema = z.object({
  platforms: z.record(
    z.string(),
    z.object({
      entries: z.array(z.string()),
      profiles: z.record(
        z.string(),
        z.object({
          requires: z.string(),
          commands: z.array(z.string()),
        })
      ),
    })
  ),
  layers: z.record(
    z.string(),
    z.object({
      hooks: z.optional(z.record(z.string(), z.string())),
      dependencies: z.optional(z.array(z.string())),
    })
  ),
});

export type ShermanFile = (typeof shermanFileSchema)["_type"];

export const unitSchema = z.object({
  name: z.string(),
  layer: z.string(),
  commands: z.record(z.string(), z.string()),
  dependencies: z.record(z.string(), z.object({})),
});

export type Unit = (typeof unitSchema)["_type"];

export const requirementsSchema = z.object({
  dependencies: z.record(z.string(), z.object({})),
});
