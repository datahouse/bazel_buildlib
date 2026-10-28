import { writeFile } from "node:fs/promises";

// Test we can write to the volume.
await writeFile("/test_volume/test.txt", "test-content");
