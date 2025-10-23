import type { Repository } from "@/src/inner/types";

export class GitRepo implements Repository {
    constructor(private path: string) {}
}