const DASH_VARIANTS = /[\u2013\u2014\u2212]/g;

export const normalizeActivationCode = (input: string) => {
  return input
    .trim()
    .toUpperCase()
    .replace(DASH_VARIANTS, '-')
    .replace(/\s+/g, '')
    .replace(/-+/g, '-');
};
