function parseLine(line: string): [string, string] {
  const [key, ...rest] = line.split(" ");

  if (!key || !rest) {
    throw new Error(`unexpected line: '${line}'`);
  }

  return [key, rest.join(" ")];
}

export default function parseWorkspaceStatus(
  data: string,
): Map<string, string> {
  return new Map(
    data
      .split("\n")
      .filter((line) => line !== "")
      .map(parseLine),
  );
}
