const escapeCsvValue = (value: string, delimiter: string) => {
  const needsQuotes =
    value.includes(delimiter) ||
    value.includes('"') ||
    value.includes('\n') ||
    value.includes('\r');
  const escaped = value.replace(/"/g, '""');
  return needsQuotes ? `"${escaped}"` : escaped;
};

export const buildCsv = (
  headers: string[],
  rows: string[][],
  delimiter = ',',
) => {
  const lines = [headers, ...rows].map((row) =>
    row.map((value) => escapeCsvValue(value ?? '', delimiter)).join(delimiter),
  );
  return lines.join('\n');
};

export const downloadCsv = (filename: string, content: string) => {
  const blob = new Blob(['\uFEFF', content], {
    type: 'text/csv;charset=utf-8;',
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
};
