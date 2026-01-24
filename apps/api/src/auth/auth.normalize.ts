import { createHash } from 'crypto';

const DASH_VARIANTS = /[\u2010\u2011\u2012\u2013\u2014\u2212\u00AD]/g;

export const normalizeActivationCode = (input: string) => {
  return input
    .trim()
    .toUpperCase()
    .replace(DASH_VARIANTS, '-')
    .replace(/\s+/g, '')
    .replace(/-/g, '')
    .replace(/[^A-Z0-9]/g, '');
};

export const formatActivationCode = (canonical: string) => {
  const normalized = normalizeActivationCode(canonical);
  if (!normalized) {
    return '';
  }
  const parts = normalized.match(/.{1,4}/g);
  return parts ? parts.join('-') : normalized;
};

export const hashActivationCode = (
  tenantId: string,
  canonicalCode: string,
) => {
  return createHash('sha256')
    .update(`${tenantId}:${canonicalCode}`)
    .digest('hex');
};
