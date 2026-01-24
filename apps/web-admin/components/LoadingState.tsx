'use client';

type LoadingStateProps = {
  message?: string;
};

export default function LoadingState({ message }: LoadingStateProps) {
  return <div className="notice">{message ?? 'Lade Daten...'} </div>;
}
