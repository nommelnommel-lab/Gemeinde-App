const escapeCsvValue = (value: string) => {
  const needsQuotes = /[",\n\r]/.test(value);
  const escaped = value.replace(/"/g, '""');
  return needsQuotes ? `"${escaped}"` : escaped;
};

export const buildCsv = (headers: string[], rows: string[][]) => {
  const lines = [headers, ...rows].map((row) =>
    row.map((value) => escapeCsvValue(value ?? '')).join(','),
  );
  return lines.join('\n');
};

export const downloadCsv = (filename: string, content: string) => {
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
};
