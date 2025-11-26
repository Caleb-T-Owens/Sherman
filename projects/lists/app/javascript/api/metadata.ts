interface MetadataResponse {
  title?: string;
  description?: string;
}

interface MetadataError {
  error: string;
}

function getCsrfToken(): string {
  return (
    document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute("content") || ""
  );
}

export async function fetchMetadata(
  url: string
): Promise<MetadataResponse | MetadataError> {
  const response = await fetch("/metadata/fetch", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": getCsrfToken(),
    },
    body: JSON.stringify({ url }),
  });

  return await response.json();
}
