'use client';

type Resident = {
  id: string;
  displayName: string;
  postalCode: string;
  houseNumber: string;
  status: string;
  createdAt: string;
};

type ResidentsTableProps = {
  residents: Resident[];
  selectable?: boolean;
  selectedIds?: Set<string>;
  onToggle?: (id: string) => void;
};

const formatDate = (value: string) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }
  return date.toLocaleString('de-DE');
};

export default function ResidentsTable({
  residents,
  selectable = false,
  selectedIds,
  onToggle,
}: ResidentsTableProps) {
  return (
    <div className="table-wrap">
      <table className="table">
        <thead>
          <tr>
            {selectable && <th />}
            <th>Name</th>
            <th>PLZ</th>
            <th>Hausnummer</th>
            <th>Status</th>
            <th>Erstellt</th>
          </tr>
        </thead>
        <tbody>
          {residents.map((resident) => (
            <tr key={resident.id}>
              {selectable && (
                <td>
                  <input
                    type="checkbox"
                    checked={selectedIds?.has(resident.id) ?? false}
                    onChange={() => onToggle?.(resident.id)}
                  />
                </td>
              )}
              <td>{resident.displayName}</td>
              <td>{resident.postalCode}</td>
              <td>{resident.houseNumber}</td>
              <td>
                <span className="badge">{resident.status}</span>
              </td>
              <td>{formatDate(resident.createdAt)}</td>
            </tr>
          ))}
          {residents.length === 0 && (
            <tr>
              <td colSpan={selectable ? 6 : 5}>Keine Bewohner gefunden.</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
